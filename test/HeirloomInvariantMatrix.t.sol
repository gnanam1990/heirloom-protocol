// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { StdStorage, stdStorage } from "forge-std/StdStorage.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { HeirloomFactory } from "../src/HeirloomFactory.sol";
import { HeirloomTypes } from "../src/HeirloomTypes.sol";
import { HeirloomVault } from "../src/HeirloomVault.sol";
import { IHeirloomVault } from "../src/interfaces/IHeirloomVault.sol";
import { MockUSDC } from "./mocks/MockUSDC.sol";

contract DebitFeeUSDC is ERC20 {
    bool public feeEnabled;
    address public chargedSender;

    constructor() ERC20("Debit Fee USDC", "dfUSDC") { }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(
        address to,
        uint256 amount
    ) external {
        _mint(to, amount);
    }

    function enableDebitFee(
        address sender
    ) external {
        chargedSender = sender;
        feeEnabled = true;
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        if (feeEnabled && from == chargedSender && to != address(0)) {
            super._update(from, address(0), 1);
        }
        super._update(from, to, value);
    }
}

contract HeirloomInvariantMatrixTest is Test {
    using stdStorage for StdStorage;

    uint256 internal constant ONE_USDC = 1e6;
    uint256 internal constant DEPOSIT = 1_000_000 * ONE_USDC;

    address internal owner = makeAddr("matrix-owner");
    address internal outsider = makeAddr("matrix-outsider");
    address internal recovery = makeAddr("matrix-recovery");
    address internal primaryA = makeAddr("matrix-primary-a");
    address internal fallbackA = makeAddr("matrix-fallback-a");
    address internal primaryB = makeAddr("matrix-primary-b");
    address internal fallbackB = makeAddr("matrix-fallback-b");
    address internal terminalPrimary = makeAddr("matrix-terminal-primary");
    address internal terminalFallback = makeAddr("matrix-terminal-fallback");
    address internal guardianA = makeAddr("matrix-guardian-a");
    address internal guardianB = makeAddr("matrix-guardian-b");
    address internal guardianC = makeAddr("matrix-guardian-c");

    MockUSDC internal usdc;
    HeirloomFactory internal factory;
    HeirloomVault internal vault;

    function setUp() public {
        usdc = new MockUSDC();
        factory = new HeirloomFactory(usdc);
        vault = HeirloomVault(factory.createVault(owner, keccak256("matrix"), _defaultConfig()));
        usdc.mint(owner, DEPOSIT);
        vm.startPrank(owner);
        usdc.approve(address(vault), DEPOSIT);
        vault.deposit(DEPOSIT);
        vm.stopPrank();
    }

    function testI1_LastSeenChangesOnlyForOwnerAuthorizationOrRecovery() public {
        uint64 beforeSeen = vault.lastSeen();
        _mature();
        vm.prank(outsider);
        vault.requestClaim();
        assertEq(vault.lastSeen(), beforeSeen);
    }

    function testI2_PermissionlessConfigExecutionCannotCreateLiveness() public {
        bytes memory encoded = abi.encode(_configWithInactivity(91 days));
        vm.prank(owner);
        vault.proposeConfig(encoded);
        uint64 beforeSeen = vault.lastSeen();
        uint64 beforeNonce = vault.livenessNonce();
        (,, uint64 eta,) = vault.pendingConfig();

        vm.warp(eta);
        vm.prank(outsider);
        vault.executeConfig(encoded);

        assertEq(vault.lastSeen(), beforeSeen);
        assertEq(vault.livenessNonce(), beforeNonce);
    }

    function testI3_ClaimRequestMovesNoAssetAndBindsCurrentEpochs() public {
        uint256 beforeBalance = usdc.balanceOf(address(vault));
        uint64 expectedLiveness = vault.livenessNonce();
        uint64 expectedConfig = vault.configNonce();
        _mature();

        vm.prank(outsider);
        vault.requestClaim();
        (uint64 nonce,,, uint64 requestLiveness, uint64 requestConfig) = vault.claimRequest();

        assertGt(nonce, 0);
        assertEq(requestLiveness, expectedLiveness);
        assertEq(requestConfig, expectedConfig);
        assertEq(usdc.balanceOf(address(vault)), beforeBalance);
    }

    function testI4_DistributionRejectsAStaleRequestEpoch() public {
        _requestClaim();
        (,, uint64 executeAfter, uint64 requestLiveness,) = vault.claimRequest();
        stdstore.enable_packed_slots().target(address(vault)).sig("livenessNonce()")
            .checked_write(uint256(requestLiveness + 1));

        vm.warp(executeAfter);
        vm.expectRevert(IHeirloomVault.StaleClaimRequest.selector);
        vault.startDistribution();
        assertEq(uint8(vault.state()), uint8(HeirloomTypes.VaultState.ClaimRequested));
    }

    function testI5_PermissionlessCallerCannotAimOrResizePayout() public {
        _startDistribution();
        uint256 amount = vault.entitlement(0);
        uint256 outsiderBefore = usdc.balanceOf(outsider);

        vm.prank(outsider);
        vault.executePayout(0);

        assertEq(usdc.balanceOf(primaryA), amount);
        assertEq(usdc.balanceOf(outsider), outsiderBefore);
        assertEq(vault.totalNonTerminalPaid(), amount);
    }

    function testI6_ExactlyOneDestinationPhaseExistsAtFallbackBoundary() public {
        _startDistribution();
        vm.warp(vault.fallbackAt());
        assertEq(
            uint8(vault.destinationPhase(0)), uint8(HeirloomTypes.DestinationPhase.FallbackOnly)
        );
    }

    function testI7_PrimaryAndFallbackAreImpossibleAtRolloverBoundary() public {
        _startDistribution();
        vm.warp(vault.rolloverAt());
        assertEq(
            uint8(vault.destinationPhase(0)), uint8(HeirloomTypes.DestinationPhase.RolloverOnly)
        );
        vm.expectRevert(IHeirloomVault.WrongDestinationPhase.selector);
        vault.executePayout(0);
    }

    function testI8_NonTerminalEntitlementResolvesExactlyOnce() public {
        _startDistribution();
        uint256 amount = vault.entitlement(0);
        vault.executePayout(0);

        vm.expectRevert(IHeirloomVault.EntitlementAlreadyResolved.selector);
        vault.executePayout(0);

        assertEq(usdc.balanceOf(primaryA), amount);
        assertEq(vault.resolvedNonTerminalCount(), 1);
    }

    function testI9_TerminalCannotUnlockBeforeEveryNonTerminalResolves() public {
        _startDistribution();
        vault.executePayout(0);

        assertEq(vault.terminalUnlockedAt(), 0);
        vm.expectRevert(IHeirloomVault.TerminalLocked.selector);
        vault.executeTerminalPayout();
    }

    function testI10_EntitlementBpsMustConserveTheSnapshot() public {
        HeirloomTypes.VaultConfig memory invalid = _defaultConfig();
        invalid.terminal.bps -= 1;
        vm.expectRevert(IHeirloomVault.InvalidConfiguration.selector);
        factory.createVault(owner, keccak256("matrix-invalid-bps"), invalid);
    }

    function testI11_RolloverRemainsInTerminalSnapshotExactlyOnce() public {
        _startDistribution();
        uint256 snapshot = vault.snapshotBalance();
        uint256 paid = vault.entitlement(0);
        uint256 rolled = vault.entitlement(1);
        vault.executePayout(0);
        vm.warp(vault.rolloverAt());
        vault.rolloverPayout(1);

        assertEq(vault.snapshotRemaining(), snapshot - paid);
        assertEq(vault.totalRolledOver(), rolled);
        vault.executeTerminalPayout();
        assertEq(usdc.balanceOf(terminalPrimary), snapshot - paid);
    }

    function testI12_InexactTransferRevertsAllResolutionAccounting() public {
        DebitFeeUSDC inexact = new DebitFeeUSDC();
        HeirloomFactory inexactFactory = new HeirloomFactory(inexact);
        HeirloomVault inexactVault = HeirloomVault(
            inexactFactory.createVault(owner, keccak256("matrix-inexact"), _defaultConfig())
        );
        inexact.mint(owner, DEPOSIT);
        vm.startPrank(owner);
        inexact.approve(address(inexactVault), DEPOSIT);
        inexactVault.deposit(DEPOSIT);
        vm.stopPrank();
        _startDistribution(inexactVault);
        inexact.enableDebitFee(address(inexactVault));

        uint256 beforeRemaining = inexactVault.snapshotRemaining();
        uint256 beforeBalance = inexact.balanceOf(address(inexactVault));
        vm.expectRevert(IHeirloomVault.UnexpectedTokenDelta.selector);
        inexactVault.executePayout(0);

        assertEq(
            uint8(inexactVault.beneficiaryStatus(0)),
            uint8(HeirloomTypes.BeneficiaryStatus.Unresolved)
        );
        assertEq(inexactVault.snapshotRemaining(), beforeRemaining);
        assertEq(inexact.balanceOf(address(inexactVault)), beforeBalance);
    }

    function testI13_SuccessfulPayoutTracksExactOutgoingDelta() public {
        _startDistribution();
        uint256 beforeRemaining = vault.snapshotRemaining();
        uint256 beforeBalance = usdc.balanceOf(address(vault));
        uint256 amount = vault.entitlement(0);

        vault.executePayout(0);

        assertEq(vault.snapshotRemaining(), beforeRemaining - amount);
        assertEq(usdc.balanceOf(address(vault)), beforeBalance - amount);
    }

    function testI14_SettlementIsCompleteTerminalAndSingleUse() public {
        _startDistribution();
        vault.executePayout(0);
        vault.executePayout(1);
        vault.executeTerminalPayout();

        assertEq(uint8(vault.state()), uint8(HeirloomTypes.VaultState.Settled));
        assertEq(vault.snapshotRemaining(), 0);
        assertTrue(vault.terminalPaid());
        assertEq(vault.resolvedNonTerminalCount(), vault.beneficiaryCount());
        vm.expectRevert(IHeirloomVault.InvalidState.selector);
        vault.executeTerminalPayout();
    }

    function testI15_RecoveryInstallsOnlyPrecommittedOwnerAndInvalidatesEpochs() public {
        bytes memory encoded = abi.encode(_configWithInactivity(91 days));
        vm.prank(owner);
        vault.proposeConfig(encoded);
        _mature();
        vault.requestClaim();
        uint64 beforeLiveness = vault.livenessNonce();
        uint64 beforeConfig = vault.configNonce();

        vm.prank(guardianA);
        vault.requestRecovery();
        (uint64 requestNonce,,,,,) = vault.recoveryRequest();
        vm.prank(guardianB);
        vault.approveRecovery(requestNonce);
        (,, uint64 readyAt,,,) = vault.recoveryRequest();
        vm.warp(readyAt);
        vm.prank(outsider);
        vault.activateRecovery();

        assertEq(vault.owner(), recovery);
        assertEq(vault.livenessNonce(), beforeLiveness + 1);
        assertEq(vault.configNonce(), beforeConfig + 1);
        (uint64 claimNonce,,,,) = vault.claimRequest();
        (bytes32 pendingHash,,,) = vault.pendingConfig();
        (uint64 recoveryRequestNonce,,,,,) = vault.recoveryRequest();
        assertEq(claimNonce, 0);
        assertEq(pendingHash, bytes32(0));
        assertEq(recoveryRequestNonce, 0);
    }

    function testI16_FactoryAssetVersionAndRuntimeIdentityRemainVerifiable() public view {
        assertEq(vault.factory(), address(factory));
        assertEq(address(vault.asset()), address(usdc));
        assertEq(vault.versionId(), factory.VERSION_ID());
        assertTrue(factory.isVault(address(vault)));
        assertEq(factory.vaultRuntimeCodeHash(address(vault)), address(vault).codehash);
        assertTrue(address(vault).codehash != bytes32(0));
    }

    function _mature() internal {
        vm.warp(uint256(vault.lastSeen()) + vault.MIN_INACTIVITY());
    }

    function _requestClaim() internal {
        _mature();
        vm.prank(outsider);
        vault.requestClaim();
    }

    function _startDistribution() internal {
        _startDistribution(vault);
    }

    function _startDistribution(
        HeirloomVault target
    ) internal {
        vm.warp(uint256(target.lastSeen()) + target.MIN_INACTIVITY());
        vm.prank(outsider);
        target.requestClaim();
        (,, uint64 executeAfter,,) = target.claimRequest();
        vm.warp(executeAfter);
        vm.prank(outsider);
        target.startDistribution();
    }

    function _configWithInactivity(
        uint64 inactivity
    ) internal view returns (HeirloomTypes.VaultConfig memory config) {
        config = _defaultConfig();
        config.durations.inactivityPeriod = inactivity;
    }

    function _defaultConfig() internal view returns (HeirloomTypes.VaultConfig memory config) {
        config.beneficiaries = new HeirloomTypes.Beneficiary[](2);
        config.beneficiaries[0] =
            HeirloomTypes.Beneficiary({ primary: primaryA, fallbackAddress: fallbackA, bps: 3000 });
        config.beneficiaries[1] =
            HeirloomTypes.Beneficiary({ primary: primaryB, fallbackAddress: fallbackB, bps: 2000 });
        config.terminal = HeirloomTypes.Beneficiary({
            primary: terminalPrimary, fallbackAddress: terminalFallback, bps: 5000
        });
        config.durations = HeirloomTypes.Durations({
            inactivityPeriod: 90 days,
            challengePeriod: 7 days,
            primaryWindow: 30 days,
            fallbackWindow: 30 days,
            configDelay: 2 days,
            configExecutionWindow: 30 days,
            recoveryDelay: 2 days,
            recoveryExecutionWindow: 30 days
        });
        config.guardians = new address[](3);
        config.guardians[0] = guardianA;
        config.guardians[1] = guardianB;
        config.guardians[2] = guardianC;
        config.guardianThreshold = 2;
        config.recoveryAddress = recovery;
    }
}

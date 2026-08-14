// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { HeirloomFactory } from "../src/HeirloomFactory.sol";
import { HeirloomTypes } from "../src/HeirloomTypes.sol";
import { HeirloomVault } from "../src/HeirloomVault.sol";
import { IHeirloomVault } from "../src/interfaces/IHeirloomVault.sol";
import { MockUSDC } from "./mocks/MockUSDC.sol";

contract HeirloomVaultTest is Test {
    uint256 internal constant ONE_USDC = 1e6;
    uint256 internal constant DEPOSIT = 1_000_000 * ONE_USDC;

    address internal owner = makeAddr("owner");
    address internal outsider = makeAddr("outsider");
    address internal recovery = makeAddr("recovery");
    address internal primaryA = makeAddr("primaryA");
    address internal fallbackA = makeAddr("fallbackA");
    address internal primaryB = makeAddr("primaryB");
    address internal fallbackB = makeAddr("fallbackB");
    address internal terminalPrimary = makeAddr("terminalPrimary");
    address internal terminalFallback = makeAddr("terminalFallback");
    address internal guardianA = makeAddr("guardianA");
    address internal guardianB = makeAddr("guardianB");
    address internal guardianC = makeAddr("guardianC");

    MockUSDC internal usdc;
    HeirloomFactory internal factory;
    HeirloomVault internal vault;

    function setUp() public {
        usdc = new MockUSDC();
        factory = new HeirloomFactory(usdc);
        vault = HeirloomVault(factory.createVault(owner, keccak256("vault-one"), _defaultConfig()));

        usdc.mint(owner, DEPOSIT * 2);
        vm.startPrank(owner);
        usdc.approve(address(vault), type(uint256).max);
        vault.deposit(DEPOSIT);
        vm.stopPrank();
    }

    function testFactoryCreatesDeterministicInitializedClone() public view {
        HeirloomTypes.VaultConfig memory config = _defaultConfig();
        bytes32 salt = keccak256("vault-two");
        address predicted = factory.predictVaultAddress(owner, salt, config);

        assertTrue(predicted != address(0));
        assertEq(vault.owner(), owner);
        assertEq(address(vault.asset()), address(usdc));
        assertEq(vault.factory(), address(factory));
        assertTrue(factory.isVault(address(vault)));
        assertTrue(factory.vaultRuntimeCodeHash(address(vault)) != bytes32(0));
    }

    function testFactoryPredictionMatchesDeployment() public {
        HeirloomTypes.VaultConfig memory config = _defaultConfig();
        bytes32 salt = keccak256("vault-two");
        address predicted = factory.predictVaultAddress(owner, salt, config);
        address deployed = factory.createVault(owner, salt, config);

        assertEq(deployed, predicted);
        assertEq(
            factory.vaultRuntimeCodeHash(deployed), factory.vaultRuntimeCodeHash(address(vault))
        );
    }

    function testImplementationCannotBeInitialized() public {
        bytes32 version = factory.VERSION_ID();
        address implementation = factory.implementation();
        vm.expectRevert(IHeirloomVault.AlreadyInitialized.selector);
        HeirloomVault(implementation).initialize(owner, usdc, version, _defaultConfig());
    }

    function testDirectTransferDoesNotCreateLiveness() public {
        uint64 beforeSeen = vault.lastSeen();
        uint64 beforeNonce = vault.livenessNonce();
        usdc.mint(outsider, ONE_USDC);

        vm.warp(block.timestamp + 20 days);
        vm.prank(outsider);
        usdc.transfer(address(vault), ONE_USDC);

        assertEq(vault.lastSeen(), beforeSeen);
        assertEq(vault.livenessNonce(), beforeNonce);
    }

    function testPermissionlessConfigExecutionDoesNotCreateLiveness() public {
        bytes memory encoded = abi.encode(_defaultConfig());
        vm.prank(owner);
        vault.proposeConfig(encoded);
        uint64 proposalSeen = vault.lastSeen();
        uint64 proposalLivenessNonce = vault.livenessNonce();
        (,, uint64 eta,) = vault.pendingConfig();

        vm.warp(eta);
        vm.prank(outsider);
        vault.executeConfig(encoded);

        assertEq(vault.lastSeen(), proposalSeen);
        assertEq(vault.livenessNonce(), proposalLivenessNonce);
        assertEq(vault.configNonce(), 2);
    }

    function testClaimUsesExactMaturityAndChallengeBoundaries() public {
        uint64 seen = vault.lastSeen();
        (uint64 inactivity, uint64 challenge,,,,,,) = vault.durations();
        vm.warp(uint256(seen) + inactivity - 1);
        vm.expectRevert(IHeirloomVault.NotMatured.selector);
        vault.requestClaim();

        vm.warp(uint256(seen) + inactivity);
        vm.prank(outsider);
        vault.requestClaim();
        (,, uint64 executeAfter,,) = vault.claimRequest();
        assertEq(executeAfter, block.timestamp + challenge);

        vm.warp(executeAfter - 1);
        vm.expectRevert(IHeirloomVault.ChallengeNotElapsed.selector);
        vault.startDistribution();

        vm.warp(executeAfter);
        vm.prank(outsider);
        vault.startDistribution();
        assertEq(uint8(vault.state()), uint8(HeirloomTypes.VaultState.Distributing));
    }

    function testFreshOwnerActivityCancelsClaimAndRecovery() public {
        _matureAndRequestClaim();
        vm.prank(guardianA);
        vault.requestRecovery();

        vm.prank(owner);
        vault.heartbeat();

        assertEq(uint8(vault.state()), uint8(HeirloomTypes.VaultState.Active));
        (uint64 claimNonce,,,,) = vault.claimRequest();
        (uint64 recoveryRequestNonce,,,,,) = vault.recoveryRequest();
        assertEq(claimNonce, 0);
        assertEq(recoveryRequestNonce, 0);
    }

    function testDestinationIsDerivedOnlyFromTime() public {
        _startDistribution();
        (,, uint64 primaryWindow, uint64 fallbackWindow,,,,) = vault.durations();
        uint64 startedAt = vault.distributionStartedAt();

        assertEq(
            uint8(vault.destinationPhase(0)), uint8(HeirloomTypes.DestinationPhase.PrimaryOnly)
        );

        vm.warp(uint256(startedAt) + primaryWindow);
        assertEq(
            uint8(vault.destinationPhase(0)), uint8(HeirloomTypes.DestinationPhase.FallbackOnly)
        );

        vm.warp(uint256(startedAt) + primaryWindow + fallbackWindow);
        assertEq(
            uint8(vault.destinationPhase(0)), uint8(HeirloomTypes.DestinationPhase.RolloverOnly)
        );
        vm.expectRevert(IHeirloomVault.WrongDestinationPhase.selector);
        vault.executePayout(0);
    }

    function testTerminalRemainsLockedUntilEveryNonTerminalIsResolved() public {
        _startDistribution();
        vm.expectRevert(IHeirloomVault.TerminalLocked.selector);
        vault.executeTerminalPayout();

        vault.executePayout(0);
        vm.expectRevert(IHeirloomVault.TerminalLocked.selector);
        vault.executeTerminalPayout();

        vault.executePayout(1);
        assertEq(
            uint8(vault.terminalDestinationPhase()),
            uint8(HeirloomTypes.DestinationPhase.TerminalPrimaryOnly)
        );
    }

    function testPaidAndRolledEntitlementsConserveSnapshot() public {
        _startDistribution();
        uint256 snapshot = vault.snapshotBalance();
        uint256 firstEntitlement = vault.entitlement(0);
        uint256 secondEntitlement = vault.entitlement(1);
        vault.executePayout(0);

        vm.warp(vault.rolloverAt());
        vault.rolloverPayout(1);

        uint256 expectedTerminal = snapshot - firstEntitlement;
        assertEq(vault.snapshotRemaining(), expectedTerminal);
        assertEq(vault.totalNonTerminalPaid(), firstEntitlement);
        assertEq(vault.totalRolledOver(), secondEntitlement);

        vault.executeTerminalPayout();
        assertEq(usdc.balanceOf(terminalPrimary), expectedTerminal);
        assertEq(usdc.balanceOf(primaryA), firstEntitlement);
        assertEq(uint8(vault.state()), uint8(HeirloomTypes.VaultState.Settled));
        assertEq(usdc.balanceOf(address(vault)), 0);
        assertEq(usdc.balanceOf(terminalPrimary), expectedTerminal);
    }

    function testTerminalFallbackIsTimeDerived() public {
        _startDistribution();
        vault.executePayout(0);
        vault.executePayout(1);
        uint64 unlockTime = vault.terminalUnlockedAt();
        (,, uint64 primaryWindow,,,,,) = vault.durations();

        vm.warp(uint256(unlockTime) + primaryWindow);
        vault.executeTerminalPayout();

        assertGt(usdc.balanceOf(terminalFallback), 0);
        assertEq(vault.settledTerminalDestination(), terminalFallback);
    }

    function testZeroSnapshotSettlesWithoutStranding() public {
        HeirloomVault emptyVault =
            HeirloomVault(factory.createVault(owner, keccak256("empty"), _defaultConfig()));
        vm.warp(uint256(emptyVault.lastSeen()) + emptyVault.MIN_INACTIVITY());
        emptyVault.requestClaim();
        (,, uint64 executeAfter,,) = emptyVault.claimRequest();
        vm.warp(executeAfter);
        emptyVault.startDistribution();

        assertEq(uint8(emptyVault.state()), uint8(HeirloomTypes.VaultState.Settled));
        assertEq(emptyVault.snapshotBalance(), 0);
        assertTrue(emptyVault.terminalPaid());
    }

    function testPositiveSnapshotZeroEntitlementsResolveAndTerminalReceivesRemainder() public {
        HeirloomVault tinyVault =
            HeirloomVault(factory.createVault(owner, keccak256("tiny"), _defaultConfig()));
        usdc.mint(address(tinyVault), 1);
        vm.warp(uint256(tinyVault.lastSeen()) + tinyVault.MIN_INACTIVITY());
        tinyVault.requestClaim();
        (,, uint64 executeAfter,,) = tinyVault.claimRequest();
        vm.warp(executeAfter);
        tinyVault.startDistribution();

        assertEq(tinyVault.resolvedNonTerminalCount(), 2);
        assertEq(tinyVault.terminalUnlockedAt(), block.timestamp);
        tinyVault.executeTerminalPayout();
        assertEq(usdc.balanceOf(terminalPrimary), 1);
        assertEq(uint8(tinyVault.state()), uint8(HeirloomTypes.VaultState.Settled));
    }

    function testTerminalAbsorbsAtomicUnitRounding() public {
        usdc.mint(address(vault), 7);
        _startDistribution();
        uint256 snapshot = vault.snapshotBalance();
        uint256 first = vault.entitlement(0);
        uint256 second = vault.entitlement(1);
        uint256 terminalFloor = snapshot * 5000 / 10_000;

        vault.executePayout(0);
        vault.executePayout(1);
        uint256 expectedTerminal = snapshot - first - second;
        assertGt(expectedTerminal, terminalFloor);
        vault.executeTerminalPayout();

        assertEq(usdc.balanceOf(terminalPrimary), expectedTerminal);
        assertEq(first + second + expectedTerminal, snapshot);
    }

    function testAccountingDeficitBlocksPayoutWithoutResolution() public {
        _startDistribution();
        uint256 snapshot = vault.snapshotBalance();
        deal(address(usdc), address(vault), snapshot - 1);

        vm.expectRevert(IHeirloomVault.AccountingDeficit.selector);
        vault.executePayout(0);
        assertEq(
            uint8(vault.beneficiaryStatus(0)), uint8(HeirloomTypes.BeneficiaryStatus.Unresolved)
        );
        assertEq(vault.snapshotRemaining(), snapshot);
    }

    function testGuardianRecoveryRequiresQuorumAndDelay() public {
        _matureAndRequestClaim();
        vm.prank(guardianA);
        vault.requestRecovery();
        (uint64 requestNonce,,,,,) = vault.recoveryRequest();

        vm.expectRevert(IHeirloomVault.RecoveryNotReady.selector);
        vault.activateRecovery();

        vm.prank(guardianB);
        vault.approveRecovery(requestNonce);
        (,, uint64 readyAt,,,) = vault.recoveryRequest();
        vm.warp(readyAt);
        vm.prank(outsider);
        vault.activateRecovery();

        assertEq(vault.owner(), recovery);
        assertEq(uint8(vault.state()), uint8(HeirloomTypes.VaultState.Active));
        assertEq(vault.recoveryNonce(), 1);
        assertEq(vault.configNonce(), 2);
        assertEq(vault.livenessNonce(), 3);
    }

    function testPausedTokenCannotPartiallyResolvePayout() public {
        _startDistribution();
        usdc.setPaused(true);
        vm.expectRevert();
        vault.executePayout(0);

        assertEq(
            uint8(vault.beneficiaryStatus(0)), uint8(HeirloomTypes.BeneficiaryStatus.Unresolved)
        );
        assertEq(vault.snapshotRemaining(), vault.snapshotBalance());
    }

    function _startDistribution() internal {
        _matureAndRequestClaim();
        (,, uint64 executeAfter,,) = vault.claimRequest();
        vm.warp(executeAfter);
        vault.startDistribution();
    }

    function _matureAndRequestClaim() internal {
        (uint64 inactivity,,,,,,,) = vault.durations();
        vm.warp(uint256(vault.lastSeen()) + inactivity);
        vm.prank(outsider);
        vault.requestClaim();
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

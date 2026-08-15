// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { Test } from "forge-std/Test.sol";

import { HeirloomFactory } from "../src/HeirloomFactory.sol";
import { HeirloomTypes } from "../src/HeirloomTypes.sol";
import { HeirloomVault } from "../src/HeirloomVault.sol";
import { MockUSDC } from "./mocks/MockUSDC.sol";

contract StatefulDebitFeeUSDC is ERC20 {
    address public chargedSender;

    constructor() ERC20("Stateful Debit Fee USDC", "sdfUSDC") { }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(
        address to,
        uint256 amount
    ) external {
        _mint(to, amount);
    }

    function chargeSender(
        address sender
    ) external {
        chargedSender = sender;
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        if (from == chargedSender && to != address(0)) super._update(from, address(0), 1);
        super._update(from, to, value);
    }
}

contract HeirloomLifecycleHandler is Test {
    HeirloomVault public immutable controlVault;
    HeirloomVault public immutable distributionVault;
    MockUSDC public immutable usdc;

    address public immutable initialOwner;
    address public immutable outsider;
    address public immutable guardianA;
    address public immutable guardianB;
    address public immutable guardianC;

    bool public livenessViolation;
    bool public ownerAuthorizationViolation;
    bool public claimViolation;
    bool public distributionViolation;
    bool public payoutViolation;
    bool public doubleResolutionViolation;
    bool public exactDeltaViolation;
    bool public recoveryViolation;

    uint256 public distributionStarts;
    uint256 public completedRecoveries;

    bytes private _replacementConfig;

    constructor(
        HeirloomVault controlTarget,
        HeirloomVault distributionTarget,
        MockUSDC token,
        address ownerAddress,
        address outsiderAddress,
        address firstGuardian,
        address secondGuardian,
        address thirdGuardian,
        bytes memory replacementConfig
    ) {
        controlVault = controlTarget;
        distributionVault = distributionTarget;
        usdc = token;
        initialOwner = ownerAddress;
        outsider = outsiderAddress;
        guardianA = firstGuardian;
        guardianB = secondGuardian;
        guardianC = thirdGuardian;
        _replacementConfig = replacementConfig;
    }

    // I1-I2: only owner-authorized actions and completed recovery may create liveness.
    function advanceTime(
        uint32 rawSeconds
    ) external {
        uint64 beforeSeen = controlVault.lastSeen();
        uint64 beforeNonce = controlVault.livenessNonce();
        vm.warp(block.timestamp + bound(uint256(rawSeconds), 1, 200 days));
        _recordPermissionlessLiveness(beforeSeen, beforeNonce);
    }

    function thirdPartyTransfer(
        uint96 rawAmount
    ) external {
        if (!_recoverable()) return;
        uint256 amount = bound(uint256(rawAmount), 1, 1_000_000e6);
        uint64 beforeSeen = controlVault.lastSeen();
        uint64 beforeNonce = controlVault.livenessNonce();
        usdc.mint(outsider, amount);
        vm.prank(outsider);
        assertTrue(usdc.transfer(address(controlVault), amount));
        _recordPermissionlessLiveness(beforeSeen, beforeNonce);
    }

    function ownerAction(
        uint8 rawAction,
        uint96 rawAmount
    ) external {
        if (!_recoverable()) return;

        address currentOwner = controlVault.owner();
        uint64 beforeNonce = controlVault.livenessNonce();
        bool executed;
        uint8 action = rawAction % 7;

        if (action == 0) {
            vm.prank(currentOwner);
            controlVault.heartbeat();
            executed = true;
        } else if (action == 1) {
            uint256 amount = bound(uint256(rawAmount), 1, 1_000_000e6);
            usdc.mint(currentOwner, amount);
            vm.startPrank(currentOwner);
            usdc.approve(address(controlVault), amount);
            controlVault.deposit(amount);
            vm.stopPrank();
            executed = true;
        } else if (action == 2) {
            uint256 balance = usdc.balanceOf(address(controlVault));
            if (balance == 0) return;
            uint256 amount = bound(uint256(rawAmount), 1, balance);
            vm.prank(currentOwner);
            controlVault.withdraw(amount, outsider);
            executed = true;
        } else if (action == 3) {
            if (controlVault.state() != HeirloomTypes.VaultState.ClaimRequested) return;
            vm.prank(currentOwner);
            controlVault.cancelClaimWithHeartbeat();
            executed = true;
        } else if (action == 4) {
            if (
                controlVault.state() != HeirloomTypes.VaultState.Active
                    || currentOwner != initialOwner
            ) return;
            vm.prank(currentOwner);
            controlVault.proposeConfig(_replacementConfig);
            executed = true;
        } else if (action == 5) {
            (bytes32 configHash,,,) = controlVault.pendingConfig();
            if (controlVault.state() != HeirloomTypes.VaultState.Active || configHash == bytes32(0))
            {
                return;
            }
            vm.prank(currentOwner);
            controlVault.vetoConfig();
            executed = true;
        } else {
            (uint64 recoveryRequestNonce,,,,,) = controlVault.recoveryRequest();
            if (recoveryRequestNonce == 0) return;
            vm.prank(currentOwner);
            controlVault.vetoRecovery();
            executed = true;
        }

        if (
            executed
                && (controlVault.lastSeen() != uint64(block.timestamp)
                    || controlVault.livenessNonce() != beforeNonce + 1)
        ) ownerAuthorizationViolation = true;
    }

    function permissionlessExecuteConfig() external {
        if (controlVault.state() != HeirloomTypes.VaultState.Active) return;
        (bytes32 configHash,, uint64 eta, uint64 expiresAt) = controlVault.pendingConfig();
        if (configHash == bytes32(0) || block.timestamp > expiresAt) return;
        if (block.timestamp < eta) vm.warp(eta);

        uint64 beforeSeen = controlVault.lastSeen();
        uint64 beforeNonce = controlVault.livenessNonce();
        vm.prank(outsider);
        controlVault.executeConfig(_replacementConfig);
        _recordPermissionlessLiveness(beforeSeen, beforeNonce);
    }

    // I3: random permissionless claims must bind the current epochs and move no asset.
    function permissionlessRequestClaim() external {
        if (controlVault.state() != HeirloomTypes.VaultState.Active) return;
        (uint64 inactivity,,,,,,,) = controlVault.durations();
        uint256 maturedAt = uint256(controlVault.lastSeen()) + inactivity;
        if (block.timestamp < maturedAt) vm.warp(maturedAt);

        uint256 beforeBalance = usdc.balanceOf(address(controlVault));
        uint64 beforeSeen = controlVault.lastSeen();
        uint64 beforeLiveness = controlVault.livenessNonce();
        uint64 beforeConfig = controlVault.configNonce();
        vm.prank(outsider);
        controlVault.requestClaim();

        (uint64 nonce,,, uint64 requestLiveness, uint64 requestConfig) = controlVault.claimRequest();
        if (
            nonce == 0 || requestLiveness != beforeLiveness || requestConfig != beforeConfig
                || usdc.balanceOf(address(controlVault)) != beforeBalance
        ) claimViolation = true;
        _recordPermissionlessLiveness(beforeSeen, beforeLiveness);
    }

    // I4: the only successful irreversible transition consumes a current-epoch claim.
    function permissionlessStartDistribution() external {
        if (controlVault.state() != HeirloomTypes.VaultState.ClaimRequested) return;
        (uint64 requestNonce,, uint64 executeAfter, uint64 requestLiveness, uint64 requestConfig) =
            controlVault.claimRequest();
        if (block.timestamp < executeAfter) vm.warp(executeAfter);

        uint64 beforeSeen = controlVault.lastSeen();
        uint64 beforeLiveness = controlVault.livenessNonce();
        uint256 beforeBalance = usdc.balanceOf(address(controlVault));
        if (
            requestNonce == 0 || requestLiveness != beforeLiveness
                || requestConfig != controlVault.configNonce()
        ) {
            distributionViolation = true;
            return;
        }

        vm.prank(outsider);
        controlVault.startDistribution();
        ++distributionStarts;
        (uint64 remainingClaimNonce,,,,) = controlVault.claimRequest();
        HeirloomTypes.VaultState expectedState = beforeBalance == 0
            ? HeirloomTypes.VaultState.Settled
            : HeirloomTypes.VaultState.Distributing;
        if (
            controlVault.state() != expectedState || controlVault.snapshotBalance() != beforeBalance
                || remainingClaimNonce != 0 || distributionStarts != 1
        ) distributionViolation = true;
        _recordPermissionlessLiveness(beforeSeen, beforeLiveness);
    }

    // I2 and I15: guardian votes cannot create liveness; activation is checked separately.
    function guardianRecoveryStep(
        uint8 rawGuardian
    ) external {
        if (!_recoverable() || controlVault.recoveryAddress() == controlVault.owner()) return;
        uint64 beforeSeen = controlVault.lastSeen();
        uint64 beforeNonce = controlVault.livenessNonce();
        (uint64 requestNonce,,, uint64 expiresAt,, bool thresholdReached) =
            controlVault.recoveryRequest();

        if (requestNonce == 0) {
            vm.prank(guardianA);
            controlVault.requestRecovery();
        } else if (block.timestamp > expiresAt) {
            vm.prank(outsider);
            controlVault.clearExpiredRecovery();
        } else if (!thresholdReached) {
            address approver = rawGuardian % 2 == 0 ? guardianB : guardianC;
            if (controlVault.recoveryApproved(requestNonce, approver)) return;
            vm.prank(approver);
            controlVault.approveRecovery(requestNonce);
        } else {
            return;
        }
        _recordPermissionlessLiveness(beforeSeen, beforeNonce);
    }

    function completeRecovery() external {
        if (!_recoverable() || controlVault.recoveryAddress() == controlVault.owner()) return;
        (uint64 requestNonce,,, uint64 expiresAt,, bool thresholdReached) =
            controlVault.recoveryRequest();
        if (requestNonce != 0 && block.timestamp > expiresAt) {
            controlVault.clearExpiredRecovery();
            return;
        }
        if (requestNonce == 0) {
            vm.prank(guardianA);
            controlVault.requestRecovery();
            (requestNonce,,, expiresAt,, thresholdReached) = controlVault.recoveryRequest();
        }
        if (!thresholdReached) {
            address approver =
                controlVault.recoveryApproved(requestNonce, guardianB) ? guardianC : guardianB;
            vm.prank(approver);
            controlVault.approveRecovery(requestNonce);
        }

        uint64 readyAt;
        (requestNonce,, readyAt, expiresAt,, thresholdReached) = controlVault.recoveryRequest();
        if (!thresholdReached || block.timestamp > expiresAt) return;
        if (block.timestamp < readyAt) vm.warp(readyAt);

        address committedOwner = controlVault.recoveryAddress();
        uint64 beforeLiveness = controlVault.livenessNonce();
        uint64 beforeConfig = controlVault.configNonce();
        uint64 beforeRecovery = controlVault.recoveryNonce();
        vm.prank(outsider);
        controlVault.activateRecovery();
        ++completedRecoveries;

        (uint64 remainingClaimNonce,,,,) = controlVault.claimRequest();
        (bytes32 remainingConfigHash,,,) = controlVault.pendingConfig();
        (uint64 remainingRecoveryNonce,,,,,) = controlVault.recoveryRequest();
        if (
            controlVault.owner() != committedOwner
                || controlVault.state() != HeirloomTypes.VaultState.Active
                || controlVault.lastSeen() != uint64(block.timestamp)
                || controlVault.livenessNonce() != beforeLiveness + 1
                || controlVault.configNonce() != beforeConfig + 1
                || controlVault.recoveryNonce() != beforeRecovery + 1 || remainingClaimNonce != 0
                || remainingConfigHash != bytes32(0) || remainingRecoveryNonce != 0
                || completedRecoveries != 1
        ) recoveryViolation = true;
    }

    // I5-I14 distribution actions. The caller supplies only an index; every other choice is derived.
    function executePayout(
        uint8 rawIndex
    ) external {
        if (distributionVault.state() != HeirloomTypes.VaultState.Distributing) return;
        uint8 index = uint8(bound(rawIndex, 0, distributionVault.beneficiaryCount() - 1));
        if (
            distributionVault.beneficiaryStatus(index) != HeirloomTypes.BeneficiaryStatus.Unresolved
        ) return;
        HeirloomTypes.DestinationPhase phase = distributionVault.destinationPhase(index);
        if (
            phase != HeirloomTypes.DestinationPhase.PrimaryOnly
                && phase != HeirloomTypes.DestinationPhase.FallbackOnly
        ) return;

        HeirloomTypes.Beneficiary memory item = distributionVault.beneficiary(index);
        address destination = phase == HeirloomTypes.DestinationPhase.PrimaryOnly
            ? item.primary
            : item.fallbackAddress;
        address excluded = phase == HeirloomTypes.DestinationPhase.PrimaryOnly
            ? item.fallbackAddress
            : item.primary;
        uint256 amount = distributionVault.entitlement(index);
        uint256 beforeVaultBalance = usdc.balanceOf(address(distributionVault));
        uint256 beforeRemaining = distributionVault.snapshotRemaining();
        uint256 beforeDestination = usdc.balanceOf(destination);
        uint256 beforeExcluded = usdc.balanceOf(excluded);
        uint256 beforeCaller = usdc.balanceOf(outsider);

        vm.prank(outsider);
        distributionVault.executePayout(index);

        if (
            usdc.balanceOf(destination) != beforeDestination + amount
                || usdc.balanceOf(excluded) != beforeExcluded
                || usdc.balanceOf(outsider) != beforeCaller
                || distributionVault.beneficiaryStatus(index)
                    != HeirloomTypes.BeneficiaryStatus.Paid
        ) payoutViolation = true;
        if (
            beforeVaultBalance - usdc.balanceOf(address(distributionVault)) != amount
                || beforeRemaining - distributionVault.snapshotRemaining() != amount
        ) exactDeltaViolation = true;
    }

    function rolloverPayout(
        uint8 rawIndex
    ) external {
        if (distributionVault.state() != HeirloomTypes.VaultState.Distributing) return;
        uint8 index = uint8(bound(rawIndex, 0, distributionVault.beneficiaryCount() - 1));
        if (
            distributionVault.beneficiaryStatus(index) != HeirloomTypes.BeneficiaryStatus.Unresolved
                || distributionVault.destinationPhase(index)
                    != HeirloomTypes.DestinationPhase.RolloverOnly
        ) return;

        HeirloomTypes.Beneficiary memory item = distributionVault.beneficiary(index);
        uint256 beforePrimary = usdc.balanceOf(item.primary);
        uint256 beforeFallback = usdc.balanceOf(item.fallbackAddress);
        uint256 beforeRemaining = distributionVault.snapshotRemaining();
        vm.prank(outsider);
        distributionVault.rolloverPayout(index);
        if (
            usdc.balanceOf(item.primary) != beforePrimary
                || usdc.balanceOf(item.fallbackAddress) != beforeFallback
                || distributionVault.snapshotRemaining() != beforeRemaining
                || distributionVault.beneficiaryStatus(index)
                    != HeirloomTypes.BeneficiaryStatus.RolledOver
        ) payoutViolation = true;
    }

    function attemptSecondResolution(
        uint8 rawIndex
    ) external {
        uint8 index = uint8(bound(rawIndex, 0, distributionVault.beneficiaryCount() - 1));
        if (
            distributionVault.state() != HeirloomTypes.VaultState.Distributing
                || distributionVault.beneficiaryStatus(index)
                    == HeirloomTypes.BeneficiaryStatus.Unresolved
        ) return;

        uint256 beforeRemaining = distributionVault.snapshotRemaining();
        uint256 beforePaid = distributionVault.totalNonTerminalPaid();
        uint256 beforeRolled = distributionVault.totalRolledOver();
        uint8 beforeResolved = distributionVault.resolvedNonTerminalCount();
        vm.prank(outsider);
        (bool succeeded,) =
            address(distributionVault).call(abi.encodeCall(HeirloomVault.executePayout, (index)));
        if (
            succeeded || distributionVault.snapshotRemaining() != beforeRemaining
                || distributionVault.totalNonTerminalPaid() != beforePaid
                || distributionVault.totalRolledOver() != beforeRolled
                || distributionVault.resolvedNonTerminalCount() != beforeResolved
        ) doubleResolutionViolation = true;
    }

    function executeTerminalPayout() external {
        if (
            distributionVault.state() != HeirloomTypes.VaultState.Distributing
                || distributionVault.terminalUnlockedAt() == 0
        ) return;
        uint256 amount = distributionVault.snapshotRemaining();
        if (amount == 0) return;
        HeirloomTypes.Beneficiary memory terminal = distributionVault.terminalBeneficiary();
        HeirloomTypes.DestinationPhase phase = distributionVault.terminalDestinationPhase();
        address destination = phase == HeirloomTypes.DestinationPhase.TerminalPrimaryOnly
            ? terminal.primary
            : terminal.fallbackAddress;
        address excluded = phase == HeirloomTypes.DestinationPhase.TerminalPrimaryOnly
            ? terminal.fallbackAddress
            : terminal.primary;
        uint256 beforeDestination = usdc.balanceOf(destination);
        uint256 beforeExcluded = usdc.balanceOf(excluded);
        vm.prank(outsider);
        distributionVault.executeTerminalPayout();
        if (
            usdc.balanceOf(destination) != beforeDestination + amount
                || usdc.balanceOf(excluded) != beforeExcluded
                || distributionVault.settledTerminalDestination() != destination
        ) payoutViolation = true;
    }

    function advanceDistributionPhase(
        uint8 rawPhase,
        uint32 rawSeconds
    ) external {
        uint8 phase = rawPhase % 4;
        if (phase == 0 && block.timestamp < distributionVault.fallbackAt()) {
            vm.warp(distributionVault.fallbackAt());
        } else if (phase == 1 && block.timestamp < distributionVault.rolloverAt()) {
            vm.warp(distributionVault.rolloverAt());
        } else if (
            phase == 2 && distributionVault.terminalFallbackAt() != 0
                && block.timestamp < distributionVault.terminalFallbackAt()
        ) {
            vm.warp(distributionVault.terminalFallbackAt());
        } else if (phase == 3) {
            vm.warp(block.timestamp + bound(uint256(rawSeconds), 1, 200 days));
        }
    }

    function addOrSweepExcess(
        uint96 rawAmount
    ) external {
        uint256 amount = bound(uint256(rawAmount), 1, 1_000_000e6);
        if (distributionVault.state() == HeirloomTypes.VaultState.Settled) {
            usdc.mint(address(distributionVault), amount);
            vm.prank(outsider);
            distributionVault.sweepExcess();
        } else if (distributionVault.state() == HeirloomTypes.VaultState.Distributing) {
            usdc.mint(address(distributionVault), amount);
        }
    }

    function _recoverable() internal view returns (bool) {
        HeirloomTypes.VaultState currentState = controlVault.state();
        return currentState == HeirloomTypes.VaultState.Active
            || currentState == HeirloomTypes.VaultState.ClaimRequested;
    }

    function _recordPermissionlessLiveness(
        uint64 beforeSeen,
        uint64 beforeNonce
    ) internal {
        if (controlVault.lastSeen() != beforeSeen || controlVault.livenessNonce() != beforeNonce) {
            livenessViolation = true;
        }
    }
}

contract HeirloomVaultInvariantTest is StdInvariant, Test {
    uint256 internal constant DEPOSIT = 1_000_000e6 + 7;

    address internal owner = makeAddr("stateful-owner");
    address internal outsider = makeAddr("stateful-outsider");
    address internal recovery = makeAddr("stateful-recovery");
    address internal guardianA = makeAddr("stateful-guardian-a");
    address internal guardianB = makeAddr("stateful-guardian-b");
    address internal guardianC = makeAddr("stateful-guardian-c");

    MockUSDC internal usdc;
    HeirloomFactory internal factory;
    HeirloomVault internal controlVault;
    HeirloomVault internal distributionVault;
    HeirloomLifecycleHandler internal handler;

    function setUp() public {
        usdc = new MockUSDC();
        factory = new HeirloomFactory(usdc);
        controlVault = HeirloomVault(
            factory.createVault(owner, keccak256("stateful-control"), _config(90 days))
        );
        distributionVault = HeirloomVault(
            factory.createVault(owner, keccak256("stateful-distribution"), _config(90 days))
        );
        _deposit(controlVault, DEPOSIT);
        _deposit(distributionVault, DEPOSIT);
        _startDistribution(distributionVault);

        handler = new HeirloomLifecycleHandler(
            controlVault,
            distributionVault,
            usdc,
            owner,
            outsider,
            guardianA,
            guardianB,
            guardianC,
            abi.encode(_config(91 days))
        );
        targetContract(address(handler));
    }

    function invariantI1ToI4_LivenessClaimsAndIrreversibleBoundary() public view {
        assertFalse(handler.livenessViolation(), "I1/I2 permissionless liveness");
        assertFalse(handler.ownerAuthorizationViolation(), "I1 owner authorization");
        assertFalse(handler.claimViolation(), "I3 claim binding or asset movement");
        assertFalse(handler.distributionViolation(), "I4 distribution boundary");

        if (controlVault.state() == HeirloomTypes.VaultState.ClaimRequested) {
            (uint64 nonce,,, uint64 requestLiveness, uint64 requestConfig) =
                controlVault.claimRequest();
            assertGt(nonce, 0);
            assertEq(requestLiveness, controlVault.livenessNonce());
            assertEq(requestConfig, controlVault.configNonce());
        }
        if (controlVault.state() >= HeirloomTypes.VaultState.Distributing) {
            assertEq(handler.distributionStarts(), 1);
            assertGt(controlVault.distributionStartedAt(), 0);
            (uint64 nonce,,,,) = controlVault.claimRequest();
            assertEq(nonce, 0);
        }
    }

    function invariantI5ToI10_DestinationResolutionAndConservation() public view {
        assertFalse(handler.payoutViolation(), "I5 caller aimed payout");
        assertFalse(handler.doubleResolutionViolation(), "I8 duplicate resolution");

        uint256 resolved;
        uint256 entitlementSum;
        uint256 length = distributionVault.beneficiaryCount();
        for (uint8 i; i < length; ++i) {
            HeirloomTypes.BeneficiaryStatus status = distributionVault.beneficiaryStatus(i);
            entitlementSum += distributionVault.entitlement(i);
            if (status != HeirloomTypes.BeneficiaryStatus.Unresolved) ++resolved;

            HeirloomTypes.DestinationPhase actual = distributionVault.destinationPhase(i);
            if (distributionVault.state() == HeirloomTypes.VaultState.Settled) {
                assertEq(uint8(actual), uint8(HeirloomTypes.DestinationPhase.Settled));
            } else if (status != HeirloomTypes.BeneficiaryStatus.Unresolved) {
                assertEq(uint8(actual), uint8(HeirloomTypes.DestinationPhase.Unavailable));
            } else if (block.timestamp < distributionVault.fallbackAt()) {
                assertEq(uint8(actual), uint8(HeirloomTypes.DestinationPhase.PrimaryOnly));
            } else if (block.timestamp < distributionVault.rolloverAt()) {
                assertEq(uint8(actual), uint8(HeirloomTypes.DestinationPhase.FallbackOnly));
            } else {
                assertEq(uint8(actual), uint8(HeirloomTypes.DestinationPhase.RolloverOnly));
            }
        }

        assertEq(distributionVault.resolvedNonTerminalCount(), resolved);
        if (distributionVault.terminalUnlockedAt() == 0) assertLt(resolved, length);
        if (distributionVault.terminalUnlockedAt() != 0) assertEq(resolved, length);

        HeirloomTypes.Beneficiary memory terminal = distributionVault.terminalBeneficiary();
        uint256 terminalFloor = distributionVault.snapshotBalance() * terminal.bps / 10_000;
        uint256 terminalBase = distributionVault.snapshotBalance() - entitlementSum;
        assertGe(terminalBase, terminalFloor);
        assertLt(terminalBase - terminalFloor, length + 1);
        assertEq(entitlementSum + terminalBase, distributionVault.snapshotBalance());
    }

    function invariantI11I13I14_RolloverExactDeltaAndSettlement() public view {
        assertFalse(handler.exactDeltaViolation(), "I13 outgoing delta mismatch");
        if (distributionVault.state() == HeirloomTypes.VaultState.Distributing) {
            assertEq(
                distributionVault.totalNonTerminalPaid() + distributionVault.snapshotRemaining(),
                distributionVault.snapshotBalance()
            );
        }
        assertGe(usdc.balanceOf(address(distributionVault)), distributionVault.snapshotRemaining());

        uint256 rolledAmount;
        uint256 length = distributionVault.beneficiaryCount();
        for (uint8 i; i < length; ++i) {
            if (
                distributionVault.beneficiaryStatus(i) == HeirloomTypes.BeneficiaryStatus.RolledOver
            ) rolledAmount += distributionVault.entitlement(i);
        }
        assertEq(distributionVault.totalRolledOver(), rolledAmount);

        if (distributionVault.state() == HeirloomTypes.VaultState.Settled) {
            assertEq(distributionVault.snapshotRemaining(), 0);
            assertTrue(distributionVault.terminalPaid());
            assertEq(distributionVault.resolvedNonTerminalCount(), length);
            assertTrue(distributionVault.settledTerminalDestination() != address(0));
        }
    }

    function invariantI15I16_RecoveryAndPermanentIdentity() public view {
        assertFalse(handler.recoveryViolation(), "I15 recovery invalidation");
        assertLe(handler.completedRecoveries(), 1);
        assertTrue(controlVault.owner() == owner || controlVault.owner() == recovery);
        if (handler.completedRecoveries() == 1) assertEq(controlVault.owner(), recovery);

        _assertIdentity(controlVault);
        _assertIdentity(distributionVault);
    }

    function testZeroBalanceDistributionMaySettleAtIrreversibleBoundary() public {
        handler.ownerAction(2, uint96(DEPOSIT));
        assertEq(usdc.balanceOf(address(controlVault)), 0);

        handler.permissionlessRequestClaim();
        handler.permissionlessStartDistribution();

        assertFalse(handler.distributionViolation());
        assertEq(handler.distributionStarts(), 1);
        assertEq(uint8(controlVault.state()), uint8(HeirloomTypes.VaultState.Settled));
        assertEq(controlVault.snapshotBalance(), 0);
        assertTrue(controlVault.terminalPaid());
    }

    function _assertIdentity(
        HeirloomVault target
    ) internal view {
        assertEq(target.factory(), address(factory));
        assertEq(address(target.asset()), address(usdc));
        assertEq(target.versionId(), factory.VERSION_ID());
        assertTrue(factory.isVault(address(target)));
        assertEq(factory.vaultRuntimeCodeHash(address(target)), address(target).codehash);
        assertTrue(address(target).codehash != bytes32(0));
    }

    function _deposit(
        HeirloomVault target,
        uint256 amount
    ) internal {
        usdc.mint(owner, amount);
        vm.startPrank(owner);
        usdc.approve(address(target), amount);
        target.deposit(amount);
        vm.stopPrank();
    }

    function _startDistribution(
        HeirloomVault target
    ) internal {
        (uint64 inactivity,,,,,,,) = target.durations();
        vm.warp(uint256(target.lastSeen()) + inactivity);
        vm.prank(outsider);
        target.requestClaim();
        (,, uint64 executeAfter,,) = target.claimRequest();
        vm.warp(executeAfter);
        vm.prank(outsider);
        target.startDistribution();
    }

    function _config(
        uint64 inactivity
    ) internal returns (HeirloomTypes.VaultConfig memory config) {
        config.beneficiaries = new HeirloomTypes.Beneficiary[](3);
        config.beneficiaries[0] = HeirloomTypes.Beneficiary(
            makeAddr("stateful-primary-a"), makeAddr("stateful-fallback-a"), 1111
        );
        config.beneficiaries[1] = HeirloomTypes.Beneficiary(
            makeAddr("stateful-primary-b"), makeAddr("stateful-fallback-b"), 2222
        );
        config.beneficiaries[2] = HeirloomTypes.Beneficiary(
            makeAddr("stateful-primary-c"), makeAddr("stateful-fallback-c"), 3333
        );
        config.terminal = HeirloomTypes.Beneficiary(
            makeAddr("stateful-terminal-primary"), makeAddr("stateful-terminal-fallback"), 3334
        );
        config.durations = HeirloomTypes.Durations(
            inactivity, 7 days, 30 days, 30 days, 2 days, 30 days, 2 days, 30 days
        );
        config.guardians = new address[](3);
        config.guardians[0] = guardianA;
        config.guardians[1] = guardianB;
        config.guardians[2] = guardianC;
        config.guardianThreshold = 2;
        config.recoveryAddress = recovery;
    }
}

contract InexactTransferHandler is Test {
    StatefulDebitFeeUSDC public immutable token;
    HeirloomVault public immutable vault;
    address public immutable outsider;
    bool public rollbackViolation;

    constructor(
        StatefulDebitFeeUSDC supportedToken,
        HeirloomVault target,
        address caller
    ) {
        token = supportedToken;
        vault = target;
        outsider = caller;
    }

    function attemptInexactPayout(
        uint8 rawIndex
    ) external {
        uint8 index = uint8(bound(rawIndex, 0, vault.beneficiaryCount() - 1));
        if (
            vault.beneficiaryStatus(index) != HeirloomTypes.BeneficiaryStatus.Unresolved
                || vault.destinationPhase(index) != HeirloomTypes.DestinationPhase.PrimaryOnly
        ) return;

        HeirloomTypes.Beneficiary memory item = vault.beneficiary(index);
        uint256 beforeBalance = token.balanceOf(address(vault));
        uint256 beforeDestination = token.balanceOf(item.primary);
        uint256 beforeRemaining = vault.snapshotRemaining();
        uint256 beforePaid = vault.totalNonTerminalPaid();
        uint8 beforeResolved = vault.resolvedNonTerminalCount();
        vm.prank(outsider);
        (bool succeeded,) =
            address(vault).call(abi.encodeCall(HeirloomVault.executePayout, (index)));

        if (
            succeeded || token.balanceOf(address(vault)) != beforeBalance
                || token.balanceOf(item.primary) != beforeDestination
                || vault.snapshotRemaining() != beforeRemaining
                || vault.totalNonTerminalPaid() != beforePaid
                || vault.resolvedNonTerminalCount() != beforeResolved
                || vault.beneficiaryStatus(index) != HeirloomTypes.BeneficiaryStatus.Unresolved
        ) rollbackViolation = true;
    }
}

contract HeirloomInexactTransferInvariantTest is StdInvariant, Test {
    uint256 internal constant DEPOSIT = 1_000_000e6;

    address internal owner = makeAddr("inexact-owner");
    address internal outsider = makeAddr("inexact-outsider");
    StatefulDebitFeeUSDC internal token;
    HeirloomVault internal vault;
    InexactTransferHandler internal handler;

    function setUp() public {
        token = new StatefulDebitFeeUSDC();
        HeirloomFactory factory = new HeirloomFactory(token);
        vault = HeirloomVault(factory.createVault(owner, keccak256("stateful-inexact"), _config()));
        token.mint(owner, DEPOSIT);
        vm.startPrank(owner);
        token.approve(address(vault), DEPOSIT);
        vault.deposit(DEPOSIT);
        vm.stopPrank();

        (uint64 inactivity,,,,,,,) = vault.durations();
        vm.warp(uint256(vault.lastSeen()) + inactivity);
        vm.prank(outsider);
        vault.requestClaim();
        (,, uint64 executeAfter,,) = vault.claimRequest();
        vm.warp(executeAfter);
        vault.startDistribution();
        token.chargeSender(address(vault));

        handler = new InexactTransferHandler(token, vault, outsider);
        targetContract(address(handler));
    }

    function invariantI12_InexactTransferRollsBackAllState() public view {
        assertFalse(handler.rollbackViolation());
        assertEq(vault.snapshotRemaining(), vault.snapshotBalance());
        assertEq(vault.totalNonTerminalPaid(), 0);
        assertEq(vault.totalRolledOver(), 0);
        assertEq(vault.resolvedNonTerminalCount(), 0);
        for (uint8 i; i < vault.beneficiaryCount(); ++i) {
            assertEq(
                uint8(vault.beneficiaryStatus(i)), uint8(HeirloomTypes.BeneficiaryStatus.Unresolved)
            );
        }
    }

    function _config() internal returns (HeirloomTypes.VaultConfig memory config) {
        config.beneficiaries = new HeirloomTypes.Beneficiary[](2);
        config.beneficiaries[0] = HeirloomTypes.Beneficiary(
            makeAddr("inexact-primary-a"), makeAddr("inexact-fallback-a"), 3000
        );
        config.beneficiaries[1] = HeirloomTypes.Beneficiary(
            makeAddr("inexact-primary-b"), makeAddr("inexact-fallback-b"), 2000
        );
        config.terminal = HeirloomTypes.Beneficiary(
            makeAddr("inexact-terminal-primary"), makeAddr("inexact-terminal-fallback"), 5000
        );
        config.durations = HeirloomTypes.Durations(
            90 days, 7 days, 30 days, 30 days, 2 days, 30 days, 2 days, 30 days
        );
        config.guardians = new address[](3);
        config.guardians[0] = makeAddr("inexact-guardian-a");
        config.guardians[1] = makeAddr("inexact-guardian-b");
        config.guardians[2] = makeAddr("inexact-guardian-c");
        config.guardianThreshold = 2;
        config.recoveryAddress = makeAddr("inexact-recovery");
    }
}

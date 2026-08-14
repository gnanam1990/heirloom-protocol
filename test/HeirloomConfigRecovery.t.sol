// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { HeirloomFactory } from "../src/HeirloomFactory.sol";
import { HeirloomTypes } from "../src/HeirloomTypes.sol";
import { HeirloomVault } from "../src/HeirloomVault.sol";
import { IHeirloomVault } from "../src/interfaces/IHeirloomVault.sol";
import { MockUSDC } from "./mocks/MockUSDC.sol";

contract HeirloomConfigRecoveryTest is Test {
    address internal owner = makeAddr("owner");
    address internal outsider = makeAddr("outsider");
    address internal recovery = makeAddr("recovery");
    address internal guardianA = makeAddr("guardianA");
    address internal guardianB = makeAddr("guardianB");
    address internal guardianC = makeAddr("guardianC");

    MockUSDC internal usdc;
    HeirloomFactory internal factory;
    HeirloomVault internal vault;

    function setUp() public {
        usdc = new MockUSDC();
        factory = new HeirloomFactory(usdc);
        vault = HeirloomVault(factory.createVault(owner, keccak256("config"), _config(90 days)));
    }

    function testOwnerExecutingConfigStillDoesNotHeartbeat() public {
        bytes memory encoded = abi.encode(_config(91 days));
        vm.prank(owner);
        vault.proposeConfig(encoded);
        uint64 seen = vault.lastSeen();
        uint64 liveness = vault.livenessNonce();
        (,, uint64 eta,) = vault.pendingConfig();

        vm.warp(eta);
        vm.prank(owner);
        vault.executeConfig(encoded);

        assertEq(vault.lastSeen(), seen);
        assertEq(vault.livenessNonce(), liveness);
    }

    function testGuardianVotesNeverCreateLiveness() public {
        uint64 seen = vault.lastSeen();
        uint64 liveness = vault.livenessNonce();
        vm.prank(guardianA);
        vault.requestRecovery();
        (uint64 nonce,,,,,) = vault.recoveryRequest();
        vm.prank(guardianB);
        vault.approveRecovery(nonce);

        assertEq(vault.lastSeen(), seen);
        assertEq(vault.livenessNonce(), liveness);
    }

    function testConfigReplacementRestartsDelayAndInvalidatesOldPayload() public {
        bytes memory first = abi.encode(_config(91 days));
        bytes memory second = abi.encode(_config(92 days));
        vm.prank(owner);
        vault.proposeConfig(first);
        (,, uint64 firstEta,) = vault.pendingConfig();

        vm.warp(firstEta - 1 days);
        vm.prank(owner);
        vault.proposeConfig(second);
        (,, uint64 secondEta,) = vault.pendingConfig();
        assertGt(secondEta, firstEta);

        vm.warp(firstEta);
        vm.expectRevert(IHeirloomVault.ConfigNotReady.selector);
        vault.executeConfig(second);

        vm.warp(secondEta);
        vm.expectRevert(IHeirloomVault.ConfigHashMismatch.selector);
        vault.executeConfig(first);
        vault.executeConfig(second);
        assertEq(vault.configNonce(), 2);
    }

    function testConfigExecutionAndExpiryExactBoundaries() public {
        bytes memory encoded = abi.encode(_config(91 days));
        vm.prank(owner);
        vault.proposeConfig(encoded);
        (,,, uint64 expiresAt) = vault.pendingConfig();

        vm.warp(expiresAt);
        vault.executeConfig(encoded);
        assertEq(vault.configNonce(), 2);

        bytes memory next = abi.encode(_config(92 days));
        vm.prank(owner);
        vault.proposeConfig(next);
        (,,, uint64 nextExpiry) = vault.pendingConfig();
        vm.warp(uint256(nextExpiry) + 1);
        vm.expectRevert(IHeirloomVault.ConfigProposalExpired.selector);
        vault.executeConfig(next);
        vault.clearExpiredConfig();
        (bytes32 pendingHash,,,) = vault.pendingConfig();
        assertEq(pendingHash, bytes32(0));
    }

    function testConfigurationIsFrozenAfterClaimRequest() public {
        bytes memory encoded = abi.encode(_config(91 days));
        vm.prank(owner);
        vault.proposeConfig(encoded);
        vm.warp(uint256(vault.lastSeen()) + 90 days);
        vault.requestClaim();

        vm.expectRevert(IHeirloomVault.InvalidState.selector);
        vault.executeConfig(encoded);
        vm.prank(owner);
        vm.expectRevert(IHeirloomVault.InvalidState.selector);
        vault.vetoConfig();
        vm.prank(owner);
        vm.expectRevert(IHeirloomVault.InvalidState.selector);
        vault.proposeConfig(encoded);
        vm.expectRevert(IHeirloomVault.InvalidState.selector);
        vault.clearExpiredConfig();
    }

    function testDistributionInvalidatesPendingConfigWithoutChangingEpoch() public {
        bytes memory encoded = abi.encode(_config(91 days));
        vm.prank(owner);
        vault.proposeConfig(encoded);
        bytes32 proposedHash = vault.proposalDigest(encoded);
        uint64 beforeConfigNonce = vault.configNonce();

        vm.warp(uint256(vault.lastSeen()) + 90 days);
        vault.requestClaim();
        (,, uint64 executeAfter,,) = vault.claimRequest();
        vm.warp(executeAfter);
        vm.expectEmit(true, false, false, true, address(vault));
        emit IHeirloomVault.ConfigInvalidated(proposedHash, beforeConfigNonce);
        vault.startDistribution();

        (bytes32 pendingHash,,,) = vault.pendingConfig();
        assertEq(pendingHash, bytes32(0));
        assertEq(vault.configNonce(), beforeConfigNonce);
    }

    function testThresholdReachedRecoveryBlocksConfigUntilOwnerVeto() public {
        bytes memory encoded = abi.encode(_config(91 days));
        vm.prank(owner);
        vault.proposeConfig(encoded);
        (,, uint64 eta,) = vault.pendingConfig();

        vm.prank(guardianA);
        vault.requestRecovery();
        (uint64 requestNonce,,,,,) = vault.recoveryRequest();
        vm.prank(guardianB);
        vault.approveRecovery(requestNonce);

        vm.warp(eta);
        vm.expectRevert(IHeirloomVault.RecoveryBlocksConfig.selector);
        vm.prank(outsider);
        vault.executeConfig(encoded);

        vm.prank(owner);
        vault.vetoRecovery();
        vm.prank(outsider);
        vault.executeConfig(encoded);
        assertEq(vault.configNonce(), 2);
    }

    function testPreThresholdRecoveryIsInvalidatedByConfigExecution() public {
        bytes memory encoded = abi.encode(_config(91 days));
        vm.prank(owner);
        vault.proposeConfig(encoded);
        (,, uint64 eta,) = vault.pendingConfig();

        vm.prank(guardianA);
        vault.requestRecovery();
        vm.warp(eta);
        vm.prank(outsider);
        vault.executeConfig(encoded);

        (uint64 requestNonce,,,,,) = vault.recoveryRequest();
        assertEq(requestNonce, 0);
        assertEq(vault.configNonce(), 2);
    }

    function testRecoveryActivationInvalidatesPendingConfigAndClaim() public {
        bytes memory encoded = abi.encode(_config(91 days));
        vm.prank(owner);
        vault.proposeConfig(encoded);
        vm.warp(uint256(vault.lastSeen()) + 90 days);
        vault.requestClaim();

        vm.prank(guardianA);
        vault.requestRecovery();
        (uint64 nonce,,,,,) = vault.recoveryRequest();
        vm.prank(guardianB);
        vault.approveRecovery(nonce);
        (,, uint64 readyAt,,,) = vault.recoveryRequest();
        vm.warp(readyAt);
        vault.activateRecovery();

        assertEq(vault.owner(), recovery);
        (bytes32 pendingHash,,,) = vault.pendingConfig();
        (uint64 claimNonce,,,,) = vault.claimRequest();
        assertEq(pendingHash, bytes32(0));
        assertEq(claimNonce, 0);
        assertEq(vault.configNonce(), 2);
    }

    function testRecoveryDelayAndExpiryExactBoundaries() public {
        vm.prank(guardianA);
        vault.requestRecovery();
        (uint64 nonce,,,,,) = vault.recoveryRequest();
        vm.prank(guardianB);
        vault.approveRecovery(nonce);
        (,, uint64 readyAt, uint64 expiresAt,,) = vault.recoveryRequest();

        vm.warp(readyAt - 1);
        vm.expectRevert(IHeirloomVault.RecoveryNotReady.selector);
        vault.activateRecovery();
        vm.warp(expiresAt);
        vault.activateRecovery();
        assertEq(vault.owner(), recovery);
    }

    function testExpiredRecoveryCannotActivateAndCanBeCleared() public {
        vm.prank(guardianA);
        vault.requestRecovery();
        (uint64 nonce,,,,,) = vault.recoveryRequest();
        vm.prank(guardianB);
        vault.approveRecovery(nonce);
        (,,, uint64 expiresAt,,) = vault.recoveryRequest();

        vm.warp(uint256(expiresAt) + 1);
        vm.expectRevert(IHeirloomVault.RecoveryRequestExpired.selector);
        vault.activateRecovery();
        vault.clearExpiredRecovery();
        (uint64 clearedNonce,,,,,) = vault.recoveryRequest();
        assertEq(clearedNonce, 0);
        assertEq(vault.owner(), owner);
    }

    function testOwnerVetoCreatesLivenessAndDeletesRecovery() public {
        vm.prank(guardianA);
        vault.requestRecovery();
        uint64 oldNonce = vault.livenessNonce();
        vm.warp(block.timestamp + 1 days);

        vm.prank(owner);
        vault.vetoRecovery();

        assertEq(vault.livenessNonce(), oldNonce + 1);
        assertEq(vault.lastSeen(), block.timestamp);
        (uint64 requestNonce,,,,,) = vault.recoveryRequest();
        assertEq(requestNonce, 0);
    }

    function testInvalidSchedulesNeverDeploy() public {
        HeirloomTypes.VaultConfig memory invalid = _config(90 days);
        invalid.terminal.bps = 4999;
        vm.expectRevert(IHeirloomVault.InvalidConfiguration.selector);
        factory.createVault(owner, keccak256("bad-bps"), invalid);

        invalid = _config(90 days);
        invalid.terminal.fallbackAddress = invalid.beneficiaries[0].primary;
        vm.expectRevert(IHeirloomVault.InvalidConfiguration.selector);
        factory.createVault(owner, keccak256("duplicate"), invalid);
    }

    function testVaultCannotConfigureItselfAsDestinationOrRecoveryAuthority() public {
        HeirloomTypes.VaultConfig memory invalid = _config(91 days);
        invalid.beneficiaries[0].primary = address(vault);
        vm.prank(owner);
        vm.expectRevert(IHeirloomVault.InvalidConfiguration.selector);
        vault.proposeConfig(abi.encode(invalid));

        invalid = _config(91 days);
        invalid.terminal.fallbackAddress = address(vault);
        vm.prank(owner);
        vm.expectRevert(IHeirloomVault.InvalidConfiguration.selector);
        vault.proposeConfig(abi.encode(invalid));

        invalid = _config(91 days);
        invalid.recoveryAddress = address(vault);
        vm.prank(owner);
        vm.expectRevert(IHeirloomVault.InvalidConfiguration.selector);
        vault.proposeConfig(abi.encode(invalid));

        invalid = _config(91 days);
        invalid.guardians[0] = address(vault);
        vm.prank(owner);
        vm.expectRevert(IHeirloomVault.InvalidConfiguration.selector);
        vault.proposeConfig(abi.encode(invalid));
    }

    function testMaximumEightTotalBeneficiariesAcceptedAndNinthRejected() public {
        HeirloomTypes.VaultConfig memory maximum = _config(90 days);
        maximum.beneficiaries = new HeirloomTypes.Beneficiary[](7);
        for (uint256 i; i < 7; ++i) {
            maximum.beneficiaries[i] = HeirloomTypes.Beneficiary(
                makeAddr(string.concat("max-primary-", vm.toString(i))),
                makeAddr(string.concat("max-fallback-", vm.toString(i))),
                i == 6 ? 1000 : 500
            );
        }
        maximum.terminal.bps = 6000;
        address deployed = factory.createVault(owner, keccak256("maximum-beneficiaries"), maximum);
        assertEq(HeirloomVault(deployed).beneficiaryCount(), 7);

        maximum.beneficiaries = new HeirloomTypes.Beneficiary[](8);
        for (uint256 i; i < 8; ++i) {
            maximum.beneficiaries[i] = HeirloomTypes.Beneficiary(
                makeAddr(string.concat("too-many-primary-", vm.toString(i))),
                makeAddr(string.concat("too-many-fallback-", vm.toString(i))),
                500
            );
        }
        maximum.terminal.bps = 6000;
        vm.expectRevert(IHeirloomVault.InvalidConfiguration.selector);
        factory.createVault(owner, keccak256("too-many-beneficiaries"), maximum);
    }

    function testConfigDigestBindsVaultAndCurrentNonce() public {
        HeirloomVault other =
            HeirloomVault(factory.createVault(owner, keccak256("other"), _config(90 days)));
        bytes memory encoded = abi.encode(_config(91 days));
        bytes32 firstDigest = vault.proposalDigest(encoded);
        assertTrue(firstDigest != other.proposalDigest(encoded));

        vm.prank(owner);
        vault.proposeConfig(encoded);
        (,, uint64 eta,) = vault.pendingConfig();
        vm.warp(eta);
        vault.executeConfig(encoded);
        assertTrue(firstDigest != vault.proposalDigest(encoded));
    }

    function _config(
        uint64 inactivity
    ) internal returns (HeirloomTypes.VaultConfig memory config) {
        config.beneficiaries = new HeirloomTypes.Beneficiary[](1);
        config.beneficiaries[0] =
            HeirloomTypes.Beneficiary(makeAddr("primary"), makeAddr("fallback"), 4000);
        config.terminal = HeirloomTypes.Beneficiary(
            makeAddr("terminalPrimary"), makeAddr("terminalFallback"), 6000
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

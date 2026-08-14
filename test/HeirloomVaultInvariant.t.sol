// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { StdInvariant } from "forge-std/StdInvariant.sol";
import { Test } from "forge-std/Test.sol";

import { HeirloomFactory } from "../src/HeirloomFactory.sol";
import { HeirloomTypes } from "../src/HeirloomTypes.sol";
import { HeirloomVault } from "../src/HeirloomVault.sol";
import { MockUSDC } from "./mocks/MockUSDC.sol";

contract DistributionHandler is Test {
    HeirloomVault public immutable vault;
    MockUSDC public immutable usdc;

    constructor(
        HeirloomVault target,
        MockUSDC token
    ) {
        vault = target;
        usdc = token;
    }

    function pay(
        uint8 rawIndex
    ) external {
        uint8 index = uint8(bound(rawIndex, 0, vault.beneficiaryCount() - 1));
        vault.executePayout(index);
    }

    function rollover(
        uint8 rawIndex
    ) external {
        uint8 index = uint8(bound(rawIndex, 0, vault.beneficiaryCount() - 1));
        vault.rolloverPayout(index);
    }

    function enterFallbackPhase() external {
        if (block.timestamp < vault.fallbackAt()) vm.warp(vault.fallbackAt());
    }

    function enterRolloverPhase() external {
        if (block.timestamp < vault.rolloverAt()) vm.warp(vault.rolloverAt());
    }

    function enterTerminalFallbackPhase() external {
        uint64 fallbackTime = vault.terminalFallbackAt();
        if (fallbackTime != 0) vm.warp(fallbackTime);
    }

    function payTerminal() external {
        vault.executeTerminalPayout();
    }

    function addExcess(
        uint96 rawAmount
    ) external {
        uint256 amount = bound(uint256(rawAmount), 1, 1_000_000e6);
        usdc.mint(address(vault), amount);
    }

    function sweepExcess() external {
        vault.sweepExcess();
    }
}

contract HeirloomVaultInvariantTest is StdInvariant, Test {
    HeirloomVault internal vault;
    MockUSDC internal usdc;

    function setUp() public {
        address owner = makeAddr("owner");
        usdc = new MockUSDC();
        HeirloomFactory factory = new HeirloomFactory(usdc);
        vault = HeirloomVault(factory.createVault(owner, keccak256("invariant"), _config()));
        usdc.mint(address(vault), 1_000_003e6);

        vm.warp(uint256(vault.lastSeen()) + 90 days);
        vault.requestClaim();
        (,, uint64 executeAfter,,) = vault.claimRequest();
        vm.warp(executeAfter);
        vault.startDistribution();

        DistributionHandler handler = new DistributionHandler(vault, usdc);
        targetContract(address(handler));
    }

    function invariantSnapshotAccountingIsConserved() public view {
        if (vault.state() == HeirloomTypes.VaultState.Distributing) {
            assertEq(
                vault.totalNonTerminalPaid() + vault.snapshotRemaining(), vault.snapshotBalance()
            );
            assertGe(usdc.balanceOf(address(vault)), vault.snapshotRemaining());
        }
    }

    function invariantResolvedCountMatchesStatuses() public view {
        uint256 resolved;
        uint256 length = vault.beneficiaryCount();
        for (uint8 i; i < length; ++i) {
            if (vault.beneficiaryStatus(i) != HeirloomTypes.BeneficiaryStatus.Unresolved) {
                ++resolved;
            }
        }
        assertEq(vault.resolvedNonTerminalCount(), resolved);
    }

    function invariantTerminalNeverUnlocksEarly() public view {
        if (vault.terminalUnlockedAt() != 0) {
            assertEq(vault.resolvedNonTerminalCount(), vault.beneficiaryCount());
        }
    }

    function invariantSettlementIsTerminalAndComplete() public view {
        if (vault.state() == HeirloomTypes.VaultState.Settled) {
            assertEq(vault.snapshotRemaining(), 0);
            assertTrue(vault.terminalPaid());
            assertEq(vault.resolvedNonTerminalCount(), vault.beneficiaryCount());
        }
    }

    function _config() internal returns (HeirloomTypes.VaultConfig memory config) {
        config.beneficiaries = new HeirloomTypes.Beneficiary[](3);
        config.beneficiaries[0] =
            HeirloomTypes.Beneficiary(makeAddr("primaryA"), makeAddr("fallbackA"), 1111);
        config.beneficiaries[1] =
            HeirloomTypes.Beneficiary(makeAddr("primaryB"), makeAddr("fallbackB"), 2222);
        config.beneficiaries[2] =
            HeirloomTypes.Beneficiary(makeAddr("primaryC"), makeAddr("fallbackC"), 3333);
        config.terminal = HeirloomTypes.Beneficiary(
            makeAddr("terminalPrimary"), makeAddr("terminalFallback"), 3334
        );
        config.durations = HeirloomTypes.Durations(
            90 days, 7 days, 30 days, 30 days, 2 days, 30 days, 2 days, 30 days
        );
        config.guardians = new address[](3);
        config.guardians[0] = makeAddr("guardianA");
        config.guardians[1] = makeAddr("guardianB");
        config.guardians[2] = makeAddr("guardianC");
        config.guardianThreshold = 2;
        config.recoveryAddress = makeAddr("recovery");
    }
}

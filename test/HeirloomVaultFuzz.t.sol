// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { HeirloomFactory } from "../src/HeirloomFactory.sol";
import { HeirloomTypes } from "../src/HeirloomTypes.sol";
import { HeirloomVault } from "../src/HeirloomVault.sol";
import { MockUSDC } from "./mocks/MockUSDC.sol";

contract HeirloomVaultFuzzTest is Test {
    address internal owner = makeAddr("owner");
    address internal primaryA = makeAddr("primaryA");
    address internal fallbackA = makeAddr("fallbackA");
    address internal primaryB = makeAddr("primaryB");
    address internal fallbackB = makeAddr("fallbackB");
    address internal terminalPrimary = makeAddr("terminalPrimary");
    address internal terminalFallback = makeAddr("terminalFallback");
    address internal guardianA = makeAddr("guardianA");
    address internal guardianB = makeAddr("guardianB");
    address internal guardianC = makeAddr("guardianC");
    address internal recovery = makeAddr("recovery");

    function testFuzzConservesSnapshotAcrossAllResolutionPaths(
        uint96 rawBalance,
        bool payFirst,
        bool paySecond
    ) public {
        uint256 balance = bound(uint256(rawBalance), 1e6, 1_000_000_000_000e6);
        MockUSDC usdc = new MockUSDC();
        HeirloomFactory factory = new HeirloomFactory(usdc);
        HeirloomVault vault =
            HeirloomVault(factory.createVault(owner, keccak256(abi.encode(balance)), _config()));
        usdc.mint(address(vault), balance);

        vm.warp(uint256(vault.lastSeen()) + 90 days);
        vault.requestClaim();
        (,, uint64 executeAfter,,) = vault.claimRequest();
        vm.warp(executeAfter);
        vault.startDistribution();

        uint256 paid;
        uint256 rolled;
        if (payFirst) {
            paid += vault.entitlement(0);
            vault.executePayout(0);
        }
        if (paySecond) {
            paid += vault.entitlement(1);
            vault.executePayout(1);
        }

        vm.warp(vault.rolloverAt());
        if (!payFirst) {
            rolled += vault.entitlement(0);
            vault.rolloverPayout(0);
        }
        if (!paySecond) {
            rolled += vault.entitlement(1);
            vault.rolloverPayout(1);
        }

        uint256 terminalAmount = vault.snapshotRemaining();
        vault.executeTerminalPayout();

        assertEq(paid + terminalAmount, balance);
        assertEq(vault.totalNonTerminalPaid(), paid);
        assertEq(vault.totalRolledOver(), rolled);
        assertEq(usdc.balanceOf(address(vault)), 0);
    }

    function _config() internal view returns (HeirloomTypes.VaultConfig memory config) {
        config.beneficiaries = new HeirloomTypes.Beneficiary[](2);
        config.beneficiaries[0] = HeirloomTypes.Beneficiary(primaryA, fallbackA, 3333);
        config.beneficiaries[1] = HeirloomTypes.Beneficiary(primaryB, fallbackB, 3333);
        config.terminal = HeirloomTypes.Beneficiary(terminalPrimary, terminalFallback, 3334);
        config.durations = HeirloomTypes.Durations(
            90 days, 7 days, 30 days, 30 days, 2 days, 30 days, 2 days, 30 days
        );
        config.guardians = new address[](3);
        config.guardians[0] = guardianA;
        config.guardians[1] = guardianB;
        config.guardians[2] = guardianC;
        config.guardianThreshold = 2;
        config.recoveryAddress = recovery;
    }
}

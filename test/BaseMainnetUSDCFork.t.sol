// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { HeirloomFactory } from "../src/HeirloomFactory.sol";
import { HeirloomTypes } from "../src/HeirloomTypes.sol";
import { HeirloomVault } from "../src/HeirloomVault.sol";

interface IBaseUSDC is IERC20Metadata {
    function implementation() external view returns (address);
    function pauser() external view returns (address);
    function paused() external view returns (bool);
    function pause() external;
    function unpause() external;
    function blacklister() external view returns (address);
    function blacklist(
        address account
    ) external;
    function isBlacklisted(
        address account
    ) external view returns (bool);
}

contract BaseMainnetUSDCForkTest is Test {
    address internal constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address internal constant PINNED_IMPLEMENTATION = 0x2Ce6311ddAE708829bc0784C967b7d77D19FD779;
    uint256 internal constant PINNED_BLOCK = 49_965_293;
    bytes32 internal constant PINNED_PROXY_CODE_HASH =
        0xa6705a10bb756b5dea144591118be77d7af0c3eee3bf2dfe2583dcb0364fefab;
    bytes32 internal constant PINNED_IMPLEMENTATION_CODE_HASH =
        0x11b75a237997ab8328f65b2d5a55c10f0346d0a175741ed42ddf4f2c66b9e873;
    uint256 internal constant ONE_USDC = 1e6;
    uint256 internal constant DEPOSIT = 1000 * ONE_USDC;

    address internal owner = makeAddr("fork-owner");
    address internal outsider = makeAddr("fork-outsider");
    address internal recovery = makeAddr("fork-recovery");
    address internal primary = makeAddr("fork-primary");
    address internal fallbackAddress = makeAddr("fork-fallback");
    address internal terminalPrimary = makeAddr("fork-terminal-primary");
    address internal terminalFallback = makeAddr("fork-terminal-fallback");
    address internal guardianA = makeAddr("fork-guardian-a");
    address internal guardianB = makeAddr("fork-guardian-b");
    address internal guardianC = makeAddr("fork-guardian-c");

    string internal rpcUrl;

    function setUp() public {
        rpcUrl = vm.envOr("BASE_MAINNET_RPC_URL", string("https://mainnet.base.org"));
    }

    function testPinnedForkUSDCIdentityAndRuntime() public {
        vm.createSelectFork(rpcUrl, PINNED_BLOCK);

        IBaseUSDC usdc = IBaseUSDC(BASE_USDC);
        assertEq(block.chainid, 8453);
        assertEq(block.number, PINNED_BLOCK);
        assertEq(usdc.name(), "USD Coin");
        assertEq(usdc.symbol(), "USDC");
        assertEq(usdc.decimals(), 6);
        assertFalse(usdc.paused());
        assertEq(BASE_USDC.codehash, PINNED_PROXY_CODE_HASH);
        assertEq(usdc.implementation(), PINNED_IMPLEMENTATION);
        assertEq(PINNED_IMPLEMENTATION.codehash, PINNED_IMPLEMENTATION_CODE_HASH);
    }

    function testLatestForkUSDCIdentityMatchesPinnedRelease() public {
        vm.createSelectFork(rpcUrl);

        IBaseUSDC usdc = IBaseUSDC(BASE_USDC);
        assertEq(block.chainid, 8453);
        assertEq(usdc.decimals(), 6);
        assertEq(BASE_USDC.codehash, PINNED_PROXY_CODE_HASH);
        assertEq(usdc.implementation(), PINNED_IMPLEMENTATION);
        assertEq(PINNED_IMPLEMENTATION.codehash, PINNED_IMPLEMENTATION_CODE_HASH);
    }

    function testPinnedForkExactDepositWithdrawalAndDirectTransferLiveness() public {
        vm.createSelectFork(rpcUrl, PINNED_BLOCK);
        (IBaseUSDC usdc, HeirloomVault vault) = _deployFundedVault();

        uint64 beforeSeen = vault.lastSeen();
        uint64 beforeNonce = vault.livenessNonce();
        deal(BASE_USDC, outsider, ONE_USDC, true);
        vm.warp(block.timestamp + 1 days);
        vm.prank(outsider);
        assertTrue(usdc.transfer(address(vault), ONE_USDC));

        assertEq(vault.lastSeen(), beforeSeen);
        assertEq(vault.livenessNonce(), beforeNonce);
        assertEq(usdc.balanceOf(address(vault)), DEPOSIT + ONE_USDC);

        uint256 ownerBefore = usdc.balanceOf(owner);
        vm.prank(owner);
        vault.withdraw(ONE_USDC, owner);

        assertEq(usdc.balanceOf(owner), ownerBefore + ONE_USDC);
        assertEq(usdc.balanceOf(address(vault)), DEPOSIT);
        assertEq(vault.livenessNonce(), beforeNonce + 1);
    }

    function testPinnedForkPausedUSDCRevertsDepositAtomically() public {
        vm.createSelectFork(rpcUrl, PINNED_BLOCK);
        IBaseUSDC usdc = IBaseUSDC(BASE_USDC);
        HeirloomVault vault = _deployEmptyVault();
        deal(BASE_USDC, owner, DEPOSIT, true);
        vm.prank(owner);
        usdc.approve(address(vault), DEPOSIT);

        uint64 beforeSeen = vault.lastSeen();
        uint64 beforeNonce = vault.livenessNonce();
        vm.prank(usdc.pauser());
        usdc.pause();

        vm.prank(owner);
        vm.expectRevert();
        vault.deposit(DEPOSIT);

        assertEq(vault.lastSeen(), beforeSeen);
        assertEq(vault.livenessNonce(), beforeNonce);
        assertEq(usdc.balanceOf(address(vault)), 0);
    }

    function testPinnedForkBlacklistedVaultRevertsDepositAtomically() public {
        vm.createSelectFork(rpcUrl, PINNED_BLOCK);
        IBaseUSDC usdc = IBaseUSDC(BASE_USDC);
        HeirloomVault vault = _deployEmptyVault();
        deal(BASE_USDC, owner, DEPOSIT, true);
        vm.prank(owner);
        usdc.approve(address(vault), DEPOSIT);

        uint64 beforeSeen = vault.lastSeen();
        uint64 beforeNonce = vault.livenessNonce();
        vm.prank(usdc.blacklister());
        usdc.blacklist(address(vault));

        vm.prank(owner);
        vm.expectRevert();
        vault.deposit(DEPOSIT);

        assertEq(vault.lastSeen(), beforeSeen);
        assertEq(vault.livenessNonce(), beforeNonce);
        assertEq(usdc.balanceOf(address(vault)), 0);
        assertEq(usdc.balanceOf(owner), DEPOSIT);
    }

    function testPinnedForkBlacklistedDestinationCannotPartiallyResolve() public {
        vm.createSelectFork(rpcUrl, PINNED_BLOCK);
        (IBaseUSDC usdc, HeirloomVault vault) = _deployFundedVault();
        _startDistribution(vault);

        vm.prank(usdc.blacklister());
        usdc.blacklist(primary);
        assertTrue(usdc.isBlacklisted(primary));

        uint256 beforeBalance = usdc.balanceOf(address(vault));
        uint256 beforeRemaining = vault.snapshotRemaining();
        vm.expectRevert();
        vault.executePayout(0);

        assertEq(
            uint8(vault.beneficiaryStatus(0)), uint8(HeirloomTypes.BeneficiaryStatus.Unresolved)
        );
        assertEq(usdc.balanceOf(address(vault)), beforeBalance);
        assertEq(vault.snapshotRemaining(), beforeRemaining);
        assertEq(vault.totalNonTerminalPaid(), 0);
    }

    function testPinnedForkBlacklistedFallbackCannotPartiallyResolve() public {
        vm.createSelectFork(rpcUrl, PINNED_BLOCK);
        (IBaseUSDC usdc, HeirloomVault vault) = _deployFundedVault();
        _startDistribution(vault);
        vm.warp(vault.fallbackAt());

        vm.prank(usdc.blacklister());
        usdc.blacklist(fallbackAddress);
        uint256 beforeBalance = usdc.balanceOf(address(vault));
        uint256 beforeRemaining = vault.snapshotRemaining();

        vm.expectRevert();
        vault.executePayout(0);

        assertEq(
            uint8(vault.beneficiaryStatus(0)), uint8(HeirloomTypes.BeneficiaryStatus.Unresolved)
        );
        assertEq(usdc.balanceOf(address(vault)), beforeBalance);
        assertEq(vault.snapshotRemaining(), beforeRemaining);
        assertEq(vault.totalNonTerminalPaid(), 0);
    }

    function testPinnedForkBlacklistedTerminalCannotPartiallySettle() public {
        vm.createSelectFork(rpcUrl, PINNED_BLOCK);
        (IBaseUSDC usdc, HeirloomVault vault) = _deployFundedVault();
        _startDistribution(vault);
        vault.executePayout(0);

        vm.prank(usdc.blacklister());
        usdc.blacklist(terminalPrimary);
        uint256 beforeBalance = usdc.balanceOf(address(vault));
        uint256 beforeRemaining = vault.snapshotRemaining();

        vm.expectRevert();
        vault.executeTerminalPayout();

        assertFalse(vault.terminalPaid());
        assertEq(uint8(vault.state()), uint8(HeirloomTypes.VaultState.Distributing));
        assertEq(usdc.balanceOf(address(vault)), beforeBalance);
        assertEq(vault.snapshotRemaining(), beforeRemaining);
    }

    function testPinnedForkCompletesDestinationLockedLifecycle() public {
        vm.createSelectFork(rpcUrl, PINNED_BLOCK);
        (IBaseUSDC usdc, HeirloomVault vault) = _deployFundedVault();
        _startDistribution(vault);

        vault.executePayout(0);
        vault.executeTerminalPayout();

        assertEq(usdc.balanceOf(primary), 400 * ONE_USDC);
        assertEq(usdc.balanceOf(terminalPrimary), 600 * ONE_USDC);
        assertEq(usdc.balanceOf(address(vault)), 0);
        assertEq(uint8(vault.state()), uint8(HeirloomTypes.VaultState.Settled));
        assertEq(vault.settledTerminalDestination(), terminalPrimary);
    }

    function _deployEmptyVault() internal returns (HeirloomVault vault) {
        HeirloomFactory factory = new HeirloomFactory(IERC20(BASE_USDC));
        vault = HeirloomVault(
            factory.createVault(owner, keccak256("base-mainnet-fork"), _defaultConfig())
        );
    }

    function _deployFundedVault() internal returns (IBaseUSDC usdc, HeirloomVault vault) {
        usdc = IBaseUSDC(BASE_USDC);
        vault = _deployEmptyVault();
        deal(BASE_USDC, owner, DEPOSIT, true);
        vm.startPrank(owner);
        usdc.approve(address(vault), DEPOSIT);
        vault.deposit(DEPOSIT);
        vm.stopPrank();
        assertEq(usdc.balanceOf(address(vault)), DEPOSIT);
    }

    function _startDistribution(
        HeirloomVault vault
    ) internal {
        vm.warp(uint256(vault.lastSeen()) + vault.MIN_INACTIVITY());
        vm.prank(outsider);
        vault.requestClaim();
        (,, uint64 executeAfter,,) = vault.claimRequest();
        vm.warp(executeAfter);
        vm.prank(outsider);
        vault.startDistribution();
    }

    function _defaultConfig() internal view returns (HeirloomTypes.VaultConfig memory config) {
        config.beneficiaries = new HeirloomTypes.Beneficiary[](1);
        config.beneficiaries[0] = HeirloomTypes.Beneficiary({
            primary: primary, fallbackAddress: fallbackAddress, bps: 4000
        });
        config.terminal = HeirloomTypes.Beneficiary({
            primary: terminalPrimary, fallbackAddress: terminalFallback, bps: 6000
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

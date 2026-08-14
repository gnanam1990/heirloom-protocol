// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Script, console2 } from "forge-std/Script.sol";

import { HeirloomFactory } from "../src/HeirloomFactory.sol";

contract DeployBaseSepolia is Script {
    uint256 public constant EXPECTED_CHAIN_ID = 84_532;
    address public constant OFFICIAL_USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    error WrongChain(uint256 actual, uint256 expected);
    error InvalidDeployer();
    error AssetCodeMissing();

    function run() external returns (HeirloomFactory factory) {
        if (block.chainid != EXPECTED_CHAIN_ID) {
            revert WrongChain(block.chainid, EXPECTED_CHAIN_ID);
        }
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        if (deployer == address(0)) revert InvalidDeployer();
        if (OFFICIAL_USDC.code.length == 0) revert AssetCodeMissing();

        vm.startBroadcast(deployer);
        factory = new HeirloomFactory(IERC20(OFFICIAL_USDC));
        vm.stopBroadcast();

        console2.log("Heirloom factory", address(factory));
        console2.log("Heirloom implementation", factory.implementation());
        console2.log("Official Base Sepolia USDC", OFFICIAL_USDC);
        console2.logBytes32(factory.VERSION_ID());
    }
}

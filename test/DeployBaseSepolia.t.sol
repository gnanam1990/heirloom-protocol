// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { DeployBaseSepolia } from "../script/DeployBaseSepolia.s.sol";
import { HeirloomFactory } from "../src/HeirloomFactory.sol";

contract DeployBaseSepoliaTest is Test {
    DeployBaseSepolia internal deployment;

    function setUp() public {
        deployment = new DeployBaseSepolia();
        vm.setEnv("DEPLOYER_ADDRESS", vm.toString(makeAddr("deployer")));
    }

    function testRejectsWrongChainBeforeBroadcast() public {
        vm.chainId(1);
        vm.expectRevert(abi.encodeWithSelector(DeployBaseSepolia.WrongChain.selector, 1, 84_532));
        deployment.run();
    }

    function testRejectsMissingOfficialAssetCode() public {
        vm.chainId(84_532);
        vm.expectRevert(DeployBaseSepolia.AssetCodeMissing.selector);
        deployment.run();
    }

    function testDeploysPinnedFactoryOnBaseSepolia() public {
        vm.chainId(84_532);
        vm.etch(deployment.OFFICIAL_USDC(), hex"00");

        HeirloomFactory factory = deployment.run();

        assertEq(block.chainid, factory.deploymentChainId());
        assertEq(address(factory.asset()), deployment.OFFICIAL_USDC());
        assertEq(factory.VERSION_ID(), keccak256("HEIRLOOM_V3_1_R1"));
        assertGt(factory.implementation().code.length, 0);
    }
}

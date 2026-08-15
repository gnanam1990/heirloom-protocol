// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { DeployBaseMainnet } from "../script/DeployBaseMainnet.s.sol";
import { HeirloomFactory } from "../src/HeirloomFactory.sol";

contract DeployBaseMainnetTest is Test {
    DeployBaseMainnet internal deployment;

    function setUp() public {
        deployment = new DeployBaseMainnet();
        vm.setEnv("HEIRLOOM_ENFORCE_RELEASE_GATES", "false");
    }

    function testRejectsWrongChainBeforeBroadcast() public {
        address expectedDeployer = deployment.EXPECTED_DEPLOYER();
        vm.chainId(1);
        vm.expectRevert(abi.encodeWithSelector(DeployBaseMainnet.WrongChain.selector, 1, 8453));
        deployment.deploy(expectedDeployer);
    }

    function testRejectsMissingOfficialAssetCode() public {
        address expectedDeployer = deployment.EXPECTED_DEPLOYER();
        vm.chainId(8453);
        vm.expectRevert(DeployBaseMainnet.AssetCodeMissing.selector);
        deployment.deploy(expectedDeployer);
    }

    function testRejectsUnpinnedDeployer() public {
        address actual = makeAddr("wrong-mainnet-deployer");
        vm.expectRevert(
            abi.encodeWithSelector(
                DeployBaseMainnet.InvalidDeployer.selector, actual, deployment.EXPECTED_DEPLOYER()
            )
        );
        deployment.validateDeploymentIdentity(actual, 0);
    }

    function testRejectsUnexpectedDeployerNonce() public {
        address expectedDeployer = deployment.EXPECTED_DEPLOYER();
        _prepareMainnet();
        vm.setNonce(expectedDeployer, 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                DeployBaseMainnet.DeployerNonceMismatch.selector,
                uint64(1),
                deployment.EXPECTED_DEPLOYER_NONCE()
            )
        );
        deployment.deploy(expectedDeployer);
    }

    function testReleaseAuthorizationFailsClosedWithoutAuditApproval() public {
        vm.expectRevert(DeployBaseMainnet.ExternalAuditNotApproved.selector);
        deployment.validateReleaseAuthorization(false, false, bytes32(0), bytes32(0));
    }

    function testReleaseAuthorizationRequiresReleaseOwnerApproval() public {
        vm.expectRevert(DeployBaseMainnet.MainnetReleaseNotApproved.selector);
        deployment.validateReleaseAuthorization(true, false, bytes32(0), bytes32(0));
    }

    function testReleaseAuthorizationRequiresExactAuditedCommit() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                DeployBaseMainnet.AuditedCommitMismatch.selector,
                bytes32(0),
                deployment.AUDIT_CANDIDATE_COMMIT()
            )
        );
        deployment.validateReleaseAuthorization(true, true, bytes32(0), bytes32(0));
    }

    function testReleaseAuthorizationRequiresAuditReportHash() public {
        bytes32 auditedCommit = deployment.AUDIT_CANDIDATE_COMMIT();
        vm.expectRevert(DeployBaseMainnet.AuditReportHashMissing.selector);
        deployment.validateReleaseAuthorization(true, true, auditedCommit, bytes32(0));
    }

    function testDryRunDeploysPinnedFactoryWithoutReleaseAuthorization() public {
        _prepareMainnet();

        HeirloomFactory factory = deployment.deploy(deployment.EXPECTED_DEPLOYER());

        assertEq(address(factory), deployment.EXPECTED_FACTORY());
        assertEq(address(factory).codehash, deployment.EXPECTED_FACTORY_RUNTIME_CODE_HASH());
        assertEq(factory.deploymentChainId(), 8453);
        assertEq(address(factory.asset()), deployment.OFFICIAL_USDC());
        assertEq(factory.VERSION_ID(), deployment.EXPECTED_VERSION_ID());
        assertEq(
            factory.implementation().codehash,
            deployment.EXPECTED_IMPLEMENTATION_RUNTIME_CODE_HASH()
        );
    }

    function testReleaseAuthorizationAcceptsCompleteAuthorization() public view {
        deployment.validateReleaseAuthorization(
            true, true, deployment.AUDIT_CANDIDATE_COMMIT(), keccak256("final-report")
        );
    }

    function testProposalAuthorizationFailsClosedWithoutApproval() public {
        vm.expectRevert(DeployBaseMainnet.ProposalDeploymentNotApproved.selector);
        deployment.validateProposalAuthorization(false, false, bytes32(0));
    }

    function testProposalAuthorizationRequiresUnauditedRiskAcceptance() public {
        vm.expectRevert(DeployBaseMainnet.UnauditedRiskNotAccepted.selector);
        deployment.validateProposalAuthorization(true, false, bytes32(0));
    }

    function testProposalAuthorizationRequiresExactCandidateCommit() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                DeployBaseMainnet.ProposalCommitMismatch.selector,
                bytes32(0),
                deployment.AUDIT_CANDIDATE_COMMIT()
            )
        );
        deployment.validateProposalAuthorization(true, true, bytes32(0));
    }

    function testProposalAuthorizationAcceptsExplicitUnauditedRelease() public view {
        deployment.validateProposalAuthorization(true, true, deployment.AUDIT_CANDIDATE_COMMIT());
    }

    function _prepareMainnet() internal {
        vm.chainId(8453);
        vm.etch(deployment.OFFICIAL_USDC(), hex"00");
    }
}

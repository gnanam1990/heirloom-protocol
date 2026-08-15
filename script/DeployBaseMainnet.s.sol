// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Script, console2 } from "forge-std/Script.sol";
import { VmSafe } from "forge-std/Vm.sol";

import { HeirloomFactory } from "../src/HeirloomFactory.sol";

/// @notice Fail-closed Base mainnet deployment path for the audited v3.1-R1 candidate.
/// @dev Dry-runs are allowed before audit completion. Broadcast/resume always requires the
///      external-audit and release-owner environment gates documented in the mainnet runbook.
contract DeployBaseMainnet is Script {
    uint256 public constant EXPECTED_CHAIN_ID = 8453;
    address public constant EXPECTED_DEPLOYER = 0xE8405844a45C209895afE2e49be6aA2C6C6202a6;
    uint64 public constant EXPECTED_DEPLOYER_NONCE = 0;
    address public constant OFFICIAL_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public constant EXPECTED_FACTORY = 0x524A95082dAD59fd8bf18FA27F89E3f55202eEcf;
    bytes32 public constant EXPECTED_VERSION_ID = keccak256("HEIRLOOM_V3_1_R1");
    bytes32 public constant AUDIT_CANDIDATE_COMMIT =
        0x7ea6617625615e41469e153bc19f020eeb692d4a000000000000000000000000;
    bytes32 public constant EXPECTED_IMPLEMENTATION_RUNTIME_CODE_HASH =
        0x48bfce26a7b15d9f7ceaa248db541a41a5afdc84ca9ac27252ff8d6dc2770ab9;
    bytes32 public constant EXPECTED_FACTORY_RUNTIME_CODE_HASH =
        0xbce0f26e2d6fc4eb3cfea3184113b7cdd01ae123b775ca6ac16938a6b18ec547;

    error WrongChain(uint256 actual, uint256 expected);
    error InvalidDeployer(address actual, address expected);
    error DeployerNonceMismatch(uint64 actual, uint64 expected);
    error AssetCodeMissing();
    error ExternalAuditNotApproved();
    error MainnetReleaseNotApproved();
    error AuditedCommitMismatch(bytes32 actual, bytes32 expected);
    error AuditReportHashMissing();
    error DeploymentInvariantFailed();
    error FactoryAddressMismatch(address actual, address expected);
    error FactoryRuntimeHashMismatch(bytes32 actual, bytes32 expected);
    error ImplementationRuntimeHashMismatch(bytes32 actual, bytes32 expected);

    function run() external returns (HeirloomFactory factory) {
        return deploy(vm.envAddress("DEPLOYER_ADDRESS"));
    }

    /// @dev Public for deterministic tests. Broadcast and resume contexts still enforce every
    ///      release gate, and the supplied address must equal EXPECTED_DEPLOYER.
    function deploy(
        address deployer
    ) public returns (HeirloomFactory factory) {
        if (block.chainid != EXPECTED_CHAIN_ID) {
            revert WrongChain(block.chainid, EXPECTED_CHAIN_ID);
        }

        uint64 deployerNonce = vm.getNonce(deployer);
        validateDeploymentIdentity(deployer, deployerNonce);
        if (OFFICIAL_USDC.code.length == 0) revert AssetCodeMissing();

        bool enforceReleaseGate = _mustEnforceReleaseGate();
        bytes32 auditedCommit;
        bytes32 auditReportHash;
        if (enforceReleaseGate) {
            auditedCommit = vm.envOr("HEIRLOOM_AUDITED_COMMIT", bytes32(0));
            auditReportHash = vm.envOr("HEIRLOOM_EXTERNAL_AUDIT_REPORT_HASH", bytes32(0));
            validateReleaseAuthorization(
                vm.envOr("HEIRLOOM_EXTERNAL_AUDIT_APPROVED", false),
                vm.envOr("HEIRLOOM_MAINNET_RELEASE_APPROVED", false),
                auditedCommit,
                auditReportHash
            );
        }

        vm.startBroadcast(deployer);
        factory = new HeirloomFactory(IERC20(OFFICIAL_USDC));
        vm.stopBroadcast();

        if (address(factory) != EXPECTED_FACTORY) {
            revert FactoryAddressMismatch(address(factory), EXPECTED_FACTORY);
        }
        address implementation = factory.implementation();
        if (
            address(factory.asset()) != OFFICIAL_USDC
                || factory.deploymentChainId() != EXPECTED_CHAIN_ID
                || factory.VERSION_ID() != EXPECTED_VERSION_ID || implementation.code.length == 0
        ) {
            revert DeploymentInvariantFailed();
        }

        bytes32 factoryRuntimeHash = address(factory).codehash;
        if (factoryRuntimeHash != EXPECTED_FACTORY_RUNTIME_CODE_HASH) {
            revert FactoryRuntimeHashMismatch(
                factoryRuntimeHash, EXPECTED_FACTORY_RUNTIME_CODE_HASH
            );
        }
        bytes32 implementationRuntimeHash = implementation.codehash;
        if (implementationRuntimeHash != EXPECTED_IMPLEMENTATION_RUNTIME_CODE_HASH) {
            revert ImplementationRuntimeHashMismatch(
                implementationRuntimeHash, EXPECTED_IMPLEMENTATION_RUNTIME_CODE_HASH
            );
        }

        console2.log("Heirloom Base mainnet factory", address(factory));
        console2.log("Heirloom implementation", implementation);
        console2.log("Pinned deployer", deployer);
        console2.log("Pinned deployer nonce", deployerNonce);
        console2.log("Official Base USDC", OFFICIAL_USDC);
        console2.log("Release gates enforced", enforceReleaseGate);
        console2.logBytes32(factory.VERSION_ID());
        if (enforceReleaseGate) {
            console2.logBytes32(auditedCommit);
            console2.logBytes32(auditReportHash);
        }
    }

    function validateDeploymentIdentity(
        address deployer,
        uint64 deployerNonce
    ) public pure {
        if (deployer != EXPECTED_DEPLOYER) revert InvalidDeployer(deployer, EXPECTED_DEPLOYER);
        if (deployerNonce != EXPECTED_DEPLOYER_NONCE) {
            revert DeployerNonceMismatch(deployerNonce, EXPECTED_DEPLOYER_NONCE);
        }
    }

    function validateReleaseAuthorization(
        bool externalAuditApproved,
        bool mainnetReleaseApproved,
        bytes32 auditedCommit,
        bytes32 auditReportHash
    ) public pure {
        if (!externalAuditApproved) revert ExternalAuditNotApproved();
        if (!mainnetReleaseApproved) revert MainnetReleaseNotApproved();
        if (auditedCommit != AUDIT_CANDIDATE_COMMIT) {
            revert AuditedCommitMismatch(auditedCommit, AUDIT_CANDIDATE_COMMIT);
        }
        if (auditReportHash == bytes32(0)) revert AuditReportHashMissing();
    }

    function _mustEnforceReleaseGate() internal view returns (bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptBroadcast)
            || vm.isContext(VmSafe.ForgeContext.ScriptResume)
            || vm.envOr("HEIRLOOM_ENFORCE_RELEASE_GATES", false);
    }
}

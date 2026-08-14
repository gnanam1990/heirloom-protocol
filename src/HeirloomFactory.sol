// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

import { HeirloomTypes } from "./HeirloomTypes.sol";
import { HeirloomVault } from "./HeirloomVault.sol";

contract HeirloomFactory {
    bytes32 public constant VERSION_ID = keccak256("HEIRLOOM_V3_1");

    IERC20 public immutable asset;
    address public immutable implementation;
    uint256 public immutable deploymentChainId;

    mapping(address vault => bool official) public isVault;
    address[] private _vaults;

    event VaultCreated(
        address indexed vault,
        address indexed owner,
        address indexed asset,
        bytes32 versionId,
        bytes32 configHash,
        bytes32 creationSalt,
        bytes32 runtimeCodeHash
    );

    error ZeroAddress();
    error WrongChain();

    constructor(
        IERC20 supportedAsset
    ) {
        if (address(supportedAsset) == address(0)) revert ZeroAddress();
        asset = supportedAsset;
        implementation = address(new HeirloomVault());
        deploymentChainId = block.chainid;
    }

    function createVault(
        address owner,
        bytes32 userSalt,
        HeirloomTypes.VaultConfig calldata config
    ) external returns (address vault) {
        if (block.chainid != deploymentChainId) revert WrongChain();
        if (owner == address(0)) revert ZeroAddress();

        bytes32 configHash = keccak256(abi.encode(config));
        bytes32 creationSalt = keccak256(abi.encode(owner, userSalt, configHash));
        vault = Clones.cloneDeterministic(implementation, creationSalt);
        HeirloomVault(vault).initialize(owner, asset, VERSION_ID, config);

        isVault[vault] = true;
        _vaults.push(vault);
        emit VaultCreated(
            vault, owner, address(asset), VERSION_ID, configHash, creationSalt, vault.codehash
        );
    }

    function predictVaultAddress(
        address owner,
        bytes32 userSalt,
        HeirloomTypes.VaultConfig calldata config
    ) external view returns (address predicted) {
        bytes32 configHash = keccak256(abi.encode(config));
        bytes32 creationSalt = keccak256(abi.encode(owner, userSalt, configHash));
        predicted = Clones.predictDeterministicAddress(implementation, creationSalt, address(this));
    }

    function vaultCount() external view returns (uint256) {
        return _vaults.length;
    }

    function vaultAt(
        uint256 index
    ) external view returns (address) {
        return _vaults[index];
    }

    function vaultRuntimeCodeHash(
        address vault
    ) external view returns (bytes32) {
        if (!isVault[vault]) revert ZeroAddress();
        return vault.codehash;
    }
}

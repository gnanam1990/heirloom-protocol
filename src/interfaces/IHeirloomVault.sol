// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { HeirloomTypes } from "../HeirloomTypes.sol";

interface IHeirloomVault {
    error AlreadyInitialized();
    event OwnerActivity(
        address indexed owner,
        HeirloomTypes.ActivityType indexed actionType,
        uint64 lastSeen,
        uint64 livenessNonce
    );
    event ClaimRequested(
        address indexed caller,
        uint64 indexed requestNonce,
        uint64 requestedAt,
        uint64 executeAfter,
        uint64 livenessNonce,
        uint64 configNonce
    );
    event ClaimCancelled(
        HeirloomTypes.ClaimCancelReason indexed reason,
        address indexed actor,
        uint64 newLastSeen,
        uint64 livenessNonce
    );
    event DistributionStarted(
        address indexed caller,
        uint256 snapshotBalance,
        uint64 startedAt,
        uint64 fallbackAt,
        uint64 rolloverAt
    );
    event ZeroEntitlementResolved(uint8 indexed beneficiaryIndex);
    event BeneficiaryPaid(
        uint8 indexed beneficiaryIndex,
        address indexed destination,
        HeirloomTypes.DestinationPhase phase,
        uint256 amount,
        address caller
    );
    event EntitlementRolledOver(uint8 indexed beneficiaryIndex, uint256 amount, address caller);
    event TerminalUnlocked(uint64 unlockedAt, uint64 terminalFallbackAt, uint256 snapshotRemaining);
    event TerminalPaid(
        address indexed destination,
        HeirloomTypes.DestinationPhase phase,
        uint256 amount,
        address caller
    );
    event Settled(
        uint256 snapshotBalance,
        uint256 totalNonTerminalPaid,
        uint256 totalRolledOver,
        uint256 terminalAmount,
        address terminalDestination
    );
    event ExcessSwept(address indexed destination, uint256 amount, address caller);

    event ConfigProposed(
        bytes32 indexed configHash, uint64 proposalNonce, uint64 eta, uint64 expiresAt
    );
    event ConfigReplaced(bytes32 indexed oldHash, bytes32 indexed newHash, uint64 proposalNonce);
    event ConfigVetoed(bytes32 indexed configHash, address indexed owner, uint64 livenessNonce);
    event ConfigExecuted(bytes32 indexed configHash, address indexed executor, uint64 configNonce);
    event ConfigExpired(bytes32 indexed configHash, address indexed clearer);
    event ConfigInvalidated(bytes32 indexed configHash, uint64 configNonce);

    event RecoveryRequested(
        uint64 indexed requestNonce, address indexed guardian, address recoveryAddress
    );
    event RecoveryApproved(
        uint64 indexed requestNonce, address indexed guardian, uint8 approvalCount
    );
    event RecoveryThresholdReached(uint64 indexed requestNonce, uint64 readyAt, uint64 expiresAt);
    event RecoveryVetoed(uint64 indexed requestNonce, address indexed owner, uint64 livenessNonce);
    event RecoveryInvalidated(
        uint64 indexed requestNonce, HeirloomTypes.RecoveryInvalidationReason indexed reason
    );
    event RecoveryActivated(
        address indexed oldOwner,
        address indexed newOwner,
        uint64 recoveryNonce,
        uint64 livenessNonce,
        uint64 configNonce
    );
    event RecoveryExpired(uint64 indexed requestNonce, address indexed clearer);

    error Unauthorized();
    error InvalidState();
    error NotMatured();
    error ChallengeNotElapsed();
    error StaleClaimRequest();
    error ClaimAlreadyPending();
    error InvalidBeneficiaryIndex();
    error EntitlementAlreadyResolved();
    error WrongDestinationPhase();
    error TerminalLocked();
    error TerminalAlreadyPaid();
    error InvalidConfiguration();
    error InvalidDuration();
    error NoPendingConfig();
    error ConfigNotReady();
    error ConfigProposalExpired();
    error ConfigHashMismatch();
    error RecoveryBlocksConfig();
    error RecoveryAlreadyPending();
    error NoPendingRecovery();
    error RecoveryNotReady();
    error RecoveryRequestExpired();
    error GuardianAlreadyApproved();
    error InvalidRecoveryNonce();
    error AccountingDeficit();
    error UnexpectedTokenDelta();
    error ZeroAddress();
    error ZeroAmount();

    function initialize(
        address initialOwner,
        IERC20 supportedAsset,
        bytes32 vaultVersionId,
        HeirloomTypes.VaultConfig calldata initialConfig
    ) external;

    function heartbeat() external;
    function deposit(
        uint256 amount
    ) external;
    function withdraw(
        uint256 amount,
        address to
    ) external;

    function requestClaim() external;
    function cancelClaimWithHeartbeat() external;
    function startDistribution() external;

    function executePayout(
        uint8 beneficiaryIndex
    ) external;
    function rolloverPayout(
        uint8 beneficiaryIndex
    ) external;
    function executeTerminalPayout() external;
    function sweepExcess() external;

    function proposeConfig(
        bytes calldata encodedConfig
    ) external;
    function vetoConfig() external;
    function executeConfig(
        bytes calldata encodedConfig
    ) external;
    function clearExpiredConfig() external;

    function requestRecovery() external;
    function approveRecovery(
        uint64 requestNonce
    ) external;
    function vetoRecovery() external;
    function activateRecovery() external;
    function clearExpiredRecovery() external;
}

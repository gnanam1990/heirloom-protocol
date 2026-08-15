// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { HeirloomTypes } from "./HeirloomTypes.sol";
import { IHeirloomVault } from "./interfaces/IHeirloomVault.sol";

contract HeirloomVault is IHeirloomVault, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint16 public constant TOTAL_BPS = 10_000;
    uint8 public constant MAX_TOTAL_BENEFICIARIES = 8;
    uint8 public constant MIN_GUARDIANS = 3;
    uint8 public constant MAX_GUARDIANS = 7;

    uint64 public constant MIN_INACTIVITY = 90 days;
    uint64 public constant MAX_INACTIVITY = 5 * 365 days;
    uint64 public constant MIN_CHALLENGE = 7 days;
    uint64 public constant MAX_CHALLENGE = 60 days;
    uint64 public constant MIN_PAYOUT_WINDOW = 30 days;
    uint64 public constant MAX_PAYOUT_WINDOW = 180 days;
    uint64 public constant MIN_CONTROL_DELAY = 2 days;
    uint64 public constant MAX_CONTROL_DELAY = 30 days;
    uint64 public constant FIXED_EXECUTION_WINDOW = 30 days;

    address public factory;
    IERC20 public asset;
    bytes32 public versionId;

    address public owner;
    HeirloomTypes.VaultState public vaultState;
    uint64 public lastSeen;
    uint64 public livenessNonce;
    uint64 public configNonce;
    uint64 public recoveryNonce;

    HeirloomTypes.Durations public durations;
    address public recoveryAddress;
    uint8 public guardianThreshold;
    bytes32 public currentConfigHash;

    HeirloomTypes.ClaimRequest public claimRequest;
    HeirloomTypes.PendingConfig public pendingConfig;
    HeirloomTypes.RecoveryRequest public recoveryRequest;

    uint64 public distributionStartedAt;
    uint64 public fallbackAt;
    uint64 public rolloverAt;
    uint64 public terminalUnlockedAt;
    uint64 public terminalFallbackAt;
    uint256 public snapshotBalance;
    uint256 public snapshotRemaining;
    uint256 public totalNonTerminalPaid;
    uint256 public totalRolledOver;
    uint8 public resolvedNonTerminalCount;
    bool public terminalPaid;
    address public settledTerminalDestination;

    HeirloomTypes.Beneficiary[] private _beneficiaries;
    HeirloomTypes.Beneficiary private _terminal;
    HeirloomTypes.BeneficiaryStatus[] private _beneficiaryStatus;
    address[] private _guardians;
    mapping(address guardian => bool configured) public isGuardian;
    mapping(uint64 requestNonce => mapping(address guardian => bool approved)) public
        recoveryApproved;

    uint64 private _claimNonceCounter;
    uint64 private _proposalNonceCounter;
    uint64 private _recoveryRequestNonceCounter;
    bool private _initialized;

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyGuardian() {
        if (!isGuardian[msg.sender]) revert Unauthorized();
        _;
    }

    constructor() {
        _initialized = true;
    }

    function initialize(
        address initialOwner,
        IERC20 supportedAsset,
        bytes32 vaultVersionId,
        HeirloomTypes.VaultConfig calldata initialConfig
    ) external {
        if (_initialized) revert AlreadyInitialized();
        if (initialOwner == address(0) || address(supportedAsset) == address(0)) {
            revert ZeroAddress();
        }

        _initialized = true;
        factory = msg.sender;
        owner = initialOwner;
        asset = supportedAsset;
        versionId = vaultVersionId;
        vaultState = HeirloomTypes.VaultState.Active;
        lastSeen = uint64(block.timestamp);
        livenessNonce = 1;
        configNonce = 1;

        _validateConfig(initialConfig, initialOwner);
        _applyConfig(initialConfig);
    }

    // -------------------------------------------------------------------------
    // Owner liveness and funds
    // -------------------------------------------------------------------------

    function heartbeat() external onlyOwner {
        _touchOwner(HeirloomTypes.ActivityType.Heartbeat);
    }

    function deposit(
        uint256 amount
    ) external onlyOwner nonReentrant {
        if (amount == 0) revert ZeroAmount();
        _touchOwner(HeirloomTypes.ActivityType.Deposit);

        uint256 beforeBalance = asset.balanceOf(address(this));
        asset.safeTransferFrom(msg.sender, address(this), amount);
        uint256 afterBalance = asset.balanceOf(address(this));
        if (afterBalance < beforeBalance || afterBalance - beforeBalance != amount) {
            revert UnexpectedTokenDelta();
        }
    }

    function withdraw(
        uint256 amount,
        address to
    ) external onlyOwner nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (to == address(0)) revert ZeroAddress();
        _touchOwner(HeirloomTypes.ActivityType.Withdrawal);
        _transferExact(to, amount);
    }

    // -------------------------------------------------------------------------
    // Claim lifecycle
    // -------------------------------------------------------------------------

    function requestClaim() external {
        if (vaultState != HeirloomTypes.VaultState.Active) revert InvalidState();
        if (block.timestamp < uint256(lastSeen) + durations.inactivityPeriod) revert NotMatured();
        if (claimRequest.nonce != 0) revert ClaimAlreadyPending();

        uint64 nowTs = uint64(block.timestamp);
        uint64 requestNonce = ++_claimNonceCounter;
        uint64 executeAfter = nowTs + durations.challengePeriod;
        claimRequest = HeirloomTypes.ClaimRequest({
            nonce: requestNonce,
            requestedAt: nowTs,
            executeAfter: executeAfter,
            livenessNonce: livenessNonce,
            configNonce: configNonce
        });
        vaultState = HeirloomTypes.VaultState.ClaimRequested;

        emit ClaimRequested(
            msg.sender, requestNonce, nowTs, executeAfter, livenessNonce, configNonce
        );
    }

    function cancelClaimWithHeartbeat() external onlyOwner {
        if (vaultState != HeirloomTypes.VaultState.ClaimRequested) revert InvalidState();
        _touchOwner(HeirloomTypes.ActivityType.ClaimCancelled);
    }

    function startDistribution() external nonReentrant {
        if (vaultState != HeirloomTypes.VaultState.ClaimRequested) revert InvalidState();

        HeirloomTypes.ClaimRequest memory request = claimRequest;
        if (block.timestamp < request.executeAfter) revert ChallengeNotElapsed();
        if (request.livenessNonce != livenessNonce || request.configNonce != configNonce) {
            revert StaleClaimRequest();
        }

        bytes32 invalidatedConfigHash = pendingConfig.configHash;
        if (invalidatedConfigHash != bytes32(0)) {
            delete pendingConfig;
            emit ConfigInvalidated(invalidatedConfigHash, configNonce);
        }

        if (recoveryRequest.nonce != 0) {
            uint64 recoveryRequestNonce = recoveryRequest.nonce;
            delete recoveryRequest;
            emit RecoveryInvalidated(
                recoveryRequestNonce, HeirloomTypes.RecoveryInvalidationReason.DistributionStarted
            );
        }

        delete claimRequest;
        vaultState = HeirloomTypes.VaultState.Distributing;

        uint64 nowTs = uint64(block.timestamp);
        distributionStartedAt = nowTs;
        fallbackAt = nowTs + durations.primaryWindow;
        rolloverAt = fallbackAt + durations.fallbackWindow;
        snapshotBalance = asset.balanceOf(address(this));
        snapshotRemaining = snapshotBalance;

        delete _beneficiaryStatus;
        uint256 length = _beneficiaries.length;
        for (uint256 i; i < length; ++i) {
            uint256 amount = _entitlement(uint8(i));
            if (amount == 0) {
                _beneficiaryStatus.push(HeirloomTypes.BeneficiaryStatus.Paid);
                ++resolvedNonTerminalCount;
                emit ZeroEntitlementResolved(uint8(i));
            } else {
                _beneficiaryStatus.push(HeirloomTypes.BeneficiaryStatus.Unresolved);
            }
        }

        emit DistributionStarted(msg.sender, snapshotBalance, nowTs, fallbackAt, rolloverAt);

        if (resolvedNonTerminalCount == length) _unlockTerminal();
    }

    // -------------------------------------------------------------------------
    // Distribution
    // -------------------------------------------------------------------------

    function executePayout(
        uint8 beneficiaryIndex
    ) external nonReentrant {
        _requireDistributingAndUnresolved(beneficiaryIndex);

        HeirloomTypes.DestinationPhase phase = destinationPhase(beneficiaryIndex);
        address destination;
        if (phase == HeirloomTypes.DestinationPhase.PrimaryOnly) {
            destination = _beneficiaries[beneficiaryIndex].primary;
        } else if (phase == HeirloomTypes.DestinationPhase.FallbackOnly) {
            destination = _beneficiaries[beneficiaryIndex].fallbackAddress;
        } else {
            revert WrongDestinationPhase();
        }

        _requireNoAccountingDeficit();
        uint256 amount = _entitlement(beneficiaryIndex);

        _beneficiaryStatus[beneficiaryIndex] = HeirloomTypes.BeneficiaryStatus.Paid;
        ++resolvedNonTerminalCount;
        snapshotRemaining -= amount;
        totalNonTerminalPaid += amount;

        _transferExact(destination, amount);
        emit BeneficiaryPaid(beneficiaryIndex, destination, phase, amount, msg.sender);

        if (resolvedNonTerminalCount == _beneficiaries.length) _unlockTerminal();
    }

    function rolloverPayout(
        uint8 beneficiaryIndex
    ) external {
        _requireDistributingAndUnresolved(beneficiaryIndex);
        if (destinationPhase(beneficiaryIndex) != HeirloomTypes.DestinationPhase.RolloverOnly) {
            revert WrongDestinationPhase();
        }

        uint256 amount = _entitlement(beneficiaryIndex);
        _beneficiaryStatus[beneficiaryIndex] = HeirloomTypes.BeneficiaryStatus.RolledOver;
        ++resolvedNonTerminalCount;
        totalRolledOver += amount;

        emit EntitlementRolledOver(beneficiaryIndex, amount, msg.sender);
        if (resolvedNonTerminalCount == _beneficiaries.length) _unlockTerminal();
    }

    function executeTerminalPayout() external nonReentrant {
        if (vaultState != HeirloomTypes.VaultState.Distributing) revert InvalidState();
        if (terminalPaid) revert TerminalAlreadyPaid();
        if (terminalUnlockedAt == 0) revert TerminalLocked();

        _requireNoAccountingDeficit();
        uint256 amount = snapshotRemaining;
        if (amount == 0) revert ZeroAmount();

        HeirloomTypes.DestinationPhase phase = terminalDestinationPhase();
        address destination;
        if (phase == HeirloomTypes.DestinationPhase.TerminalPrimaryOnly) {
            destination = _terminal.primary;
        } else if (phase == HeirloomTypes.DestinationPhase.TerminalFallbackOnly) {
            destination = _terminal.fallbackAddress;
        } else {
            revert TerminalLocked();
        }

        snapshotRemaining = 0;
        terminalPaid = true;
        settledTerminalDestination = destination;
        vaultState = HeirloomTypes.VaultState.Settled;

        _transferExact(destination, amount);
        emit TerminalPaid(destination, phase, amount, msg.sender);
        emit Settled(snapshotBalance, totalNonTerminalPaid, totalRolledOver, amount, destination);
    }

    function sweepExcess() external nonReentrant {
        if (vaultState != HeirloomTypes.VaultState.Settled) revert InvalidState();
        uint256 amount = asset.balanceOf(address(this));
        if (amount == 0) revert ZeroAmount();

        address destination = settledTerminalDestination;
        _transferExact(destination, amount);
        emit ExcessSwept(destination, amount, msg.sender);
    }

    // -------------------------------------------------------------------------
    // Configuration
    // -------------------------------------------------------------------------

    function proposeConfig(
        bytes calldata encodedConfig
    ) external onlyOwner {
        if (vaultState != HeirloomTypes.VaultState.Active) revert InvalidState();
        HeirloomTypes.VaultConfig memory proposed =
            abi.decode(encodedConfig, (HeirloomTypes.VaultConfig));
        _validateConfig(proposed, owner);

        _touchOwner(HeirloomTypes.ActivityType.ConfigProposed);

        bytes32 newHash = _proposalDigest(encodedConfig);
        bytes32 oldHash = pendingConfig.configHash;
        uint64 proposalNonce = ++_proposalNonceCounter;
        uint64 eta = uint64(block.timestamp) + durations.configDelay;
        uint64 expiresAt = eta + durations.configExecutionWindow;
        pendingConfig = HeirloomTypes.PendingConfig({
            configHash: newHash, proposalNonce: proposalNonce, eta: eta, expiresAt: expiresAt
        });

        if (oldHash != bytes32(0)) emit ConfigReplaced(oldHash, newHash, proposalNonce);
        emit ConfigProposed(newHash, proposalNonce, eta, expiresAt);
    }

    function vetoConfig() external onlyOwner {
        if (vaultState != HeirloomTypes.VaultState.Active) revert InvalidState();
        bytes32 proposalHash = pendingConfig.configHash;
        if (proposalHash == bytes32(0)) revert NoPendingConfig();

        _touchOwner(HeirloomTypes.ActivityType.ConfigVetoed);
        delete pendingConfig;
        emit ConfigVetoed(proposalHash, msg.sender, livenessNonce);
    }

    function executeConfig(
        bytes calldata encodedConfig
    ) external {
        if (vaultState != HeirloomTypes.VaultState.Active) revert InvalidState();
        HeirloomTypes.PendingConfig memory pending = pendingConfig;
        if (pending.configHash == bytes32(0)) revert NoPendingConfig();
        if (block.timestamp < pending.eta) revert ConfigNotReady();
        if (block.timestamp > pending.expiresAt) revert ConfigProposalExpired();
        if (_proposalDigest(encodedConfig) != pending.configHash) revert ConfigHashMismatch();

        if (recoveryRequest.thresholdReached) revert RecoveryBlocksConfig();

        HeirloomTypes.VaultConfig memory proposed =
            abi.decode(encodedConfig, (HeirloomTypes.VaultConfig));
        _validateConfig(proposed, owner);

        if (recoveryRequest.nonce != 0) {
            uint64 requestNonce = recoveryRequest.nonce;
            delete recoveryRequest;
            emit RecoveryInvalidated(
                requestNonce, HeirloomTypes.RecoveryInvalidationReason.ConfigExecuted
            );
        }

        delete pendingConfig;
        ++configNonce;
        _applyConfig(proposed);
        emit ConfigExecuted(pending.configHash, msg.sender, configNonce);
    }

    function clearExpiredConfig() external {
        if (vaultState != HeirloomTypes.VaultState.Active) revert InvalidState();
        bytes32 proposalHash = pendingConfig.configHash;
        if (proposalHash == bytes32(0)) revert NoPendingConfig();
        if (block.timestamp <= pendingConfig.expiresAt) revert ConfigNotReady();
        delete pendingConfig;
        emit ConfigExpired(proposalHash, msg.sender);
    }

    // -------------------------------------------------------------------------
    // Guardian recovery
    // -------------------------------------------------------------------------

    function requestRecovery() external onlyGuardian {
        _requireRecoverableState();
        if (recoveryAddress == owner) revert InvalidConfiguration();
        if (recoveryRequest.nonce != 0) revert RecoveryAlreadyPending();

        uint64 nowTs = uint64(block.timestamp);
        uint64 requestNonce = ++_recoveryRequestNonceCounter;
        uint64 expiresAt = nowTs + durations.recoveryExecutionWindow;
        recoveryRequest = HeirloomTypes.RecoveryRequest({
            nonce: requestNonce,
            requestedAt: nowTs,
            readyAt: 0,
            expiresAt: expiresAt,
            approvals: 1,
            thresholdReached: false
        });
        recoveryApproved[requestNonce][msg.sender] = true;

        emit RecoveryRequested(requestNonce, msg.sender, recoveryAddress);
        emit RecoveryApproved(requestNonce, msg.sender, 1);
    }

    function approveRecovery(
        uint64 requestNonce
    ) external onlyGuardian {
        _requireRecoverableState();
        HeirloomTypes.RecoveryRequest storage request = recoveryRequest;
        if (request.nonce == 0) revert NoPendingRecovery();
        if (request.nonce != requestNonce) revert InvalidRecoveryNonce();
        if (block.timestamp > request.expiresAt) revert RecoveryRequestExpired();
        if (request.thresholdReached) revert RecoveryNotReady();
        if (recoveryApproved[requestNonce][msg.sender]) revert GuardianAlreadyApproved();

        recoveryApproved[requestNonce][msg.sender] = true;
        ++request.approvals;
        emit RecoveryApproved(requestNonce, msg.sender, request.approvals);

        if (request.approvals >= guardianThreshold) {
            request.thresholdReached = true;
            request.readyAt = uint64(block.timestamp) + durations.recoveryDelay;
            request.expiresAt = request.readyAt + durations.recoveryExecutionWindow;
            emit RecoveryThresholdReached(requestNonce, request.readyAt, request.expiresAt);
        }
    }

    function vetoRecovery() external onlyOwner {
        _requireRecoverableState();
        if (recoveryRequest.nonce == 0) revert NoPendingRecovery();
        _touchOwner(HeirloomTypes.ActivityType.RecoveryVetoed);
    }

    function activateRecovery() external {
        _requireRecoverableState();
        HeirloomTypes.RecoveryRequest memory request = recoveryRequest;
        if (request.nonce == 0) revert NoPendingRecovery();
        if (!request.thresholdReached || block.timestamp < request.readyAt) {
            revert RecoveryNotReady();
        }
        if (block.timestamp > request.expiresAt) revert RecoveryRequestExpired();

        address oldOwner = owner;
        address newOwner = recoveryAddress;
        bytes32 invalidatedConfigHash = pendingConfig.configHash;

        if (vaultState == HeirloomTypes.VaultState.ClaimRequested) {
            delete claimRequest;
            emit ClaimCancelled(
                HeirloomTypes.ClaimCancelReason.RecoveryActivated,
                msg.sender,
                uint64(block.timestamp),
                livenessNonce + 1
            );
        }
        if (invalidatedConfigHash != bytes32(0)) {
            delete pendingConfig;
            emit ConfigInvalidated(invalidatedConfigHash, configNonce + 1);
        }

        delete recoveryRequest;
        owner = newOwner;
        vaultState = HeirloomTypes.VaultState.Active;
        lastSeen = uint64(block.timestamp);
        ++livenessNonce;
        ++configNonce;
        ++recoveryNonce;

        emit OwnerActivity(
            newOwner, HeirloomTypes.ActivityType.RecoveryActivated, lastSeen, livenessNonce
        );
        emit RecoveryActivated(oldOwner, newOwner, recoveryNonce, livenessNonce, configNonce);
    }

    function clearExpiredRecovery() external {
        HeirloomTypes.RecoveryRequest memory request = recoveryRequest;
        if (request.nonce == 0) revert NoPendingRecovery();
        if (block.timestamp <= request.expiresAt) revert RecoveryNotReady();
        delete recoveryRequest;
        emit RecoveryExpired(request.nonce, msg.sender);
    }

    // -------------------------------------------------------------------------
    // Views
    // -------------------------------------------------------------------------

    function state() external view returns (HeirloomTypes.VaultState) {
        return vaultState;
    }

    function claimable() external view returns (bool) {
        return vaultState == HeirloomTypes.VaultState.Active
            && block.timestamp >= uint256(lastSeen) + durations.inactivityPeriod;
    }

    function beneficiaryCount() external view returns (uint256) {
        return _beneficiaries.length;
    }

    function beneficiary(
        uint8 index
    ) external view returns (HeirloomTypes.Beneficiary memory) {
        if (index >= _beneficiaries.length) revert InvalidBeneficiaryIndex();
        return _beneficiaries[index];
    }

    function terminalBeneficiary() external view returns (HeirloomTypes.Beneficiary memory) {
        return _terminal;
    }

    function guardianCount() external view returns (uint256) {
        return _guardians.length;
    }

    function guardian(
        uint8 index
    ) external view returns (address) {
        if (index >= _guardians.length) revert InvalidBeneficiaryIndex();
        return _guardians[index];
    }

    function beneficiaryStatus(
        uint8 index
    ) external view returns (HeirloomTypes.BeneficiaryStatus) {
        if (index >= _beneficiaryStatus.length) revert InvalidBeneficiaryIndex();
        return _beneficiaryStatus[index];
    }

    function entitlement(
        uint8 beneficiaryIndex
    ) external view returns (uint256) {
        if (beneficiaryIndex >= _beneficiaries.length) revert InvalidBeneficiaryIndex();
        if (vaultState < HeirloomTypes.VaultState.Distributing) return 0;
        return _entitlement(beneficiaryIndex);
    }

    function destinationPhase(
        uint8 beneficiaryIndex
    ) public view returns (HeirloomTypes.DestinationPhase) {
        if (beneficiaryIndex >= _beneficiaries.length) revert InvalidBeneficiaryIndex();
        if (vaultState == HeirloomTypes.VaultState.Settled) {
            return HeirloomTypes.DestinationPhase.Settled;
        }
        if (vaultState != HeirloomTypes.VaultState.Distributing) {
            return HeirloomTypes.DestinationPhase.Unavailable;
        }
        if (_beneficiaryStatus[beneficiaryIndex] != HeirloomTypes.BeneficiaryStatus.Unresolved) {
            return HeirloomTypes.DestinationPhase.Unavailable;
        }
        if (block.timestamp < fallbackAt) return HeirloomTypes.DestinationPhase.PrimaryOnly;
        if (block.timestamp < rolloverAt) return HeirloomTypes.DestinationPhase.FallbackOnly;
        return HeirloomTypes.DestinationPhase.RolloverOnly;
    }

    function terminalDestinationPhase() public view returns (HeirloomTypes.DestinationPhase) {
        if (vaultState == HeirloomTypes.VaultState.Settled) {
            return HeirloomTypes.DestinationPhase.Settled;
        }
        if (vaultState != HeirloomTypes.VaultState.Distributing) {
            return HeirloomTypes.DestinationPhase.Unavailable;
        }
        if (terminalUnlockedAt == 0) return HeirloomTypes.DestinationPhase.TerminalLocked;
        if (block.timestamp < terminalFallbackAt) {
            return HeirloomTypes.DestinationPhase.TerminalPrimaryOnly;
        }
        return HeirloomTypes.DestinationPhase.TerminalFallbackOnly;
    }

    function excessBalance() external view returns (uint256) {
        uint256 actualBalance = asset.balanceOf(address(this));
        if (vaultState == HeirloomTypes.VaultState.Settled) return actualBalance;
        if (vaultState != HeirloomTypes.VaultState.Distributing) return 0;
        if (actualBalance <= snapshotRemaining) return 0;
        return actualBalance - snapshotRemaining;
    }

    function proposalDigest(
        bytes calldata encodedConfig
    ) external view returns (bytes32) {
        return _proposalDigest(encodedConfig);
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    function _touchOwner(
        HeirloomTypes.ActivityType actionType
    ) internal {
        if (
            vaultState != HeirloomTypes.VaultState.Active
                && vaultState != HeirloomTypes.VaultState.ClaimRequested
        ) revert InvalidState();

        uint64 newLivenessNonce = livenessNonce + 1;

        if (recoveryRequest.nonce != 0) {
            uint64 requestNonce = recoveryRequest.nonce;
            delete recoveryRequest;
            emit RecoveryVetoed(requestNonce, owner, newLivenessNonce);
            emit RecoveryInvalidated(
                requestNonce, HeirloomTypes.RecoveryInvalidationReason.OwnerActivity
            );
        }

        if (vaultState == HeirloomTypes.VaultState.ClaimRequested) {
            delete claimRequest;
            vaultState = HeirloomTypes.VaultState.Active;
            emit ClaimCancelled(
                HeirloomTypes.ClaimCancelReason.OwnerActivity,
                msg.sender,
                uint64(block.timestamp),
                newLivenessNonce
            );
        }

        lastSeen = uint64(block.timestamp);
        livenessNonce = newLivenessNonce;
        emit OwnerActivity(owner, actionType, lastSeen, livenessNonce);
    }

    function _unlockTerminal() internal {
        terminalUnlockedAt = uint64(block.timestamp);
        terminalFallbackAt = terminalUnlockedAt + durations.primaryWindow;
        emit TerminalUnlocked(terminalUnlockedAt, terminalFallbackAt, snapshotRemaining);

        if (snapshotRemaining == 0) {
            terminalPaid = true;
            settledTerminalDestination = _terminal.primary;
            vaultState = HeirloomTypes.VaultState.Settled;
            emit TerminalPaid(
                _terminal.primary, HeirloomTypes.DestinationPhase.TerminalPrimaryOnly, 0, msg.sender
            );
            emit Settled(
                snapshotBalance, totalNonTerminalPaid, totalRolledOver, 0, _terminal.primary
            );
        }
    }

    function _requireDistributingAndUnresolved(
        uint8 beneficiaryIndex
    ) internal view {
        if (vaultState != HeirloomTypes.VaultState.Distributing) revert InvalidState();
        if (beneficiaryIndex >= _beneficiaries.length) revert InvalidBeneficiaryIndex();
        if (_beneficiaryStatus[beneficiaryIndex] != HeirloomTypes.BeneficiaryStatus.Unresolved) {
            revert EntitlementAlreadyResolved();
        }
    }

    function _requireRecoverableState() internal view {
        if (
            vaultState != HeirloomTypes.VaultState.Active
                && vaultState != HeirloomTypes.VaultState.ClaimRequested
        ) revert InvalidState();
    }

    function _requireNoAccountingDeficit() internal view {
        if (asset.balanceOf(address(this)) < snapshotRemaining) revert AccountingDeficit();
    }

    function _entitlement(
        uint8 beneficiaryIndex
    ) internal view returns (uint256) {
        return Math.mulDiv(snapshotBalance, _beneficiaries[beneficiaryIndex].bps, TOTAL_BPS);
    }

    function _transferExact(
        address to,
        uint256 amount
    ) internal {
        uint256 beforeBalance = asset.balanceOf(address(this));
        asset.safeTransfer(to, amount);
        uint256 afterBalance = asset.balanceOf(address(this));
        if (afterBalance > beforeBalance || beforeBalance - afterBalance != amount) {
            revert UnexpectedTokenDelta();
        }
    }

    function _proposalDigest(
        bytes calldata encodedConfig
    ) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                block.chainid, address(this), versionId, configNonce, keccak256(encodedConfig)
            )
        );
    }

    function _applyConfig(
        HeirloomTypes.VaultConfig memory config
    ) internal {
        for (uint256 i; i < _guardians.length; ++i) {
            isGuardian[_guardians[i]] = false;
        }
        delete _guardians;
        delete _beneficiaries;

        for (uint256 i; i < config.beneficiaries.length; ++i) {
            _beneficiaries.push(config.beneficiaries[i]);
        }
        _terminal = config.terminal;
        durations = config.durations;
        recoveryAddress = config.recoveryAddress;
        guardianThreshold = config.guardianThreshold;

        for (uint256 i; i < config.guardians.length; ++i) {
            address guardianAddress = config.guardians[i];
            _guardians.push(guardianAddress);
            isGuardian[guardianAddress] = true;
        }

        currentConfigHash = keccak256(abi.encode(config));
    }

    function _validateConfig(
        HeirloomTypes.VaultConfig memory config,
        address currentOwner
    ) internal view {
        uint256 nonTerminalCount = config.beneficiaries.length;
        if (nonTerminalCount == 0 || nonTerminalCount + 1 > MAX_TOTAL_BENEFICIARIES) {
            revert InvalidConfiguration();
        }

        _validateDurations(config.durations);

        uint256 destinationCount = (nonTerminalCount + 1) * 2;
        address[] memory destinations = new address[](destinationCount);
        uint256 destinationCursor;
        uint256 totalBps;

        for (uint256 i; i < nonTerminalCount; ++i) {
            HeirloomTypes.Beneficiary memory item = config.beneficiaries[i];
            _validateBeneficiary(item);
            totalBps += item.bps;
            destinations[destinationCursor++] = item.primary;
            destinations[destinationCursor++] = item.fallbackAddress;
        }

        _validateBeneficiary(config.terminal);
        totalBps += config.terminal.bps;
        destinations[destinationCursor++] = config.terminal.primary;
        destinations[destinationCursor] = config.terminal.fallbackAddress;
        if (totalBps != TOTAL_BPS) revert InvalidConfiguration();

        for (uint256 i; i < destinations.length; ++i) {
            for (uint256 j = i + 1; j < destinations.length; ++j) {
                if (destinations[i] == destinations[j]) revert InvalidConfiguration();
            }
        }

        uint256 guardianLength = config.guardians.length;
        if (guardianLength < MIN_GUARDIANS || guardianLength > MAX_GUARDIANS) {
            revert InvalidConfiguration();
        }
        if (config.guardianThreshold < 2 || config.guardianThreshold > guardianLength) {
            revert InvalidConfiguration();
        }
        if (
            config.recoveryAddress == address(0) || config.recoveryAddress == currentOwner
                || config.recoveryAddress == address(this)
        ) {
            revert InvalidConfiguration();
        }

        for (uint256 i; i < guardianLength; ++i) {
            address guardianAddress = config.guardians[i];
            if (
                guardianAddress == address(0) || guardianAddress == currentOwner
                    || guardianAddress == config.recoveryAddress || guardianAddress == address(this)
            ) revert InvalidConfiguration();
            for (uint256 j = i + 1; j < guardianLength; ++j) {
                if (guardianAddress == config.guardians[j]) revert InvalidConfiguration();
            }
        }
    }

    function _validateBeneficiary(
        HeirloomTypes.Beneficiary memory item
    ) internal view {
        if (
            item.primary == address(0) || item.fallbackAddress == address(0)
                || item.primary == item.fallbackAddress || item.primary == address(this)
                || item.fallbackAddress == address(this) || item.bps == 0
        ) revert InvalidConfiguration();
    }

    function _validateDurations(
        HeirloomTypes.Durations memory value
    ) internal pure {
        if (value.inactivityPeriod < MIN_INACTIVITY || value.inactivityPeriod > MAX_INACTIVITY) {
            revert InvalidDuration();
        }
        if (value.challengePeriod < MIN_CHALLENGE || value.challengePeriod > MAX_CHALLENGE) {
            revert InvalidDuration();
        }
        if (
            value.primaryWindow < MIN_PAYOUT_WINDOW || value.primaryWindow > MAX_PAYOUT_WINDOW
                || value.fallbackWindow < MIN_PAYOUT_WINDOW
                || value.fallbackWindow > MAX_PAYOUT_WINDOW
        ) revert InvalidDuration();
        if (
            value.configDelay < MIN_CONTROL_DELAY || value.configDelay > MAX_CONTROL_DELAY
                || value.recoveryDelay < MIN_CONTROL_DELAY
                || value.recoveryDelay > MAX_CONTROL_DELAY
        ) revert InvalidDuration();
        if (
            value.configExecutionWindow != FIXED_EXECUTION_WINDOW
                || value.recoveryExecutionWindow != FIXED_EXECUTION_WINDOW
        ) revert InvalidDuration();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

library HeirloomTypes {
    enum VaultState {
        Active,
        ClaimRequested,
        Distributing,
        Settled
    }

    enum BeneficiaryStatus {
        Unresolved,
        Paid,
        RolledOver
    }

    enum DestinationPhase {
        Unavailable,
        PrimaryOnly,
        FallbackOnly,
        RolloverOnly,
        TerminalLocked,
        TerminalPrimaryOnly,
        TerminalFallbackOnly,
        Settled
    }

    enum ActivityType {
        Heartbeat,
        Deposit,
        Withdrawal,
        ConfigProposed,
        ConfigVetoed,
        RecoveryVetoed,
        ClaimCancelled,
        RecoveryActivated
    }

    enum ClaimCancelReason {
        OwnerActivity,
        RecoveryActivated
    }

    enum RecoveryInvalidationReason {
        OwnerActivity,
        ConfigExecuted,
        DistributionStarted
    }

    struct Beneficiary {
        address primary;
        address fallbackAddress;
        uint16 bps;
    }

    struct Durations {
        uint64 inactivityPeriod;
        uint64 challengePeriod;
        uint64 primaryWindow;
        uint64 fallbackWindow;
        uint64 configDelay;
        uint64 configExecutionWindow;
        uint64 recoveryDelay;
        uint64 recoveryExecutionWindow;
    }

    struct VaultConfig {
        Beneficiary[] beneficiaries;
        Beneficiary terminal;
        Durations durations;
        address[] guardians;
        uint8 guardianThreshold;
        address recoveryAddress;
    }

    struct ClaimRequest {
        uint64 nonce;
        uint64 requestedAt;
        uint64 executeAfter;
        uint64 livenessNonce;
        uint64 configNonce;
    }

    struct PendingConfig {
        bytes32 configHash;
        uint64 proposalNonce;
        uint64 eta;
        uint64 expiresAt;
    }

    struct RecoveryRequest {
        uint64 nonce;
        uint64 requestedAt;
        uint64 readyAt;
        uint64 expiresAt;
        uint8 approvals;
        bool thresholdReached;
    }
}

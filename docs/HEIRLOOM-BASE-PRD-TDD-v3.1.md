# Heirloom - PRD + TDD v3.1

**A non-custodial asset-continuity vault for Base**

**Status:** Stage 0A candidate for sign-off<br>
**Target:** Base Sepolia, then Base mainnet after independent audit and remediation<br>
**Date:** 14 August 2026<br>
**Supersedes:** v3, v2 and v1

> v3.1 is the corrected post-audit protocol specification. It removes recipient-failure
> detection, makes payout destinations exclusively time-derived, prevents permissionless
> actions from manufacturing owner liveness, pays the terminal beneficiary last, binds
> claim requests to a liveness epoch, and fully specifies guardian recovery.

> Nothing has been deployed. This document is the candidate implementation source of truth.
> Stage 1 may begin only after D1-D40 and I1-I16 are accepted without contradiction.

---

## Executive decision

**Proceed, with conditions satisfied at specification level.**

Heirloom is not a death oracle and does not detect whether a beneficiary has lost a key. It is
an immutable Base vault that converts prolonged owner inactivity into a deterministic,
challengeable and permissionlessly executable destination schedule.

The protocol's central security property is:

> Anyone may pay gas to advance an eligible action. No permissionless caller gains the ability
> to choose the payout amount, destination, entitlement, timing phase or settlement order.

### The four v3 blockers and their v3.1 resolution

| Blocker | v3.1 resolution |
|---|---|
| P0-1: permissionless config execution could reset `lastSeen` | Only a fresh authorization attributable to the current owner may create liveness. Config execution never updates `lastSeen`, even when the owner is the executor. |
| P0-2: transfer failure was treated as proof of recipient failure | Removed. ERC-20 transfer success says nothing about key availability. Fallback eligibility is determined only by timestamp and status. |
| P0-3: primary and fallback were simultaneously callable | Removed. Exactly one destination phase is valid at a time and the contract derives it. |
| P0-4: terminal could be paid before later rollovers | Removed. Terminal is locked until all non-terminal entitlements are Paid or RolledOver, then paid once. |

---

# Part I - Product Requirements

## 1. Problem

Self-custodied assets have no native continuity process when an owner stops participating. A
key can be lost, an owner can be incapacitated, or an account can simply become inactive. The
chain observes none of those facts. It only observes valid transactions and time.

Existing approaches fail in different ways:

| Approach | Failure |
|---|---|
| Share the seed phrase | Gives present-day withdrawal power to the recipient. |
| Family multisig | Requires every participant to maintain keys and operational competence for years. |
| Custodial continuity provider | Reintroduces custody, solvency and intervention risk. |
| Off-chain dead-man switch | Places a service and usually a signing key in the correctness path. |
| Do nothing | Leaves the asset permanently dependent on one key. |

Heirloom provides a narrower primitive:

> If the owner stops creating authenticated liveness for long enough, anyone may start a
> challenge. If the owner still does not return, anyone may execute the owner's precommitted
> share distribution without gaining payout authority.

## 2. Product category

Launch as **asset continuity**, not automatic legal inheritance.

- Silence is not proof of death.
- Distribution may occur while the owner is alive.
- The protocol does not determine identity, capacity, mortality, legal title or tax treatment.
- Conventional estate documents may reference the vault, but the vault does not replace them.

Recommended public language:

> A non-custodial digital-asset continuity vault with explicit check-ins, a public challenge
> process and fixed payout authority.

## 3. Users and jobs

| User | Job |
|---|---|
| Owner | Keep control while active and precommit what happens after prolonged inactivity. |
| Beneficiary | Receive a configured share without needing gas or submitting the payout transaction. |
| Guardian | Activate only the recovery identity already chosen by the owner. |
| Permissionless executor | Advance a mature claim or payout without gaining economic discretion. |
| Observer or adviser | Verify configuration, deadlines, version and distribution evidence on-chain. |

Operator-treasury continuity remains a secondary research use case and does not ship as a V1
duration preset.

## 4. Product principles

1. **Destination lock:** caller identity never determines where vault value goes.
2. **Fresh owner intent:** only current-owner authorization creates liveness.
3. **Time, not diagnosis:** the contract uses timestamps; it does not infer death or key loss.
4. **Challenge before irreversibility:** `requestClaim()` moves no value.
5. **Immutable distribution snapshot:** entitlements do not change after distribution starts.
6. **Terminal last:** final routing happens only after every non-terminal share is resolved.
7. **No service in correctness:** indexers, reminders, paymasters and relayers are optional.
8. **Small asset-control kernel:** one immutable vault and one explicitly supported asset.
9. **Environmental honesty:** USDC issuer controls and Base execution behavior are external.
10. **Evidence over promises:** every security claim must map to an invariant and a test.

## 5. V1 success criteria

V1 succeeds when a user can:

1. Create a source-verified immutable vault from the official versioned factory.
2. Configure one to seven non-terminal beneficiaries and exactly one terminal beneficiary.
3. Fund the vault with Base USDC.
4. Create fresh liveness through an explicit owner-authorized action.
5. Understand the inactivity, challenge, primary, fallback and rollover deadlines before funding.
6. Recover ownership through a delayed, threshold-guardian activation to a precommitted address.
7. Observe a complete Base Sepolia lifecycle from Active to Settled.
8. Reproduce the destination-lock and conservation evidence independently.

## 6. Scope

### MUST ship in V1

- Base USDC only.
- Full immutable per-vault deployment from a versioned factory.
- Four states: Active, ClaimRequested, Distributing and Settled.
- Explicit owner heartbeat and owner-authenticated activity.
- Claim request, challenge and irreversible distribution start.
- Snapshot-share accounting with exactly 10,000 basis points.
- Maximum eight entries including one terminal beneficiary.
- Time-derived PrimaryOnly, FallbackOnly and RolloverOnly phases.
- Terminal-last settlement.
- Post-snapshot supported-token excess accounting and permissionless sweep after settlement.
- Delayed configuration with proposal expiry and permissionless execution.
- Threshold guardian recovery to a precommitted recovery address.
- Source verification, bytecode version evidence and Base Sepolia lifecycle evidence.
- Prominent product limits and deadline confirmation.

### SHOULD ship

- Notifications and escalation reminders.
- Sponsored owner-authorized heartbeats.
- Sponsored permissionless claim and payout calls.
- Public read-only evidence page.
- Direct compatibility with owner smart accounts through ordinary contract calls.

### Deferred

- Passkey beneficiary onboarding.
- Additional audited assets.
- Smart-account modules that observe activity routed through the account.
- Separate operator-treasury product profile.

### Explicitly out of V1

| Cut | Reason |
|---|---|
| Fixed absolute entitlements | Ordinary owner withdrawals can make a fixed schedule insolvent. |
| One-step irreversible claim | Exposes a returning owner to a final transaction-ordering race without challenge. |
| Failure-detected fallback | ERC-20 transfers cannot prove key availability or recipient capability. |
| Caller-selected payout route | Violates destination lock. |
| Arbitrary ERC-20s or multiple assets | Token semantics and cross-asset accounting exceed the validated model. |
| Automated heartbeat | Proves service uptime rather than owner control. |
| Custom relayed vault signatures | Adds EIP-712, ERC-1271, nonce and recovery-invalidating complexity. |
| Care mode | Requires a separate delegated authority model. |
| Encrypted notes | Key custody and disclosure timing are undesigned. |
| Developer-controlled beneficiary wallet | Reintroduces custody at the final step. |
| Percentage-of-distribution fee | Weakens destination lock and creates poor regulatory and user optics. |
| Off-chain liveness assertion | Puts a service in the correctness path. |
| Personal data on-chain | Permanently exposes relationships and notification data. |

## 7. Honest limits

| Limit | Required product copy |
|---|---|
| Silence is not death | A live but inactive owner can lose control on the configured schedule. |
| Key loss is not detectable | Heirloom cannot determine whether a beneficiary can access an address. |
| Distribution is irreversible | After `startDistribution()` succeeds, owner control cannot be restored. |
| V1 requires addresses at setup | Beneficiaries need not submit a transaction, but each destination must already exist. |
| Addresses and shares are public | The configuration may reveal economic relationships. |
| Owner-key compromise is outside fund-theft protection | An attacker with the owner key may withdraw while the vault is Active. |
| USDC is externally administered | Pause, blacklist or implementation changes may prevent transfer. |
| Permissionless is not guaranteed execution | Anyone can execute, but no actor is obliged to do so. |
| Notifications are convenience | A failed reminder does not change an on-chain deadline. |
| Unsupported assets may be stranded | V1 guarantees no rescue path for tokens other than configured USDC. |

---

# Part II - Normative Protocol Model

## 8. Actors and authority

| Actor | Authority |
|---|---|
| Current owner | Heartbeat, deposit, withdraw, propose config, veto config, veto recovery and cancel a claim through fresh activity. |
| Guardian | Request and approve activation of the precommitted recovery address. Cannot select a new owner. |
| Any caller | Request claim, start distribution, execute the currently valid payout, mark matured rollover, execute config after ETA, activate matured recovery, sweep excess after settlement. |
| Factory | Deploy a fixed vault version and emit deployment evidence. No control over deployed vaults. |
| Issuer and Base environment | External dependencies, not Heirloom authorities. |

No admin, pause key, upgrade pointer, migration key or emergency withdrawal authority exists in
a deployed V1 vault.

## 9. State machine

```text
                         fresh owner activity
                   +-----------------------------+
                   |                             |
                   v                             |
              +----------+                      |
              |  Active  |                      |
              +----+-----+                      |
                   | requestClaim               |
                   | after inactivity threshold |
                   v                             |
          +------------------+                   |
          |  ClaimRequested  |-------------------+
          +---------+--------+  or recovery activation
                    |
                    | startDistribution after challenge
                    | and matching request epoch
                    v
             +--------------+
             | Distributing |
             +------+-------+
                    |
                    | all non-terminal resolved,
                    | terminal paid once
                    v
                +---------+
                | Settled |
                +---------+
```

### 9.1 State permissions

| State | Owner-authorized actions | Permissionless actions | Config |
|---|---|---|---|
| Active | Heartbeat, deposit, withdraw, propose, veto, recovery veto | Request claim, execute mature config, request/approve/activate recovery | Delayed lifecycle enabled |
| ClaimRequested | Heartbeat, deposit or withdraw cancels claim; recovery veto | Start distribution after challenge; request/approve/activate precommitted recovery | Frozen |
| Distributing | None | Execute non-terminal payout, mark rollover, execute terminal when unlocked | Frozen |
| Settled | None | Sweep supported-token excess | Frozen |

### 9.2 Exact transition boundaries

- Claim request is allowed when `block.timestamp >= lastSeen + inactivityPeriod`.
- Distribution start is allowed when `block.timestamp >= executeAfter`.
- Primary destination is valid when `block.timestamp < fallbackAt`.
- Fallback destination is valid when `fallbackAt <= block.timestamp < rolloverAt`.
- Rollover is valid when `block.timestamp >= rolloverAt`.
- Terminal primary is valid when `block.timestamp < terminalFallbackAt`.
- Terminal fallback is valid when `block.timestamp >= terminalFallbackAt` and remains valid indefinitely.

## 10. Liveness

### 10.1 Normative rule

> Only a fresh authorization attributable to the current owner may update `lastSeen`.

Every liveness update also increments `livenessNonce`. If the vault is ClaimRequested, the
update cancels the request and returns the vault to Active before the requested owner action
continues.

### 10.2 Action matrix

| Action | Updates `lastSeen` | Reason |
|---|---:|---|
| `heartbeat()` by current owner | Yes | Direct fresh owner authorization. |
| `deposit(amount)` by current owner | Yes | Direct owner call plus exact token receipt. |
| `withdraw(amount,to)` by current owner | Yes | Direct owner call. |
| `proposeConfig(...)` by current owner | Yes | Direct owner authorization. |
| `vetoConfig()` by current owner | Yes | Direct owner authorization. |
| `vetoRecovery()` by current owner | Yes | Direct owner authorization. |
| `cancelClaimWithHeartbeat()` by current owner | Yes | Explicit owner return. |
| Permissionless `executeConfig(...)` | **No** | Executor need not be owner. Never heartbeat, even if caller equals owner. |
| Claim request or distribution action | **No** | Public execution is not owner activity. |
| Guardian request or vote | **No** | Guardian activity is not owner activity. |
| Third-party direct USDC transfer | **No** | No owner-authenticated vault call occurred. |
| Recovery activation | Reset | Installs new owner, sets `lastSeen = block.timestamp`, increments liveness epoch. |

### 10.3 Prohibited designs

- Recurring automatic heartbeat jobs.
- Backend-held heartbeat keys.
- Unlimited session keys that can heartbeat without fresh owner participation.
- Treating arbitrary owner-wallet activity as vault liveness.
- Treating notification acknowledgement as on-chain liveness.

## 11. Claim request and liveness-epoch binding

`requestClaim()` stores:

```solidity
struct ClaimRequest {
    uint64 requestedAt;
    uint64 executeAfter;
    uint64 livenessNonce;
    uint64 configNonce;
}
```

It is callable by anyone only from Active after the inactivity threshold. It transfers no
asset.

`startDistribution()` requires all of the following:

1. State is ClaimRequested.
2. `block.timestamp >= executeAfter`.
3. Stored `livenessNonce` equals the current liveness nonce.
4. Stored `configNonce` equals the current config nonce.
5. No completed recovery changed the owner epoch.

Any successful owner-liveness action or recovery activation deletes the claim request and
emits `ClaimCancelled` with a reason code.

The irreversible boundary is `startDistribution()`. Once successful, no heartbeat, recovery,
withdrawal or configuration path may return the vault to an earlier state.

## 12. Distribution configuration

### 12.1 Beneficiary structure

```solidity
struct Beneficiary {
    address primary;
    address fallbackAddress;
    uint16 bps;
}
```

- One to seven non-terminal beneficiaries.
- Exactly one terminal beneficiary with the same primary/fallback structure.
- Maximum eight total entries including terminal.
- Every BPS value is greater than zero.
- All BPS values total exactly 10,000.
- Every configured destination is nonzero.
- `primary != fallbackAddress` for every entry.
- V1 rejects duplicate destination addresses across the full schedule.

### 12.2 Snapshot and entitlements

At `startDistribution()`:

```text
snapshotBalance   = USDC.balanceOf(vault)
snapshotRemaining = snapshotBalance
entitlement[i]    = floor(snapshotBalance * bps[i] / 10_000)
terminalBase      = snapshotBalance - sum(nonTerminalEntitlements)
```

The terminal absorbs:

- Its configured proportional share.
- Every integer rounding unit.
- Every non-terminal entitlement later marked RolledOver.

A positive-BPS non-terminal entitlement may round to zero. It is marked Paid without a token
call and emits a zero-resolution event. The setup UI warns when the current balance would
produce a zero entitlement, but configuration remains valid because the balance may change.

A zero snapshot settles through the normal terminal-unlock path without a token call and emits
`Settled` with zero values.

## 13. Time-based destination schedule

### 13.1 Non-terminal phase

All non-terminal beneficiaries use the same vault-level schedule anchored to
`distributionStartedAt`:

```text
fallbackAt = distributionStartedAt + primaryWindow
rolloverAt = fallbackAt + fallbackWindow

PRIMARY ONLY          FALLBACK ONLY             ROLLOVER ONLY
time < fallbackAt     fallbackAt <= time         time >= rolloverAt
                      < rolloverAt
```

`executePayout(index)` accepts only the beneficiary index. It has no destination argument.
The contract derives exactly one valid destination from time and status.

- Before `fallbackAt`, only `primary` is valid.
- At or after `fallbackAt` and before `rolloverAt`, only `fallbackAddress` is valid.
- At or after `rolloverAt`, neither address is payable; only `rolloverPayout(index)` is valid.
- A reverting transfer leaves the entitlement Unresolved and changes no snapshot accounting.
- Primary transfer failure does not activate fallback early.
- Primary recovery after `fallbackAt` does not make primary valid again.

Heirloom cannot detect key loss, death, incapacity or whether a recipient contract can later
move received USDC. Ordinary ERC-20 transfer semantics do not include a mandatory recipient
callback. See [ERC-20](https://eips.ethereum.org/EIPS/eip-20).

### 13.2 Beneficiary status

```solidity
enum BeneficiaryStatus {
    Unresolved,
    Paid,
    RolledOver
}
```

Each non-terminal beneficiary transitions exactly once:

```text
Unresolved -> Paid
Unresolved -> RolledOver
```

No transition exists from Paid or RolledOver.

### 13.3 Terminal-last settlement

Terminal is locked until every non-terminal status is Paid or RolledOver.

When the last non-terminal resolves:

```text
terminalUnlockedAt = block.timestamp
terminalFallbackAt = terminalUnlockedAt + primaryWindow
terminalAmount      = snapshotRemaining
```

Terminal routing is:

- Terminal primary only before `terminalFallbackAt`.
- Terminal fallback only at or after `terminalFallbackAt`.
- Terminal fallback remains valid indefinitely; there is no further economic destination.

`executeTerminalPayout()` transfers exactly `snapshotRemaining` once. A successful transfer
sets `snapshotRemaining` to zero, stores the destination used, emits `TerminalPaid` and
`Settled`, and moves the state to Settled.

If both terminal destinations remain unable to receive USDC, the vault remains Distributing.
This is a published environmental limit, not a condition Heirloom can solve by inventing a new
owner.

## 14. Exact-transfer accounting and excess

V1 assumes exact-transfer Base USDC behavior at the block being executed.

Every supported-token transfer uses a safe wrapper and balance-delta validation:

```text
beforeBalance - afterBalance == requestedOutgoingAmount
afterBalance - beforeBalance == requestedIncomingAmount
```

If a delta differs, the transaction reverts and no beneficiary status or snapshot accounting
changes.

During Distributing:

```text
actualBalance = USDC.balanceOf(vault)

if actualBalance < snapshotRemaining:
    revert AccountingDeficit

excessBalance = actualBalance - snapshotRemaining
```

- Direct transfers before `startDistribution()` are part of the snapshot.
- Direct transfers after the snapshot are excess.
- Excess does not alter BPS entitlements.
- Excess is not swept while Distributing.
- After Settled, `sweepExcess()` sends the full supported-token balance to the terminal
  destination that successfully completed settlement.
- Later supported-token deposits after settlement follow the same destination.
- Unsupported tokens have no V1 rescue path.

## 15. Configuration lifecycle

### 15.1 Proposal

Only the current owner may propose a complete replacement configuration while Active. A
proposal updates liveness. One pending proposal exists per vault. A replacement cancels the
previous proposal and restarts the delay.

The proposal hash binds:

- Chain ID.
- Vault address.
- Factory/version identifier.
- Current `configNonce`.
- Complete beneficiary and terminal schedule.
- Liveness and distribution durations.
- Guardian set, threshold, recovery delay and recovery address.

### 15.2 Execution

Any caller may execute the exact proposal after ETA and before expiry while Active.

Permissionless execution:

- Never updates `lastSeen`.
- Never increments `livenessNonce`.
- Cannot change the proposal payload.
- Increments `configNonce` only after successful validation and application.
- Is unavailable from ClaimRequested onward.

The owner may heartbeat separately before or after execution while the vault remains Active.

### 15.3 Veto, expiry and invalidation

- Owner veto while Active deletes the proposal and creates liveness.
- Expired proposals cannot execute and may be cleared by anyone.
- Recovery activation deletes the pending proposal and increments `configNonce`.
- ClaimRequested freezes proposal creation, veto and execution.

## 16. Guardian recovery

### 16.1 Configuration

- Three to seven unique guardian addresses.
- Threshold from two guardians up to guardian count.
- Owner, recovery address and zero address cannot be guardians.
- Recovery address is nonzero and different from current owner.
- Guardians can activate only that precommitted recovery address.

### 16.2 Lifecycle

```text
NoRequest
   -> RecoveryRequested
   -> ThresholdReached
   -> Delayed
   -> Activated or Expired

Owner veto is available before activation.
```

1. A configured guardian calls `requestRecovery()` in Active or ClaimRequested.
2. Guardians call `approveRecovery(requestNonce)` once each.
3. When threshold is reached, the contract stores `readyAt = now + recoveryDelay` and
   `expiresAt = readyAt + recoveryExecutionWindow`.
4. Current owner may call `vetoRecovery()` before activation. This creates liveness and cancels
   any pending claim.
5. Any caller may call `activateRecovery()` when `readyAt <= now <= expiresAt`.
6. After expiry, anyone may clear the request; guardians must start a new request.

### 16.3 Activation effects

Activation is atomic:

1. Install only the precommitted recovery address as owner.
2. Delete any claim request and return the vault to Active.
3. Delete pending configuration.
4. Increment `recoveryNonce`, `livenessNonce` and `configNonce`.
5. Set `lastSeen = block.timestamp`.
6. Delete guardian approvals for the completed request.
7. Emit old owner, new owner and every new nonce.

Existing guardians remain configured, but another activation would target the now-current
owner and creates no additional authority. The recovered owner should configure a new recovery
address through the normal config delay.

Recovery is unavailable after distribution starts.

## 17. Owner smart accounts and signatures

V1 authorizes the owner with `msg.sender == owner`.

A Base smart account can therefore own the vault and call it directly after validating its own
authorization. The vault does not implement `heartbeatBySig`, custom EIP-712 actions or direct
ERC-1271 signature validation in V1. ERC-1271 remains an account-layer concern unless a future
version deliberately accepts relayed signed vault messages. See
[ERC-1271](https://eips.ethereum.org/EIPS/eip-1271).

Sponsored transactions are valid when the owner account freshly authorizes the call. A
paymaster may pay gas but may not originate unattended heartbeat authority.

## 18. Durations and audited bounds

### 18.1 Personal-continuity V1 defaults

| Parameter | Default | Allowed bounds | Reason |
|---|---:|---:|---|
| Inactivity period | 365 days | 90 days to 5 years | Conservative annual return expectation with meaningful flexibility. |
| Claim challenge | 30 days | 7 to 60 days | Gives a returning owner time without creating an indefinite limbo. |
| Primary payout window | 90 days | 30 to 180 days | Allows primary destination use before ownership shifts. |
| Fallback payout window | 90 days | 30 to 180 days | Gives fallback a real exclusive window before rollover. |
| Config delay | 7 days | 2 to 30 days | Makes destination changes visible and vetoable. |
| Config execution window | 30 days | Fixed in V1 | Prevents permanently executable stale proposals. |
| Recovery delay | 7 days | 2 to 30 days | Gives the owner a veto opportunity after guardian quorum. |
| Recovery execution window | 30 days | Fixed in V1 | Prevents permanently activatable recovery requests. |

Setup must show absolute calendar projections for each deadline and require the owner to
confirm them before funding.

### 18.2 Operator duration decision

V1 does not ship an operator-treasury preset. Operator continuity requires a separate outage
model, live spending design and root-owner comparison. It may use the same primitive only after
product validation. This closes D6 by deferral, not by inventing unsafe short defaults.

## 19. Supported asset and environmental risk

V1 supports only Circle-issued USDC on Base:

| Network | Chain ID | Address |
|---|---:|---|
| Base mainnet | 8453 | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| Base Sepolia | 84532 | `0x036CbD53842c5426634e7929541eC2318f3dCF7e` |

These addresses are verified against Circle's current
[USDC contract-address registry](https://developers.circle.com/stablecoins/usdc-contract-addresses).

The vault is immutable; the asset implementation and issuer controls are not. Circle's token
architecture includes administrative behavior such as pause and blacklist, and its proxy
implementation can change independently of Heirloom. Therefore:

- Mainnet-fork tests prove compatibility only with the tested block and implementation.
- A blacklisted vault or destination may be unable to transfer.
- A paused token may stop deposits, withdrawals and payouts.
- Heirloom cannot override issuer controls.
- Monitoring must alert on implementation and role changes.
- No absolute no-stranding promise is permitted.

## 20. Base execution and confirmation UX

The contract adds no separate confirmation delay. A same-chain reorganization removes the
state update and corresponding transfer together; application confirmation is a UX concern,
not a new asset-control rule.

The application distinguishes:

1. Submitted.
2. Preconfirmed.
3. L2 included.
4. L1 batched.
5. Finalized.

Preconfirmation is never presented as irreversible. Current Base behavior must be refreshed
from the official [Base transaction-finality documentation](https://docs.base.org/base-chain/network-information/transaction-finality)
before launch and whenever the application labels confirmation stages.

The challenge window protects owner return; it is not a finality substitute.

---

# Part III - Technical Design

## 21. Deployment architecture

```text
OFFICIAL VERSIONED FACTORY
    |
    | deploys full immutable bytecode
    v
VAULT
    |- immutable asset address and version identifier
    |- mutable owner only through precommitted recovery
    |- liveness and claim state
    |- complete delayed configuration
    |- snapshot and per-beneficiary resolution status
    |- terminal-last settlement
    `- no admin, proxy, pause or upgrade path

OPTIONAL OFF-CHAIN SERVICES
    |- index events and derive warnings
    |- notify users
    |- sponsor freshly authorized owner calls
    `- sponsor permissionless claim and payout calls
```

Each factory publishes:

- Semantic version.
- Compiler version and settings.
- Source repository commit.
- Creation bytecode hash.
- Runtime bytecode hash.
- Supported chain and USDC address.
- Independent audit references for that exact bytecode.

A new protocol version uses a new factory and bytecode. Existing owners migrate voluntarily by
withdrawing while Active and creating a new vault.

## 22. Proposed external interface

Names may change only if the normative behavior and invariants remain identical.

```solidity
interface IHeirloomVaultV31 {
    // Owner liveness and funds
    function heartbeat() external;
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount, address to) external;

    // Claim lifecycle
    function requestClaim() external;
    function cancelClaimWithHeartbeat() external;
    function startDistribution() external;

    // Distribution
    function executePayout(uint8 beneficiaryIndex) external;
    function rolloverPayout(uint8 beneficiaryIndex) external;
    function executeTerminalPayout() external;
    function sweepExcess() external;

    // Configuration
    function proposeConfig(bytes calldata encodedConfig) external;
    function vetoConfig() external;
    function executeConfig(bytes calldata encodedConfig) external;
    function clearExpiredConfig() external;

    // Recovery
    function requestRecovery() external;
    function approveRecovery(uint64 requestNonce) external;
    function vetoRecovery() external;
    function activateRecovery() external;
    function clearExpiredRecovery() external;

    // Views
    function state() external view returns (VaultState);
    function claimable() external view returns (bool);
    function destinationPhase(uint8 beneficiaryIndex) external view returns (DestinationPhase);
    function entitlement(uint8 beneficiaryIndex) external view returns (uint256);
    function excessBalance() external view returns (uint256);
    function currentConfigHash() external view returns (bytes32);
}
```

## 23. Storage model

Minimum conceptual storage:

```solidity
address owner;
IERC20 immutable asset;
bytes32 immutable versionId;

VaultState vaultState;
uint64 lastSeen;
uint64 livenessNonce;
uint64 configNonce;
uint64 recoveryNonce;

Durations durations;
Beneficiary[] nonTerminal;
Beneficiary terminal;
address[] guardians;
uint8 guardianThreshold;
address recoveryAddress;

ClaimRequest claimRequest;
PendingConfig pendingConfig;
RecoveryRequest recoveryRequest;

uint64 distributionStartedAt;
uint64 fallbackAt;
uint64 rolloverAt;
uint64 terminalUnlockedAt;
uint64 terminalFallbackAt;
uint256 snapshotBalance;
uint256 snapshotRemaining;
BeneficiaryStatus[] beneficiaryStatus;
address settledTerminalDestination;
```

Use packed storage only after correctness, auditability and gas measurements. Do not obscure
state boundaries for marginal deployment savings.

## 24. Events

| Event | Minimum fields |
|---|---|
| `VaultCreated` | vault, owner, asset, versionId, configHash |
| `OwnerActivity` | owner, actionType, lastSeen, livenessNonce |
| `ClaimRequested` | caller, requestNonce, requestedAt, executeAfter, livenessNonce, configNonce |
| `ClaimCancelled` | reason, actor, newLastSeen, livenessNonce |
| `DistributionStarted` | caller, snapshotBalance, startedAt, fallbackAt, rolloverAt |
| `BeneficiaryPaid` | index, destination, phase, amount, caller |
| `EntitlementRolledOver` | index, amount, caller |
| `TerminalUnlocked` | unlockedAt, terminalFallbackAt, snapshotRemaining |
| `TerminalPaid` | destination, phase, amount, caller |
| `ExcessSwept` | destination, amount, caller |
| `Settled` | snapshotBalance, totalNonTerminalPaid, terminalAmount, terminalDestination |
| `ConfigProposed` | proposalNonce, configHash, eta, expiresAt |
| `ConfigReplaced` | oldHash, newHash, proposalNonce |
| `ConfigVetoed` | configHash, owner, livenessNonce |
| `ConfigExecuted` | configHash, executor, configNonce |
| `ConfigExpired` | configHash, clearer |
| `RecoveryRequested` | requestNonce, guardian, recoveryAddress |
| `RecoveryApproved` | requestNonce, guardian, approvalCount |
| `RecoveryThresholdReached` | requestNonce, readyAt, expiresAt |
| `RecoveryVetoed` | requestNonce, owner, livenessNonce |
| `RecoveryActivated` | oldOwner, newOwner, recoveryNonce, livenessNonce, configNonce |
| `RecoveryExpired` | requestNonce, clearer |

## 25. Custom errors

Minimum error surface:

```solidity
error Unauthorized();
error InvalidState();
error NotMatured();
error ChallengeNotElapsed();
error StaleClaimRequest();
error InvalidBeneficiaryIndex();
error EntitlementAlreadyResolved();
error WrongDestinationPhase();
error TerminalLocked();
error InvalidConfiguration();
error InvalidDuration();
error ConfigNotReady();
error ConfigExpired();
error ConfigHashMismatch();
error RecoveryNotReady();
error RecoveryExpired();
error GuardianAlreadyApproved();
error AccountingDeficit();
error UnexpectedTokenDelta();
error ZeroAddress();
error Reentrancy();
```

## 26. Interaction ordering and reentrancy

- Use checks-effects-interactions.
- Use a reentrancy guard on every token-moving function.
- Derive destination before external token interaction.
- Mark status and update snapshot accounting before transfer, relying on transaction revert to
  restore state if the transfer or balance-delta check fails.
- Never call an arbitrary beneficiary contract directly.
- Do not use ERC-777-style hooks.
- Do not make external notifier, oracle, paymaster or relayer calls from the vault.

## 27. Formal invariants

Stateful invariants are mandatory. Each must be demonstrated with a mutation that causes the
test to fail.

| ID | Invariant |
|---|---|
| I1 | `lastSeen` changes only after fresh current-owner authorization or completed recovery. |
| I2 | Permissionless actions, guardian actions, third-party deposits and direct token transfers never create owner liveness. |
| I3 | `requestClaim()` transfers no vault asset and records the current liveness/config epoch. |
| I4 | `startDistribution()` succeeds only for the current request epoch and is the sole irreversible boundary. |
| I5 | A permissionless caller cannot choose payout amount, destination, entitlement, phase or terminal order. |
| I6 | Exactly one non-terminal destination phase is valid for an unresolved beneficiary at any timestamp. |
| I7 | After `rolloverAt`, primary and fallback payment are impossible for non-terminal beneficiaries. |
| I8 | Every non-terminal entitlement resolves exactly once as Paid or RolledOver. |
| I9 | Terminal payout is impossible while any non-terminal entitlement is Unresolved. |
| I10 | The sum of non-terminal entitlements plus terminal base entitlement equals the snapshot. |
| I11 | Every rolled-over amount remains in `snapshotRemaining` and therefore increases final terminal payment exactly once. |
| I12 | A failed or inexact token transfer changes no beneficiary status and no snapshot accounting. |
| I13 | Every successful payout reduces `snapshotRemaining` by exactly the outgoing token balance delta. |
| I14 | Settled implies `snapshotRemaining == 0`, all non-terminal entries resolved and terminal paid exactly once. |
| I15 | Recovery installs only the precommitted address and invalidates old claims, configs, approvals and nonces atomically. |
| I16 | Vault version, asset, factory and runtime bytecode identity remain publicly verifiable for the life of the vault. |

## 28. Test strategy

### 28.1 Liveness and P0-1 regression

| Test | Assertion |
|---|---|
| `test_ownerHeartbeatUpdatesLiveness` | Owner heartbeat changes lastSeen and nonce. |
| `test_permissionlessConfigExecutionDoesNotHeartbeat` | Mature config execution leaves lastSeen and livenessNonce unchanged. |
| `test_ownerExecutingConfigStillDoesNotHeartbeat` | Caller identity does not change executeConfig semantics. |
| `test_thirdPartyTransferDoesNotHeartbeat` | Direct USDC transfer changes balance only. |
| `test_guardianVoteDoesNotHeartbeat` | Guardian actions do not postpone claim maturity. |
| `test_ownerDepositExactDeltaHeartbeats` | Exact owner deposit changes liveness. |
| `test_inexactDepositRevertsWithoutHeartbeat` | Token delta mismatch rolls back liveness. |
| `test_recoveryStartsNewLivenessEpoch` | New owner and nonces update atomically. |

### 28.2 ERC-20 reality and P0-2 regression

| Test | Assertion |
|---|---|
| `test_transferToEOAWithoutKnownKeySucceeds` | Transfer success cannot be used as key-access evidence. |
| `test_transferToIncapableContractSucceeds` | Ordinary USDC does not call the recipient. |
| `test_primaryRevertDoesNotOpenFallbackEarly` | Fallback remains timestamp-gated. |
| `test_blacklistedDestinationPreservesAccounting` | Token revert leaves status and snapshot unchanged. |
| `test_pausedTokenPreservesAccounting` | Pause is an environmental block, not a resolution. |

### 28.3 Phase exclusivity and P0-3 regression

| Test | Assertion |
|---|---|
| `test_phaseOneSecondBeforeFallback` | Primary only. |
| `test_phaseAtFallback` | Fallback only. |
| `test_phaseOneSecondBeforeRollover` | Fallback only. |
| `test_phaseAtRollover` | Rollover only. |
| `test_executePayoutHasNoDestinationChoice` | Arbitrary caller cannot encode a route. |
| `test_primaryCannotRecoverAfterPhaseEnds` | Earlier destination remains invalid. |
| `testFuzz_exactlyOneDestinationPhase` | Phase exclusivity across timestamps. |

### 28.4 Terminal-last and P0-4 regression

| Test | Assertion |
|---|---|
| `test_terminalCannotExecuteEarly` | Any unresolved non-terminal locks terminal. |
| `test_rolloverIncreasesTerminalAmountOnce` | Rollover is conserved without duplicate accrual. |
| `test_multipleRollovers` | All rolled shares remain in final snapshotRemaining. |
| `test_paidCannotRollover` | Paid is terminal status. |
| `test_rolledCannotPay` | RolledOver is terminal status. |
| `test_terminalPrimaryThenFallbackBoundary` | Terminal uses one exclusive destination at a time. |
| `test_terminalPaymentSettlesExactly` | One payment makes snapshotRemaining zero. |
| `testFuzz_nonTerminalOrderIndependent` | Final conservation is independent of resolution order. |

### 28.5 Claim and recovery

| Test | Assertion |
|---|---|
| `test_requestAtExactInactivityBoundary` | Inclusive boundary. |
| `test_startAtExactChallengeBoundary` | Inclusive boundary. |
| `test_ownerActivityCancelsRequest` | Request is deleted before owner action proceeds. |
| `test_staleLivenessEpochRejected` | Old request cannot start distribution. |
| `test_staleConfigEpochRejected` | Old configuration request cannot start distribution. |
| `test_recoveryDuringChallengeCancelsClaim` | Precommitted recovery remains available. |
| `test_recoveryThresholdCannotChooseAddress` | No guardian sequence installs another destination. |
| `test_recoveryDelayAndExpiry` | Both exact boundaries are pinned. |
| `test_recoveryVetoCreatesLiveness` | Current owner veto cancels claim and updates nonce. |

### 28.6 Shares, snapshot and excess

| Test | Assertion |
|---|---|
| `test_bpsMustTotal10000` | Invalid total rejected. |
| `test_maxEightIncludingTerminal` | Ninth total entry rejected. |
| `test_duplicateDestinationRejected` | Ambiguous schedule rejected. |
| `test_terminalAbsorbsRounding` | Every integer unit assigned. |
| `test_zeroEntitlementResolvesWithoutTransfer` | Tiny snapshots cannot block terminal. |
| `test_zeroSnapshotSettles` | Empty vault does not strand state. |
| `test_directTransferBeforeSnapshotIncluded` | Pre-snapshot balance joins estate. |
| `test_directTransferAfterSnapshotIsExcess` | Entitlements unchanged. |
| `test_excessWaitsUntilSettled` | No premature sweep. |
| `test_postSettlementTransferSweepsToStoredTerminal` | Later supported asset follows settled terminal destination. |
| `test_accountingDeficitReverts` | Snapshot obligation cannot be silently reduced. |
| `testFuzz_shareConservation` | Total resolved plus remaining equals snapshot. |

### 28.7 Configuration and deployment

| Test | Assertion |
|---|---|
| `test_configHashBindsChainVaultVersionNonce` | Cross-vault and cross-chain replay impossible. |
| `test_configReplacementRestartsDelay` | Old mature proposal cannot survive replacement. |
| `test_configExpiry` | Stale proposal cannot execute. |
| `test_configFrozenFromClaimRequested` | No config operation bypasses state gate. |
| `test_recoveryInvalidatesPendingConfig` | Proposal cannot execute after owner change. |
| `test_factoryRuntimeHashMatchesVersion` | Deployment identity is reproducible. |
| `test_constructorRejectsInvalidSchedule` | Invalid vault never deploys. |

### 28.8 Base and real USDC

- Base Sepolia complete lifecycle against official test USDC.
- Base mainnet fork pinned to an audited block.
- Latest available Base mainnet fork in CI as a compatibility signal.
- USDC paused behavior.
- Blacklisted vault behavior.
- Blacklisted primary, fallback and terminal behavior.
- Proxy implementation and administrative-role monitoring evidence.
- Mutation evidence for every invariant and high-risk branch.

## 29. Decision register D1-D40

No decision in this register is TBD. Product research may revise defaults only through a new
version and renewed security review.

| ID | Decision | V3.1 position | Test or gate consequence |
|---|---|---|---|
| D1 | Heartbeat source | Fresh current-owner authorization against the vault only. | I1-I2 and liveness matrix tests. |
| D2 | Config while claiming | Frozen from ClaimRequested onward. Owner activity first returns to Active. | State-gate tests. |
| D3 | Care mode | Out of V1. | No delegated withdrawal authority. |
| D4 | L2 confirmation | No contract delay; application labels confirmation stages. | Base UX acceptance test. |
| D5 | Human durations | Defaults and audited bounds in section 18. | Exact-boundary tests for every duration. |
| D6 | Operator durations | No V1 operator preset; separate product validation. | Cannot select operator profile in V1 UI. |
| D7 | Owner return after distribution | No reversal. | Owner actions revert after startDistribution. |
| D8 | Encrypted notes | Out of V1. | No note ciphertext or key material on-chain. |
| D9 | Distribution model | Estate split by BPS snapshot; terminal absorbs rounding. | Share-conservation fuzzing. |
| D10 | Operator treasury role | Secondary and not launch positioning. | Personal continuity is default journey. |
| D11 | Market claim | Asset continuity with permissionless, destination-locked execution. | Claims review gate. |
| D12 | Recovery destination | Owner precommits; guardians activate only. | Arbitrary recovery address unreachable. |
| D13 | Owner-key compromise | Model A: active funds can be withdrawn by compromised owner key. | Prominent threat-model copy. |
| D14 | On-chain states | Active, ClaimRequested, Distributing, Settled. | State-machine exhaustive tests. |
| D15 | Supported asset | Base USDC only, with issuer risks. | Address and fork tests. |
| D16 | Snapshot and deposits | Snapshot at startDistribution; direct transfers cannot be blocked. | Snapshot/excess tests. |
| D17 | Recipient routing | Time-based primary, fallback and rollover; no failure detection. | Phase-exclusivity tests. |
| D18 | Privacy | Public addresses and shares; no personal metadata. | Storage and event review. |
| D19 | No-stranding scope | No absolute promise; only stated asset and transfer assumptions. | Product-claims gate. |
| D20 | Beneficiary onboarding | Self-custodied addresses in V1. | No developer custody path. |
| D21 | Claim lifecycle | Request, challenge, startDistribution. | Epoch and boundary tests. |
| D22 | Excess | Post-snapshot supported-token excess goes to stored terminal destination after settlement. | Excess tests. |
| D23 | Recovery during claim | Request, approval and activation of precommitted recovery remain available. | Recovery/claim race tests. |
| D24 | Deployment | Full immutable vaults from versioned factory. | Runtime hash evidence. |
| D25 | Business model | Setup, subscription and integrations; no estate percentage. | Fee-path architecture review. |
| D26 | Legal category | Asset continuity, not inheritance. | Marketing and counsel gate. |
| D27 | Liveness action set | Exact matrix in section 10. | Exhaustive action-to-lastSeen tests. |
| D28 | Permissionless config execution | Never heartbeats, regardless of executor identity. | Direct P0-1 regression test. |
| D29 | Fallback trigger | Time only; never transfer-failure detection. | Lost-key and incapable-contract tests. |
| D30 | Destination exclusivity | Exactly one phase valid at a timestamp. | I6-I7 fuzzing. |
| D31 | Terminal order | Locked until every non-terminal resolves; paid once. | I9 and terminal tests. |
| D32 | Zero entitlement | Mark Paid without token call; emit evidence. | Tiny-snapshot test. |
| D33 | Duplicate destinations | Reject all duplicates in V1. | Constructor/config validation. |
| D34 | Claim request binding | Store livenessNonce and configNonce. | Stale-request tests. |
| D35 | Recovery governance | 3-7 guardians, threshold >=2, delayed activation, owner veto and expiry. | Recovery lifecycle tests. |
| D36 | Recovery address | Precommitted, nonzero and not current owner. | Destination-selection invariant. |
| D37 | Custom ERC-1271 actions | Excluded; smart account calls vault directly. | No by-signature interface. |
| D38 | USDC changes | Monitor implementation and roles; pinned plus latest fork tests. | Operational launch gate. |
| D39 | Post-settlement excess | Sweep to the terminal destination used at settlement. | Later-transfer sweep test. |
| D40 | Automatic heartbeat | Prohibited; fresh owner authorization required every time. | Product and permission review. |

---

# Part IV - Product, Operations, Legal and Business

## 30. Required UX flows

### 30.1 Create and fund

1. Connect owner EOA or smart account.
2. Verify chain, factory version and official USDC.
3. Add non-terminal and terminal addresses and BPS.
4. Add distinct fallback destinations.
5. Configure guardians and precommitted recovery address.
6. Select durations within bounds.
7. Show absolute projected dates for every phase.
8. Require acknowledgement of silence, irreversibility, key-loss and USDC limits.
9. Deploy, source-verify and show bytecode/version evidence.
10. Fund through owner-authorized deposit.

### 30.2 Owner dashboard

- Current state and last owner-authenticated activity.
- Next inactivity threshold in absolute and relative time.
- One explicit Heartbeat control.
- Pending config and recovery requests with veto deadlines.
- ClaimRequested emergency banner with challenge end time.
- Direct contract link and recovery instructions if hosted services disappear.

### 30.3 Beneficiary and public evidence

- Vault version and supported asset.
- Current state and distribution snapshot.
- Beneficiary index, BPS, current phase and resolved status.
- No personal names or private relationship metadata.
- Transaction links for request, distribution start, payout, rollover, terminal and excess.

## 31. Notifications and relayers

Notifications are advisory. Recommended reminders:

- 60, 30, 14, 7 and 1 day before inactivity threshold.
- Immediately when ClaimRequested.
- Daily during the last seven challenge days.
- At distribution start and every phase transition.
- When recovery quorum is reached and before activation.
- When configuration is proposed, ready, near expiry, executed or vetoed.

Relayers may sponsor:

- Freshly owner-authorized calls.
- Permissionless claim and distribution calls.

Relayers hold no vault key, cannot assert liveness, cannot change destinations and are never
required for correctness.

## 32. Legal and compliance workstream

This document is not legal advice. Before mainnet:

| Workstream | Required action |
|---|---|
| Estate and property law | Avoid probate-avoidance claims; obtain jurisdiction-specific counsel; encourage conventional documents to reference the vault. |
| Tax evidence | Preserve snapshot, transaction, address and valuation evidence. |
| Money transmission | Review hosted sponsorship, fees and operational control while remaining non-custodial. |
| Sanctions | Review frontend, notifier, sponsorship and relayer obligations. |
| Privacy | Keep names, emails and relationships off-chain; protect notification metadata. |
| Consumer communication | Present inactivity, irreversibility and environmental token risks before funding. |

## 33. Business model

Sell reliability and user experience, not custody.

| Revenue path | V1 position |
|---|---|
| One-time setup fee | Allowed, paid separately from vault assets. |
| Reminder subscription | Allowed for monitoring, notifications and sponsored owner calls. |
| Sponsored claim execution | Included service; every contract function stays public. |
| Wallet integration | White-label continuity module. |
| Treasury evidence tooling | Later B2B opportunity after separate validation. |
| Percentage of distributed assets | Prohibited in V1. |

## 34. Operational monitoring

Monitor without acquiring authority:

- Factory and vault deployment verification.
- USDC implementation address and administrative roles.
- ClaimRequested and recovery events.
- Pending config ETA and expiry.
- Distribution phases and unresolved beneficiaries.
- Relayer availability and sponsorship budget.
- Indexer lag and notification-delivery health.

Monitoring failure must never alter contract state or deadline computation.

---

# Part V - Build and Release Plan

## 35. Implementation order

| Stage | Deliverable | Exit gate |
|---|---|---|
| 0A | Signed v3.1 specification | D1-D40 and I1-I16 accepted without contradiction. |
| 0B | Pure executable reference model | Every state, boundary and resolution order enumerated. |
| 1 | Share, snapshot and phase libraries | Conservation and phase fuzz suites green with mutation evidence. |
| 2 | Claim and liveness kernel | P0-1 and stale-epoch regressions green. |
| 3 | Distribution and terminal settlement | P0-2, P0-3 and P0-4 regressions green. |
| 4 | Config and recovery | Full lifecycle, veto, expiry and invalidation tests green. |
| 5 | Factory and Base Sepolia | Source-verified full lifecycle evidence pack. |
| 6 | Mainnet-fork compatibility | Pinned and latest Base USDC suites green. |
| 7 | Independent audit | All findings remediated and retested. |
| 8 | Guarded mainnet | Limited cohort, monitoring and explicit launch approval. |

## 36. Stage 0B reference-model requirements

Before production Solidity:

- Model every function as a state transition.
- Enumerate every timestamp comparison and equality boundary.
- Explore all non-terminal resolution orders for maximum beneficiary count.
- Prove snapshot conservation with zero, tiny and maximum tested balances.
- Prove stale claim requests cannot cross owner or config epochs.
- Prove no permissionless action changes liveness.
- Prove terminal cannot unlock early.
- Generate traces for all four v3 P0 regressions.

## 37. Base Sepolia evidence pack

The pack must contain:

- Factory and vault addresses.
- Verified source and compiler settings.
- Creation and runtime bytecode hashes.
- Official test USDC address and chain ID.
- Complete transaction list from creation to settlement.
- Before/after balance table for owner, vault, every paid destination and executor.
- Proof that the executor received no vault asset.
- Primary, fallback and rollover boundary transactions.
- Recovery activation and veto traces.
- Config execution trace proving `lastSeen` unchanged.
- Reproduction commands that work without trusted backend access.

## 38. Mainnet release gates

No meaningful-value mainnet vault until all are true:

1. v3.1 is signed off.
2. Reference model and mutation evidence complete.
3. Solidity unit, fuzz, invariant and integration suites green.
4. Base Sepolia evidence independently reproduced.
5. Pinned and latest mainnet-fork USDC tests green.
6. Independent contract audit completed and findings remediated.
7. Source and bytecode verification automated.
8. Legal and sanctions workstreams reviewed.
9. Monitoring, relayer and incident runbooks tested.
10. Public product limits match contract reality.

## 39. Definition of done

- D1-D40 are implemented or explicitly enforced as product exclusions.
- I1-I16 pass under stateful fuzzing with mutation evidence.
- Four v3 P0 regression families remain permanently in CI.
- Every public function has state, authorization, boundary and revert tests.
- Every emitted event is indexed and rendered in the evidence UI.
- Base Sepolia full lifecycle is reproducible by an independent reviewer.
- Mainnet-fork tests cover current USDC implementation behavior.
- Exact deployed bytecode has an independent audit and public verification.
- No marketing claim exceeds the environmental guarantees in this document.

---

# Appendix A - V3 to V3.1 normative change summary

1. Replaced action-based liveness language with fresh-current-owner authorization.
2. Removed config execution from heartbeat-producing actions.
3. Removed transfer-failure-driven fallback.
4. Added explicit statement that Heirloom cannot detect beneficiary key loss.
5. Replaced simultaneous primary/fallback callability with exclusive timestamp phases.
6. Removed executor route choice; `executePayout` accepts an index only.
7. Added global `fallbackAt` and `rolloverAt` boundaries.
8. Added Unresolved, Paid and RolledOver beneficiary statuses.
9. Locked terminal until all non-terminal entries resolve.
10. Anchored terminal primary/fallback schedule to terminal unlock time.
11. Bound claim requests to liveness and config nonces.
12. Fully specified recovery request, quorum, delay, veto, expiry and activation.
13. Defined zero-entitlement and zero-snapshot behavior.
14. Defined exact token balance-delta validation and AccountingDeficit behavior.
15. Defined post-settlement excess destination.
16. Excluded custom signed vault actions from V1.
17. Closed D5 with conservative defaults and bounds.
18. Closed D6 by excluding an operator preset from V1.
19. Replaced D17 failure hierarchy with time-based destination scheduling.
20. Added D27-D40 and expanded formal invariants from 12 to 16.

# Appendix B - Primary technical references

- [ERC-20 Token Standard](https://eips.ethereum.org/EIPS/eip-20)
- [ERC-1271 Contract Signatures](https://eips.ethereum.org/EIPS/eip-1271)
- [Circle USDC contract addresses](https://developers.circle.com/stablecoins/usdc-contract-addresses)
- [Circle stablecoin EVM contracts](https://github.com/circlefin/stablecoin-evm)
- [Base transaction finality](https://docs.base.org/base-chain/network-information/transaction-finality)

# Appendix C - Sign-off

| Role | Required approval |
|---|---|
| Product owner | Confirms estate-split product, defaults, limits and user language. |
| Protocol engineer | Confirms state model, interfaces, equations and storage feasibility. |
| Security reviewer | Confirms threat model, invariants and test completeness. |
| Product designer | Confirms deadline comprehension and recovery/fallback warnings. |
| Legal counsel | Confirms launch jurisdiction, claims and operational model. |

**Stage 0A sign-off statement:**

> We accept that Heirloom reacts to inactivity rather than death; cannot detect key loss;
> depends on externally administered USDC; becomes irreversible at distribution start; and
> guarantees destination lock only through the exact v3.1 state machine and assumptions.

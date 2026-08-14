# Heirloom Internal Pre-Mainnet Security Review

**Review date:** 14 August 2026  
**Reviewed commit:** `9c4fb2b64b49114f86d402f800ad91b5367fe26d`  
**Review type:** Internal, adversarial pre-audit  
**Mainnet recommendation:** Blocked pending remediation and independent external sign-off

> This report is not an independent external audit. It was produced inside the implementation
> workflow and cannot replace a third-party auditor's conflict-free assessment. Its purpose is to
> find and remove issues before the external engagement and to give that auditor reproducible,
> commit-bound evidence.

## Executive summary

The reviewed Heirloom candidate has a strong destination-locked distribution model, exact token
delta checks, an irreversible distribution boundary and unusually substantial invariant evidence.
The review nevertheless found one high-severity control-plane ordering issue, one medium-severity
configuration footgun, one low-severity terminal-state hygiene issue and one low-severity coverage
weakness. No demonstrated path allowed an arbitrary permissionless caller to redirect funds to an
address of its choice.

| ID | Severity | Finding | Status at reviewed commit |
|---|---|---|---|
| H-01 | High | A permissionless config executor can invalidate a threshold-reached recovery request | Open |
| M-01 | Medium | Post-deployment config accepts the vault itself as a payout or recovery role | Open |
| L-01 | Low | Distribution leaves an unreachable pending config record in storage | Open |
| L-02 | Low | Stateful I10 uses a divisible snapshot and cannot exercise atomic-unit rounding | Open |
| I-01 | Informational | Deterministic deployment can be preempted only by deploying the exact intended vault | Accepted observation |

The candidate must not be deployed to Base mainnet until the accepted fixes are implemented, the
exact remediation commit is re-reviewed, all repository gates pass, and an independent auditor
signs the final source.

## Scope and method

Production scope:

- `src/HeirloomFactory.sol`
- `src/HeirloomVault.sol`
- `src/HeirloomTypes.sol`
- `src/interfaces/IHeirloomVault.sol`

Evidence scope included unit, fuzz, stateful invariant, mutation, Base USDC fork, deployment and web
transaction-construction tests. The review used twelve sequential lenses: architecture and trust,
authorization, state transitions, accounting, external calls and tokens, arithmetic and boundaries,
reentrancy and callbacks, denial of service and liveness, configuration and recovery races,
deployment and identity, test adequacy, and specification/implementation consistency.

Every reported finding survived manual source tracing and a concrete reproduction. Style issues and
unsupported hypotheses were excluded. A local orchestration sandbox could not access its normal
configuration directory or resolve the Base RPC, so the twelve lenses ran sequentially and the Base
fork was verified separately on the host. This is an execution-environment limitation, not evidence
of independent review.

## Baseline evidence

The reviewed commit was clean and matched `origin/main`. Before remediation:

- Formatting and compilation passed.
- 50 non-fork Forge entries passed, including a 10,000-run fuzz case.
- Five stateful groups completed 500,000 calls with zero unexpected handler reverts.
- All 16 production-source mutants were killed.
- Nine Base mainnet USDC fork cases passed in existing hosted/host evidence for the exact source.
- Vault runtime was 23,602 bytes, leaving 974 bytes below EIP-170.
- The compiled implementation runtime hash reproduced the Base Sepolia manifest:
  `0x3525b99ee637757d4e7b42c5c7a70c86b97f76dfd780527f359e259a9000bbc2`.
- Version ID, initializer storage slot, CREATE2 prediction and initial configuration hash reproduced
  the recorded deployment evidence.

## H-01: Threshold-reached recovery can lose to permissionless config execution

**Impact:** A guardian quorum may have approved the precommitted recovery owner, but any caller can
execute an already-mature configuration first. The config path deletes the recovery request. A
permissionless third party therefore chooses the ordering outcome between two security-sensitive
control-plane transitions and can deny a valid recovery attempt.

**Preconditions:** A config proposal is mature and unexpired; a recovery request has reached its
guardian threshold; the vault is Active; config execution lands before recovery activation.

**Evidence:** At the reviewed commit, `executeConfig()` unconditionally deletes any pending recovery
request after payload validation. The contract emits `RecoveryInvalidated(..., ConfigExecuted)`, so
the action is observable; the issue is transition priority, not silent state mutation.

**Required remediation:** Once `thresholdReached == true`, `executeConfig()` must revert. The current
owner may explicitly veto the recovery through a fresh owner authorization, or the recovery may
activate, expire and be cleared. A pre-threshold request may still be invalidated by a valid config
execution so a single guardian cannot freeze configuration.

**Required regression:** Exercise both interleavings: threshold reached blocks execution until owner
veto, while a pre-threshold request is invalidated by config execution.

## M-01: Vault self-address is accepted in security-critical config roles

**Impact:** After a vault exists, its owner can propose the vault address as a primary destination,
fallback destination, recovery address or guardian. An ERC-20 transfer to the vault itself does not
reduce the vault balance, so exact-delta enforcement reverts. A self-addressed terminal route can
make settlement permanently unreachable in that phase. Self recovery/guardian roles are also
incapable authorities.

**Preconditions:** The current owner signs a delayed configuration containing `address(vault)` and
the proposal executes. This is a dangerous misconfiguration, not a permissionless takeover.

**Evidence:** The reviewed validator rejected zero, duplicate and owner addresses but did not reject
`address(this)`. A transfer-to-self reproduction reverted with `UnexpectedTokenDelta` and left the
entitlement unresolved.

**Required remediation:** Reject `address(this)` for every beneficiary destination, the recovery
address and every guardian. Preserve the existing exact-delta check as defense in depth.

## L-01: Distribution leaves stale pending config state

**Impact:** An owner may propose config, later become inactive and enter ClaimRequested. When
distribution starts, configuration functions become permanently unavailable, but the proposal
record remains nonzero. This does not move funds or reopen configuration; it creates misleading and
unreachable state for clients and indexers.

**Required remediation:** At the validated irreversible boundary, delete any pending config and emit
`ConfigInvalidated`. Do not change the claim-bound config epoch during this cleanup.

## L-02: Stateful rounding assertion is weaker than the specification

**Impact:** The stateful I10 harness calculated the terminal base as its configured-share floor and
used a snapshot divisible by 10,000. It therefore passed without exercising the specification's
actual rule: terminal base is the snapshot remainder after all non-terminal floors. Production logic
was correct, but this test could not detect rounding regressions.

**Required remediation:** Use a snapshot not divisible by 10,000; define terminal base as
`snapshot - sum(nonTerminalEntitlements)`; assert it is at least the terminal configured-share floor
and that the total exactly conserves the snapshot. Add a deterministic atomic-unit rounding test and
positive-snapshot zero-entitlement test.

## I-01: Exact-intent deterministic deployment preemption

The factory salt binds owner, user salt and complete initial config. Another caller can submit the
same creation first, causing a later duplicate create to revert, but the resulting vault has the
intended owner, asset and config at the intended address. A different config produces a different
address. This is a bounded UX/griefing consideration, not demonstrated asset theft. The external
auditor should decide whether idempotent create semantics are worth the added code and interface
surface.

## Residual risks outside these findings

- Heirloom cannot detect death, incapacity, key loss or whether a recipient can later use received
  USDC.
- A compromised active owner can withdraw the vault balance.
- Guardian-threshold compromise can install only the precommitted recovery address after delay.
- Circle can pause, blacklist or upgrade USDC.
- Permissionless execution does not guarantee that a caller will be available or willing to pay gas.
- Public configuration reveals participant addresses and shares.

## Required re-verification

The remediation review must bind to an exact commit and repeat formatting, bytecode-size, full core
tests, 500,000-call stateful profile, gas snapshot, 16-source-mutant gate, Base mainnet USDC fork,
web transaction/render tests and a focused source-diff review. The independent auditor must review
both this report and the remediation diff and issue its own report; no repository author should mark
that external gate complete.

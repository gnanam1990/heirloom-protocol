# I1-I16 Invariant Mutation Matrix

## Result

**16 of 16 production-source mutants killed locally on 2026-08-14.**

Each mutant changes an exact anchor in `src/HeirloomVault.sol`, must compile successfully, and is
then run against one named invariant regression test. A mutant is counted as killed only when that
test reports a Foundry test failure. Compilation failures, harness errors and surviving mutants all
fail the gate.

The runner copies the repository into an isolated temporary directory. It never changes the source
worktree and removes the temporary copy after the run.

## Evidence matrix

| ID | Compiling production mutation | Killing regression test | Local result |
|---|---|---|---|
| I1 | `requestClaim()` rewrites `lastSeen` without owner authorization | `testI1_LastSeenChangesOnlyForOwnerAuthorizationOrRecovery` | Killed |
| I2 | Permissionless `executeConfig()` updates `lastSeen` | `testI2_PermissionlessConfigExecutionCannotCreateLiveness` | Killed |
| I3 | Claim request stores zero instead of the current `configNonce` | `testI3_ClaimRequestMovesNoAssetAndBindsCurrentEpochs` | Killed |
| I4 | Stale request rejection requires both epochs to differ | `testI4_DistributionRejectsAStaleRequestEpoch` | Killed |
| I5 | Primary payout destination becomes `msg.sender` | `testI5_PermissionlessCallerCannotAimOrResizePayout` | Killed |
| I6 | Primary remains valid at the exact fallback boundary | `testI6_ExactlyOneDestinationPhaseExistsAtFallbackBoundary` | Killed |
| I7 | Fallback remains valid at the exact rollover boundary | `testI7_PrimaryAndFallbackAreImpossibleAtRolloverBoundary` | Killed |
| I8 | Resolved-status guard is disabled | `testI8_NonTerminalEntitlementResolvesExactlyOnce` | Killed |
| I9 | Terminal unlocks after a single non-terminal payout | `testI9_TerminalCannotUnlockBeforeEveryNonTerminalResolves` | Killed |
| I10 | Configuration accepts total BPS below 10,000 | `testI10_EntitlementBpsMustConserveTheSnapshot` | Killed |
| I11 | Rollover subtracts its amount from `snapshotRemaining` | `testI11_RolloverRemainsInTerminalSnapshotExactlyOnce` | Killed |
| I12 | Exact-transfer check accepts an excessive sender debit | `testI12_InexactTransferRevertsAllResolutionAccounting` | Killed |
| I13 | Payout accounting subtracts one unit less than the outgoing amount | `testI13_SuccessfulPayoutTracksExactOutgoingDelta` | Killed |
| I14 | Settled vault retains one unit of `snapshotRemaining` | `testI14_SettlementIsCompleteTerminalAndSingleUse` | Killed |
| I15 | Recovery executor installs itself instead of the precommitted owner | `testI15_RecoveryInstallsOnlyPrecommittedOwnerAndInvalidatesEpochs` | Killed |
| I16 | Initialized vault discards the factory version ID | `testI16_FactoryAssetVersionAndRuntimeIdentityRemainVerifiable` | Killed |

The executable anchors and replacements are in `mutations/manifest.mjs`. The dedicated normal-source
tests are in `test/HeirloomInvariantMatrix.t.sol`.

## Reproduction

Run every invariant mutant:

```bash
./script/check-invariant-mutations.mjs --all
```

Run a focused subset while reviewing a finding:

```bash
./script/check-invariant-mutations.mjs --id I1,I4,I12
```

Expected final output:

```text
Mutation score: 16/16 killed
```

## Interpretation boundary

This proves that each named regression test detects one concrete violation of its mapped invariant.
It does not prove that the mutants are exhaustive, that no equivalent mutant exists, or that the
contracts are vulnerability-free. Stateful fuzzing, Base USDC fork compatibility and independent
review remain separate release gates.

# I1-I16 Stateful Invariant Matrix

## Result

All I1-I16 invariants pass under the CI profile: 1,000 runs times 100 randomized calls for each
of five stateful property groups. That is 500,000 handler calls per complete run. The handlers
report zero unexpected reverts, and Foundry shrinks any counterexample before reporting failure.

This gate complements, but does not replace, the one-to-one production-source mutation gate or an
independent security audit.

The stateful harness was introduced at source commit
`64d2c418ea6605bdaa8b585399088d2ede9bdfbe`. Production contract source and bytecode were not
changed by this milestone. The exact hosted run is
[GitHub Actions 31820092793](https://github.com/gnanam1990/heirloom-protocol/actions/runs/31820092793),
and the machine-readable record is `proof/i1-i16-stateful-64d2c41.json`.

## Stateful model

`test/HeirloomVaultInvariant.t.sol` creates three isolated vaults:

1. A control-plane vault that moves through owner activity, direct third-party transfers, claim,
   configuration and guardian-recovery sequences.
2. A distribution vault that moves across exact primary, fallback, rollover, terminal and settled
   phases while excess tokens may arrive at any time.
3. An inexact-transfer vault backed by a token that debits one extra unit from the sender, proving
   that failed exact-delta checks roll back the complete payout transition.

The primary handler exposes 14 bounded actions. It records ghost failure flags only after checking
the complete before/after state of successful transitions. The inexact-transfer handler repeatedly
attempts adversarial payouts against every beneficiary while checking token and vault rollback.

## Coverage map

| ID | Stateful assertion | Randomized actions and state |
|---|---|---|
| I1 | `lastSeen` and `livenessNonce` change only after owner authorization or completed recovery | Owner heartbeat/deposit/withdraw/cancel/veto/config actions versus time, claims, config execution, guardian actions and transfers |
| I2 | Every permissionless, guardian and direct-transfer action preserves liveness | Time advance, third-party transfer, claim, distribution start, config execution, recovery request/approval/expiry |
| I3 | Claim stores current liveness/config epochs and moves no asset | Permissionless claim after randomized liveness and config history |
| I4 | Distribution consumes exactly one current-epoch claim and snapshots the full balance | Challenge time advance and permissionless start after randomized cancellations, recovery and config changes |
| I5 | Caller cannot aim or resize beneficiary or terminal payouts | Random caller/index, derived phase, before/after balances for selected, excluded and caller addresses |
| I6 | Exactly one destination phase exists | Primary, exact `fallbackAt`, exact `rolloverAt` and arbitrary later timestamps |
| I7 | Payout is unavailable after rollover | Random payout and rollover attempts at and after `rolloverAt` |
| I8 | Each entitlement resolves once | Random pay/rollover ordering plus explicit second-resolution calls |
| I9 | Terminal stays locked until all non-terminal entries resolve | Mixed paid and rolled statuses with terminal attempts throughout |
| I10 | BPS entitlements conserve the snapshot | Every state after randomized payout ordering, using an exactly divisible snapshot |
| I11 | Rolled amounts remain in `snapshotRemaining` exactly once | Mixed payout/rollover paths and recomputed rolled-status sum |
| I12 | Inexact transfers change no balance, status or accounting | 100,000 stateful calls against the extra-debit token vault |
| I13 | Successful payouts match both outgoing balance delta and snapshot delta | Every primary/fallback payout plus excess-balance arrivals |
| I14 | Settled is terminal, complete and zero-remaining | Primary/fallback terminal settlement and post-settlement excess sweeps |
| I15 | Recovery installs only the committed owner and invalidates pending epochs atomically | Random guardian voting, expiry, owner veto and outsider activation |
| I16 | Factory, asset, version, registry and runtime identity remain permanent | Checked after every randomized sequence for control and distribution vaults |

## Reproduction

Run only the stateful suite at release intensity:

```bash
FOUNDRY_PROFILE=ci forge test --match-path test/HeirloomVaultInvariant.t.sol -vv
```

Run the complete non-fork protocol gate:

```bash
FOUNDRY_PROFILE=ci forge test --no-match-contract BaseMainnetUSDCForkTest
```

## Interpretation

Passing means the implemented randomized model did not find an I1-I16 violation across the stated
sequences and intensity. It does not prove correctness for unmodeled token behavior, EVM changes,
compiler defects, compromised owner/guardian keys or economic/product assumptions. Those remain
in scope for independent review and operational controls.

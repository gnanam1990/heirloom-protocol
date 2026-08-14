# Heirloom v3 to v3.1 - Change Log

## Release status

V3.1 is a normative protocol correction, not an editorial patch. V3 must not be used as the
Solidity implementation source after v3.1 sign-off.

## Blocking corrections

| ID | V3 defect | V3.1 correction |
|---|---|---|
| P0-1 | Permissionless config execution could create owner liveness. | Config execution never updates `lastSeen`; only fresh current-owner authorization or completed recovery can do so. |
| P0-2 | Recipient failure was inferred from ERC-20 transfer behavior. | Failure detection removed; destination changes are purely timestamp-based. |
| P0-3 | Executor could choose between simultaneously callable destinations. | Exactly one phase is valid; contract derives destination from time and status. |
| P0-4 | Terminal could be paid before later rollover accrual. | Terminal is locked until all non-terminal shares resolve and is paid once. |

## Major additions

- Claim requests bind to `livenessNonce` and `configNonce`.
- Non-terminal status is Unresolved, Paid or RolledOver.
- Terminal schedule begins only when terminal unlocks.
- Guardian recovery now includes request, quorum, delay, veto, expiry and atomic activation.
- Token transfers require exact balance deltas.
- Zero-entitlement and zero-snapshot behavior are defined.
- Smart-account ownership uses direct calls; custom signed vault actions are excluded.
- Human duration defaults and bounds are defined.
- Operator duration preset is excluded from V1.
- Decision register expanded from D1-D26 to D1-D40.
- Formal invariant set expanded to I1-I16.

## Migration rule

No deployed v3 vault exists. Stage 1 begins directly from v3.1. If an implementation was
privately started from v3, discard its interface assumptions and map every function back to
v3.1 before reuse.

# Heirloom v3.1-R1 External Audit Findings Register

**Audit tag:** `v3.1-r1-audit-candidate`  
**Audit commit:** `02fd2046c96ef1c4117d6ab637cb4052faab5c6f`  
**Provider:** Not selected  
**Status:** Waiting for independent engagement

This register is the project-side remediation ledger. It does not replace the auditor's report and
must never mark a finding verified without evidence from the independent reviewer.

## Engagement identity

| Field | Value |
|---|---|
| Legal provider | Pending |
| Statement of work | Pending |
| Lead reviewer | Pending |
| Additional reviewers | Pending |
| Review start/end | Pending |
| Draft report | Pending |
| Final report | Pending |
| Fix-review window | Required; pending confirmation |
| Publication terms | Pending |

## Finding states

`Reported -> Reproduced -> Fix proposed -> Regression proved -> Internally verified -> Auditor re-verified -> Closed`

`Risk acceptance proposed -> Release owner accepted -> Auditor recorded -> Accepted`

- Critical and High findings cannot be risk-accepted for a mainnet release.
- Medium and Low acceptance requires written release-owner rationale and must appear in the final
  external report.
- A fix is not closed because CI passes. The original independent reviewer must re-verify the exact
  remediation commit.
- Any production change outside the finding fix must be separately scoped or excluded from the
  remediation commit.

## Findings

| ID | Severity | Title | Invariant / asset at risk | Status | Reproduction | Remediation commit | Regression | Auditor re-verification |
|---|---|---|---|---|---|---|---|---|
| — | — | No external report delivered | — | Waiting | — | — | — | — |

## Remediation evidence required per finding

1. Original external report identifier and exact affected lines.
2. Locally reproduced failing transaction, test or state trace.
3. Root cause and the violated D1-D40 decision or I1-I16 invariant.
4. Minimal production diff with no unrelated refactor.
5. A regression that fails on the audit commit and passes on the remediation commit.
6. Relevant deterministic, fuzz, stateful, mutation, fork and UI/deployment checks rerun.
7. Hosted CI link bound to the remediation commit.
8. Independent reviewer response: verified, partially verified, not fixed or out of scope.

## Final release decision

| Gate | Status | Evidence |
|---|---|---|
| External report commit matches audit tag | Pending | — |
| No unresolved Critical or High findings | Pending | — |
| Medium/Low risks resolved or explicitly accepted | Pending | — |
| Remediation commit independently re-verified | Pending | — |
| All hosted CI, mutation and Base USDC fork gates pass | Pending | — |
| Base Sepolia deployment delta reviewed | Pending | — |
| Mainnet release owner approval | Blocked | — |

Until every gate above is complete, the valid status remains **pre-production; Base mainnet
blocked**.

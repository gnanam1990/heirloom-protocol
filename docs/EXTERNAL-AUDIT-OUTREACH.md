# Heirloom v3.1-R1 External Audit Outreach

**Status:** Ready for quote requests; no auditor engaged yet  
**Target:** Independent Solidity/EVM review before any Base mainnet deployment  
**Audit authority:** Annotated Git tag `v3.1-r1-audit-candidate-2`
**Resolved commit:** `7ea6617625615e41469e153bc19f020eeb692d4a`
**Repository:** Private; grant named reviewers read-only access after a quote is shortlisted

## Recommended procurement path

Request the same fixed-scope quote from three independent providers. Compare the named reviewers,
reviewer effort, start date, methodology, fix-review terms, report-publication terms and total price.
Do not select only by the lowest quote.

| Priority | Provider | Why it fits this scope | Official intake |
|---:|---|---|---|
| 1 | Cantina / Spearbit hybrid review | Dedicated protocol reasoning plus a broader researcher network; suitable for a compact but state-machine-heavy Solidity scope | [Talk to the Cantina team](https://cantina.xyz/web3) |
| 2 | Trail of Bits comprehensive code assessment | Strong match for invariant-driven review, fuzzing, atomic accounting and Base/Optimism-adjacent EVM assumptions | [Blockchain security services](https://trailofbits.com/services/blockchain/) |
| 3 | OpenZeppelin security audit | Established private smart-contract audit process and direct fit with the OpenZeppelin 5.7 dependency used by Heirloom | [Request a security audit](https://www.openzeppelin.com/request) |

After one private review and remediation, consider a time-boxed [Sherlock audit
contest](https://docs.sherlock.xyz/audits/protocols/how-it-works-for-protocols) as a second,
diverse-reviewer layer. A contest is not a substitute for the first reviewer owning the full threat
model and fix re-verification.

No current price or availability is assumed. Each provider should quote against the same frozen
scope. These official service pages were rechecked on 2026-08-15.

## Frozen review scope

The annotated audit tag is the authority. The reviewer must record the tag's resolved commit in the
statement of work and final report before review begins.

### Production code

| File | Lines | SHA-256 |
|---|---:|---|
| `src/HeirloomFactory.sol` | 88 | `456373f6ae289df7b973a6f483e3676962ff7168ca8063f84ab137ed536dd90a` |
| `src/HeirloomVault.sol` | 826 | `7f5e61cf51e80739e30315003a7c7f14c1d0f261d9d22115bec901e1baef7c71` |
| `src/HeirloomTypes.sol` | 100 | `98181688a1ee2234c94bef8781f9629b269184735d99d7884b6ca1427aa48285` |
| `src/interfaces/IHeirloomVault.sol` | 165 | `651f44819a90794d2b4597538f9567b9fb413639da1c64ecac2bcf7fa4621e78` |

The 1,179 physical lines include comments, events, interfaces and types. The provider should perform
its own source-line and complexity estimate rather than price from this count alone.

### Review-adjacent evidence

- `docs/INDEPENDENT-AUDIT-PACK.md` — threat model, I1-I16 and mandatory attack questions.
- `docs/HEIRLOOM-BASE-PRD-TDD-v3.1.md` — normative D1-D40 behavior.
- `docs/INTERNAL-PREMAINNET-AUDIT-2026-08-14.md` — prior internal findings.
- `docs/REMEDIATION-REVERIFICATION-2026-08-14.md` — internal remediation evidence.
- `test/` and `script/check-invariant-mutations.mjs` — unit, fuzz, stateful and mutation evidence.
- `test/BaseMainnetUSDCFork.t.sol` — Base USDC compatibility and issuer-control failure paths.
- `deployments/base-sepolia-02b0ea5-v3.1-r1.json` — R1 factory deployment identity.
- `deployments/base-sepolia-v3.1-r1-vault-0x21ea6a01.json` — funded R1 vault evidence.

### Required focus

1. Owner-liveness authorization and every way `lastSeen` or claim epochs can change.
2. Permissionless execution without caller-selected payout destination, amount, phase or order.
3. Exact timestamp equality at inactivity, challenge, primary, fallback and rollover boundaries.
4. Terminal-last conservation, atomic-unit rounding, zero entitlements and excess balances.
5. Atomic rollback for paused, blacklisted, reverting or inexact ERC-20 behavior.
6. Guardian recovery/configuration races, stale approvals and cross-epoch invalidation.
7. Minimal-clone initialization, deterministic salts, registry/version/runtime identity and replay.
8. Base USDC proxy/admin assumptions, direct transfers and post-snapshot accounting.

The external reviewer must independently reproduce or challenge the existing evidence. Passing CI,
an internal audit and mutation coverage are inputs to the review, not proof that no vulnerability
exists.

## Required commercial and technical deliverables

Ask every provider to state these items explicitly in its proposal:

- Named lead reviewer and review team, with relevant Solidity/state-machine work.
- Reviewer-days or person-weeks committed to manual review.
- Confirmed start date, review window and expected draft/final dates.
- Exact in-scope tag/commit and explicit out-of-scope list.
- Findings with severity, exploit preconditions, affected invariant and reproducible proof.
- Coverage statement for I1-I16 and every mandatory attack question in the audit pack.
- Review of deployed R1 runtime identity and Base USDC issuer/proxy assumptions.
- One remediation window and fix re-verification by the original reviewer.
- Final report bound to the remediated commit, with unresolved/accepted risks clearly marked.
- Permission and timing for public report publication before mainnet launch.
- Total quote, payment schedule, cancellation/rescheduling terms and any travel/token requirements.

Reject a proposal that excludes fix re-verification, does not name the reviewed commit, or treats
automated scanning as the complete review.

## Ready-to-send intake message

**Subject:** Independent Solidity audit request — Heirloom v3.1-R1 on Base

Hello,

We are requesting a quote and availability for an independent security review of Heirloom v3.1-R1,
a non-custodial Base USDC asset-continuity vault. After owner inactivity and a challenge period,
permissionless callers can advance a destination-locked distribution without selecting payout
destinations, amounts or phases.

The production Solidity scope is four files and 1,179 physical lines including comments and
interfaces. The core risk is state-machine and accounting correctness rather than line count. The
repository includes a normative PRD/TDD, 16 formal invariants, deterministic/fuzz/stateful tests,
16 source-mutation regressions, a Base mainnet USDC fork suite, an internal findings report and a
source-verified funded Base Sepolia R1 deployment.

There is no Base mainnet deployment. Mainnet is blocked until an independent report is delivered,
all findings are resolved or explicitly accepted, and the original reviewer re-verifies the fixes.
The repository is private; we can grant named reviewers read-only access after initial scoping.

Please provide:

1. Named reviewers and relevant Solidity/EVM experience.
2. Proposed reviewer effort, methodology, start date and delivery dates.
3. A fixed-scope quote, payment terms and rescheduling terms.
4. Confirmation that remediation re-verification and a final commit-bound report are included.
5. Your report-publication terms.

Audit authority: `v3.1-r1-audit-candidate-2`
Detailed scope: `docs/INDEPENDENT-AUDIT-PACK.md`

Thank you.

## Private repository access checklist

1. Obtain the provider's legal entity, statement of work and named GitHub usernames.
2. Give only named reviewers read-only repository access; never organization owner or admin access.
3. Require checkout of `v3.1-r1-audit-candidate-2`, not a moving `main` branch.
4. Share no wallet secrets, private keys, recovery material, RPC secrets or production credentials.
5. Use a dedicated communication channel for questions and record all scope decisions.
6. During review, make no audit-scope code changes. Put proposed fixes on a separate remediation
   branch after findings are delivered.
7. Revoke repository access after the final report and fix verification are complete, unless the
   signed agreement requires a longer retention period.

## Selection record

Complete this table after quotes arrive. Until then, no provider is selected.

| Provider | Named reviewers | Effort | Start | Draft/final | Fix review | Publication | Quote | Decision |
|---|---|---:|---|---|---|---|---:|---|
| Cantina / Spearbit | Pending | Pending | Pending | Pending | Required | Required | Pending | — |
| Trail of Bits | Pending | Pending | Pending | Pending | Required | Required | Pending | — |
| OpenZeppelin | Pending | Pending | Pending | Pending | Required | Required | Pending | — |

## Stop conditions

- Do not deploy to Base mainnet while procurement, audit or fix verification is pending.
- Do not describe an internal review, CI run, testnet deployment or contest as the required
  independent commit-bound audit.
- Never move an existing audit tag. If production or review-evidence scope changes, create a new
  immutable candidate tag and require the auditor to re-scope the delta.

## Candidate lineage

`v3.1-r1-audit-candidate` is retained as immutable historical evidence but is superseded. A later
randomized CI seed exposed that its stateful test model incorrectly required every successful
`startDistribution()` call to remain in `Distributing`; the specified zero-balance path settles
atomically instead. Production source hashes were unchanged, no external review had begun, and the
model was corrected with a deterministic regression before candidate 2 was frozen.

# Heirloom v3.1 Independent Audit Pack

## Release status

**Audit candidate; not approved for Base mainnet deployment.**

The external engagement must use the annotated Git tag `v3.1-r1-audit-candidate-2` as its immutable
review authority. The statement of work and report must record the commit resolved by
`git rev-list -n 1 v3.1-r1-audit-candidate-2`. Reviewers must not audit a moving `main` branch.

This package freezes the security claims, review scope, trust assumptions, reproduction steps and
release gates for Heirloom v3.1. The internal findings were remediated at commit
`50461c50f5dd9d8505d684286d75ba6e3ed58ee1`. Release candidate
`286b0e98d3372262410de54363759f17a1becb41` changes only the factory version preimage to
`HEIRLOOM_V3_1_R1` plus its test/runbook identity. The exact final delivery commit and the source
hashes below must be recorded in the external engagement and report.

Mainnet deployment remains prohibited until an independent reviewer signs the exact commit, all
accepted findings are remediated, the remediation is re-reviewed, and the release evidence in
`docs/PROOF-OF-WORK.md` is complete.

## Executive summary

Heirloom is a non-custodial Base USDC vault. After a configured inactivity and challenge period,
any caller may advance a destination-locked distribution. The caller cannot choose the amount,
destination, timing phase or terminal order. The owner can withdraw while the vault is Active;
distribution becomes irreversible at `startDistribution()`.

The review should prioritize five properties:

1. Only fresh authorization attributable to the current owner, or completed recovery, creates
   liveness.
2. Claim requests are bound to the current liveness and configuration epochs.
3. The contract derives exactly one valid destination phase from time; executors never aim funds.
4. Failed or inexact token transfers change no beneficiary or snapshot accounting.
5. Terminal settlement is last, once only, and consumes the entire remaining snapshot.

## Scope

### In-scope production contracts

| File | SHA-256 | Purpose |
|---|---|---|
| `src/HeirloomFactory.sol` | `456373f6ae289df7b973a6f483e3676962ff7168ca8063f84ab137ed536dd90a` | Versioned deterministic clone factory and registry |
| `src/HeirloomVault.sol` | `7f5e61cf51e80739e30315003a7c7f14c1d0f261d9d22115bec901e1baef7c71` | Asset custody, liveness, claim, recovery and distribution state machine |
| `src/HeirloomTypes.sol` | `98181688a1ee2234c94bef8781f9629b269184735d99d7884b6ca1427aa48285` | Configuration and state types |
| `src/interfaces/IHeirloomVault.sol` | `651f44819a90794d2b4597538f9567b9fb413639da1c64ecac2bcf7fa4621e78` | External interface and events |

The normative behavioral specification is `docs/HEIRLOOM-BASE-PRD-TDD-v3.1.md`, including
D1-D40 and I1-I16. The internal findings and remediation evidence are
`docs/INTERNAL-PREMAINNET-AUDIT-2026-08-14.md` and
`docs/REMEDIATION-REVERIFICATION-2026-08-14.md`. Tests are in scope as evidence, not as production
bytecode.

The release-identity delta and exact version ID are frozen in
`docs/RELEASE-CANDIDATE-V3.1-R1.md`.

### Review-adjacent scope

- `script/DeployBaseSepolia.s.sol`, deployment manifests and chain-ID/address gates.
- Base Sepolia deployed source and runtime identity.
- Base mainnet USDC fork compatibility at the pinned block and latest available block.
- Product transaction construction where it could change contract security assumptions.

### Out of scope

- Legal classification, inheritance law, tax treatment and beneficiary identity verification.
- Death, incapacity or lost-key detection; Heirloom observes only owner authorization and time.
- Availability of public RPCs, frontends, indexers, explorers, relayers or permissionless callers.
- Security of owner, guardian, recovery and beneficiary devices or wallet providers.
- Assets other than the single factory-bound Base USDC contract.
- A Base mainnet deployment, which does not yet exist and is not authorized by this pack.

## Architecture and trust boundaries

| Component or actor | Authority and assumptions |
|---|---|
| Owner | Controls Active funds, config proposals, heartbeat, claim veto and recovery veto. A compromised owner can withdraw Active funds. |
| Guardians | May approve only the precommitted recovery address. They cannot select a new owner or move funds directly. Threshold compromise can transfer ownership after the delay. |
| Recovery address | Fixed in configuration. It becomes owner only after a valid, delayed guardian recovery. |
| Permissionless caller | May request a mature claim, start a valid distribution, execute a beneficiary index, roll over an expired index and settle terminal. It must never choose payout economics or destination. |
| Beneficiaries | Receive public, configured entitlements. The vault cannot determine whether a recipient key is lost or a recipient contract can later move USDC. |
| Factory | Deploys immutable minimal clones bound to one USDC address and exposes registry/version evidence. It has no upgrade or vault-admin authority. |
| Circle USDC | External trusted dependency. Its admins can upgrade, pause or blacklist. Heirloom must revert atomically on failed/inexact transfers but cannot neutralize issuer control. |
| Base | Timestamps and ordering are supplied by Base. Exact equality boundaries must remain deterministic; temporary sequencing or RPC unavailability can delay but must not redirect execution. |

## State and asset model

```text
Active --requestClaim--> ClaimRequested --startDistribution--> Distributing --terminal--> Settled
   ^             |                 irreversible boundary
   |             +--fresh owner action or recovery invalidation--+
   +--------------------------------------------------------------+
```

- Owner withdrawals are allowed only while Active.
- `requestClaim()` moves no asset and records liveness/configuration epochs.
- `startDistribution()` snapshots the supported-token balance and is irreversible.
- Every non-terminal entitlement resolves exactly once as Paid or RolledOver.
- Terminal is payable only after all non-terminal entries resolve and receives the remaining
  snapshot exactly once.
- Direct transfers cannot be prevented. Pre-snapshot transfers enter the snapshot; post-snapshot
  excess is handled separately under D22/D39.

## Formal invariants under review

| ID | Required property |
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
| I10 | Non-terminal entitlements plus terminal base entitlement equal the snapshot. |
| I11 | Every rollover remains in `snapshotRemaining` and increases final terminal payment exactly once. |
| I12 | A failed or inexact transfer changes no beneficiary status or snapshot accounting. |
| I13 | Every payout reduces `snapshotRemaining` by exactly the outgoing token balance delta. |
| I14 | Settled implies zero snapshot remaining, all non-terminal entries resolved and terminal paid once. |
| I15 | Recovery installs only the precommitted address and atomically invalidates old claims, configs, approvals and nonces. |
| I16 | Vault version, asset, factory and runtime bytecode identity remain publicly verifiable. |

Five stateful property groups exercise every I1-I16 invariant across randomized control-plane,
recovery, distribution, excess-balance and inexact-transfer sequences. The coverage mapping and
reproduction command are documented in `docs/STATEFUL-INVARIANT-MATRIX.md`. A separate
deterministic matrix maps every I1-I16 invariant to a compiling production-source mutant and a
regression test that kills it; that evidence is documented in
`docs/INVARIANT-MUTATION-MATRIX.md`. Neither gate is an exhaustive formal proof or a replacement
for independent review.

## Mandatory attack questions

The review must attempt to demonstrate each attack, including exact timestamp boundaries and
cross-feature races:

- Can any non-owner action extend inactivity or revive a stale claim?
- Can permissionless config execution heartbeat, including when the executor happens to be owner?
- Can stale liveness/config epochs start distribution after owner activity, config change or recovery?
- Can a caller select primary versus fallback, pay after rollover, change amount, skip an unresolved
  beneficiary or settle terminal early?
- Can duplicate calls, reentrancy, zero entitlements, rounding or rollovers double-pay or strand the
  snapshot?
- Can paused, blacklisted, fee-on-transfer, rebasing, callback or otherwise inexact token behavior
  partially commit state?
- Can direct transfers manipulate liveness, snapshot accounting or post-settlement excess handling?
- Can guardians replace the precommitted recovery address, reuse approvals, bypass delay/expiry,
  survive owner veto, or revive claims/config after activation?
- Can configuration hashes or deterministic salts replay across vaults, owners, chains, versions or
  nonces?
- Can an implementation clone be initialized twice, impersonate the registry, upgrade, self-destruct
  or acquire admin authority?
- Can chain timestamp equality, integer truncation, array bounds, BPS conservation or maximum
  configuration size create an unreachable or prematurely reachable state?

## Known limitations and non-promises

- Heirloom cannot detect death, incapacity, key loss or recipient usability. Fallback eligibility is
  time-based only.
- A compromised owner can withdraw all funds while Active. Guardians are recovery governance, not a
  theft-prevention committee.
- Circle can pause, blacklist or upgrade Base USDC. The fork suite proves compatibility only with the
  tested implementation and block.
- Permissionless execution improves executability but does not guarantee that someone will pay gas.
- Public configuration reveals owner, guardian and beneficiary addresses and shares.
- Distribution cannot be cancelled after `startDistribution()`.
- The v3.1-R1 Base Sepolia factory is the audit-remediated candidate and has source/runtime evidence;
  the earlier funded vault remains historical pre-remediation evidence only.
- The R1 vault proves creation, identity, 20-USDC funding and owner-liveness advancement on the
  deployed bytecode. Its complete real-time claim lifecycle remains time-gated.
- Base Sepolia evidence is not a production audit and the funded testnet vault has not yet elapsed
  through its complete real-time lifecycle.

## Reproduction

Pinned toolchain: Foundry 1.7.1, Solidity 0.8.30, OpenZeppelin Contracts 5.7.0 and forge-std 1.16.2.

```bash
git submodule update --init --recursive
forge --version
forge fmt --check
forge build --sizes
FOUNDRY_PROFILE=ci forge test --no-match-contract BaseMainnetUSDCForkTest
forge snapshot --check --no-match-contract BaseMainnetUSDCForkTest
./script/check-invariant-mutations.mjs --all
./script/check-base-mainnet-usdc-fork.sh
cd apps/web
npm ci --ignore-scripts --no-audit --no-fund
npm run lint
npm test
```

The fork checker uses `BASE_MAINNET_RPC_URL` when set and otherwise the public Base RPC. The pinned
block proves a stable historical target; the latest fork is a compatibility alarm and may fail
legitimately if Circle upgrades USDC. Such a failure blocks release until reviewed and re-pinned.

## Base mainnet USDC compatibility evidence

The machine-readable evidence is `proof/base-mainnet-usdc-fork-49965293.json`.

| Field | Pinned value |
|---|---|
| Chain | Base mainnet, `8453` |
| Block | `49,965,293` |
| Block hash | `0x1330f00832a462062c4e218a5e02367c109f903234b9d55cd905f251f04856d8` |
| Timestamp | `2026-08-14T15:05:33Z` |
| USDC proxy | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| Implementation | `0x2Ce6311ddAE708829bc0784C967b7d77D19FD779` |
| Fork cases | 9 passed: identity, latest compatibility, exact deltas/direct transfer, pause, vault/primary/fallback/terminal blacklist paths and complete lifecycle |

`deal()` is used only to seed test balances. Approvals, `transferFrom`, transfers, pause,
blacklisting, proxy reads and implementation behavior execute against forked Base USDC bytecode.

## Required auditor output

The engagement should return:

1. Report bound to an exact repository commit and compiler/toolchain.
2. Findings with severity, exploit preconditions, invariant impact and reproducible proof.
3. Coverage statement for every I1-I16 invariant and every mandatory attack question above.
4. Explicit review of Base USDC proxy/admin risks and Heirloom's atomic failure behavior.
5. Remediation review bound to the final candidate commit.
6. Residual-risk and launch recommendation: approve, approve with accepted risks, or block.

Suggested severity: Critical for immediate arbitrary loss/control; High for conditional loss,
permanent claim denial or destination control; Medium for bounded accounting/liveness violation;
Low for defense-in-depth or operational mismatch; Informational for non-security observations.

## Mainnet release gates

- [ ] Exact audit delivery commit and source hashes confirmed.
- [x] I1-I16 each have test and compiling production-source mutation evidence.
- [ ] Independent report has no unresolved Critical or High finding.
- [ ] Accepted Medium/Low risks are documented by the release owner.
- [ ] Remediation commit is re-reviewed and all CI/fork gates pass.
- [x] Internal remediation re-verification and all local CI/fork gates pass.
- [ ] Latest Base USDC proxy, implementation, roles and runtime hashes are rechecked at release time.
- [ ] Mainnet deployment script, chain lock, official asset address and bytecode verification are
      separately reviewed.
- [ ] Deployment and verification manifests are committed before meaningful-value funding.
- [ ] UI warnings accurately describe inactivity, irreversibility, key loss, privacy and issuer risk.

Until every required gate is recorded, the only valid release status is **pre-production**.

Quote-request instructions, provider comparison criteria and the ready-to-send intake message are
in `docs/EXTERNAL-AUDIT-OUTREACH.md`.

The frozen tag, commit, source hashes, deployed R1 identity and candidate CI receipt are recorded in
the candidate-2 machine manifest under `proof/`. External findings and fix re-verification must be
tracked in `docs/EXTERNAL-AUDIT-FINDINGS-REGISTER.md` without converting internal verification into
external sign-off. The original `v3.1-r1-audit-candidate` remains immutable but is retired because a
later randomized run exposed a zero-snapshot assumption defect in its stateful test model. This was
a test-harness correction; the four production source hashes above did not change.

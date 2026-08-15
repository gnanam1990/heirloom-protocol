# Heirloom Remediation Re-Verification

**Review date:** 14 August 2026  
**Original reviewed commit:** `9c4fb2b64b49114f86d402f800ad91b5367fe26d`  
**Frozen findings commit:** `9bd28d426657523bf5add21c382075a4aa283a2e`  
**Remediation commit:** `50461c50f5dd9d8505d684286d75ba6e3ed58ee1`  
**Review type:** Internal remediation verification  
**External audit status:** Not complete

> This verifies that the repository's internally reported findings were remediated and that the
> executable gates pass. It is not an independent auditor's re-verification or mainnet approval.

## Outcome

All four actionable findings in the internal pre-mainnet review are closed in the remediation
commit. The exact remediation source passes the core, stateful, mutation, Base USDC fork, gas,
size, coverage and web gates. No new Critical, High or Medium finding survived the focused diff
review. Mainnet remains blocked until an independent third party reviews this exact candidate (or a
later documented commit), reviews the remediation diff, and issues its own signed report.

| Finding | Remediation | Regression evidence | Internal status |
|---|---|---|---|
| H-01 recovery/config ordering | `executeConfig` reverts after guardian threshold; pre-threshold invalidation remains allowed | `testThresholdReachedRecoveryBlocksConfigUntilOwnerVeto`, `testPreThresholdRecoveryIsInvalidatedByConfigExecution` | Closed |
| M-01 vault self-address config | Validator rejects the vault as any destination, recovery address or guardian | `testVaultCannotConfigureItselfAsDestinationOrRecoveryAuthority` | Closed |
| L-01 stale pending config | `startDistribution` clears and emits invalidation without changing the validated config epoch | `testDistributionInvalidatesPendingConfigWithoutChangingEpoch` | Closed |
| L-02 rounding coverage | Stateful snapshot is non-divisible; terminal remainder and atomic units are asserted | `testTerminalAbsorbsAtomicUnitRounding`, `testPositiveSnapshotZeroEntitlementsResolveAndTerminalReceivesRemainder` | Closed |

Additional boundary regressions cover `AccountingDeficit` and the maximum eight total
beneficiaries.

## Exact source identity

| File | SHA-256 |
|---|---|
| `src/HeirloomFactory.sol` | `339d41deab998ca60348cce5ec61e5e166fcdad431fefb216150f2e9182d1746` |
| `src/HeirloomVault.sol` | `7f5e61cf51e80739e30315003a7c7f14c1d0f261d9d22115bec901e1baef7c71` |
| `src/HeirloomTypes.sol` | `98181688a1ee2234c94bef8781f9629b269184735d99d7884b6ca1427aa48285` |
| `src/interfaces/IHeirloomVault.sol` | `651f44819a90794d2b4597538f9567b9fb413639da1c64ecac2bcf7fa4621e78` |

Compiled `HeirloomVault` implementation runtime hash:
`0x48bfce26a7b15d9f7ceaa248db541a41a5afdc84ca9ac27252ff8d6dc2770ab9`.

This differs from the existing Base Sepolia implementation because that deployment predates these
fixes. The existing testnet factory/vault is historical evidence only and must not be presented as
the remediated candidate. A new versioned Base Sepolia deployment is required before final external
audit handoff or mainnet planning.

## Re-verification gates

| Gate | Result |
|---|---|
| Formatting and whitespace | Pass |
| Optimized build and EIP-170 size | Pass; vault 23,818 bytes, 758-byte margin; factory 2,995 bytes |
| Core Forge profile | 58 entries passed |
| Deterministic cases | 52 passed |
| Fuzz | 10,000 runs passed |
| Stateful invariants | 5 groups x 1,000 runs x 100 calls = 500,000 calls; zero unexpected handler reverts |
| Production-source mutation | 16/16 mutants killed |
| Gas snapshot | Updated for the remediated bytecode and passes exact check |
| Base mainnet USDC fork | 9/9 passed, including latest identity compatibility and issuer failure paths |
| Coverage | Overall 92.07% lines, 90.51% statements, 55.96% branches, 88.51% functions |
| Vault coverage | 91.40% lines, 85.80% statements, 44.95% branches, 91.67% functions |
| Web transaction/render gate | Lint, production build and rendered-shell test pass |

Coverage uses Foundry's unoptimized instrumentation and emitted known anchor warnings; the coverage
run itself completed successfully. Release behavior and size were separately tested using the pinned
optimized configuration.

## Focused diff review

The re-review traced every changed production branch against its before/after state:

- The new recovery guard reads only the existing request and does not create liveness or mutate
  state on revert.
- Owner veto still deletes recovery through `_touchOwner`, after which the original proposal digest
  remains valid because `configNonce` is unchanged.
- Expired threshold requests can be explicitly cleared before config execution; no permanent freeze
  is introduced.
- Distribution clears pending config only after the claim's challenge and epoch checks, so a failed
  start cannot discard control-plane state.
- Self-address rejection runs on initialization and delayed config proposal/execution paths without
  changing storage layout.
- The terminal remainder assertion now covers atomic-unit truncation while production entitlement
  arithmetic remains unchanged.

The vault runtime grew by 216 bytes and remains below EIP-170. No storage variable, upgrade path,
admin role, arbitrary destination argument or new external call was added.

## Remaining release gates

- [ ] Independent auditor confirms exact source hashes and toolchain.
- [ ] Independent report resolves all Critical/High findings and records accepted lower risks.
- [ ] Independent auditor re-verifies the remediation diff.
- [x] Remediated version is redeployed and source-verified on Base Sepolia as v3.1-R1.
- [x] Hosted CI passed all four jobs on evidence commit `1f3b682` in
  [GitHub Actions run 31827335863](https://github.com/gnanam1990/heirloom-protocol/actions/runs/31827335863).
- [ ] Base USDC identity, proxy implementation and roles are refreshed immediately before release.
- [ ] Mainnet deployment script and manifests receive a separate review.

Until those gates close, the valid release status is **pre-production; mainnet blocked**.

# Proof of Work

This file is the human-readable index for reproducible engineering evidence. It must contain
only outputs produced by repository commands or verified deployment records. No test count,
coverage percentage, bytecode hash or deployment address may be entered manually without the
command that reproduces it.

## Milestone commits

| Milestone | Commit | Evidence |
|---|---|---|
| M0: repository and v3.1 freeze | `b1dc61c` | Private repository, pinned Foundry and dependency submodules, normative specification |
| M1: asset-control kernel | `791c545` | Deterministic clone factory, locked implementation, vault state machine, unit and fuzz tests |
| M2: adversarial verification | `cb57cbc` | Recovery/config boundary suite and four stateful accounting invariants |
| CI and gas gates | `0765cd3` | Pinned GitHub workflow and committed gas snapshot |
| M3: Base product UI | `0f9580d` | Base Account connector, responsive dashboard, production build and server-render test |
| M4 preparation: Base Sepolia | `eaf30c6` | Chain-locked deployment script, pinned official test USDC, manifest and runbook |
| M5 preparation: independent audit | `93ea145` | Pinned/latest Base mainnet USDC fork suite, machine-readable evidence and auditor handoff pack |
| M6: invariant mutation proof | `1f0c51a` | Dedicated I1-I16 regression matrix and 16 compiling production-source mutants killed |
| M7: stateful I1-I16 proof | `64d2c41` | Five property groups, 14 lifecycle actions and 500,000 randomized calls at CI intensity |
| M8: internal pre-mainnet review | `9bd28d4` | Commit-bound findings report with one High, one Medium, two Low and one informational observation |
| M9: audit remediation | `50461c5` | Recovery/config ordering, vault self-address, stale config and atomic rounding fixes with regressions |
| M10: hosted remediation re-verification | `1f3b682` | Exact remediation evidence commit passed protocol, mutation, Base USDC fork and web jobs |
| M11: v3.1-R1 release identity | `286b0e9` | Unique audit-remediated version ID for the next Base Sepolia factory |
| M12: v3.1-R1 Base Sepolia release | `ddfdf79` | Hosted CI-bound deployment, exact dry-run/live input match, runtime identity and source verification |
| M13: v3.1-R1 smoke vault | `a759889` | Predicted/deployed address match, registry/config/runtime identity and empty-vault manifest |
| M14: R1 product binding | `ee30657` | Dashboard, release activity, browser storage namespace and rendered proof pinned to the R1 factory/vault |
| M15: R1 funded vault | `4c64ee2` | 20-USDC approval/deposit receipts, exact post-funding state, hardened remaining-amount UI and release monitor |
| M16: historical external audit candidate | `02fd204` | Immutable but superseded candidate; later randomized CI exposed a zero-balance state-model assumption |
| M17: corrected external audit candidate | `7ea6617` | Zero-snapshot state-model correction, deterministic regression, unchanged production hashes and immutable candidate-2 tag |
| M18: Base mainnet release preparation | `34bbecd` | Updated multi-pass review, fail-closed deployment script, pinned deployer/nonce/factory/runtime identity, ten release-gate tests, runbook and fork-only evidence |
| M19: unaudited proposal release mode | `fd2d5db` | Separately named proposal entrypoint, explicit unaudited-risk acknowledgement, exact candidate binding, no-funding policy and fourteen release-gate tests |
| M20: Base mainnet proposal factory | `5ca330d` | Exact reviewed-input deployment, receipt/runtime/config verification, Blockscout source verification and explicit no-vault/no-funding status |
| M21: public proposal product surface | `b0e5fc3` | Read-only Base mainnet proof, completed dashboard controls, social metadata, render regressions and public Sites Version 2 |

## Current verified results

Verified locally from committed source on 2026-08-15:

| Gate | Result | Reproduction |
|---|---:|---|
| Deterministic tests | 66 passed | `FOUNDRY_PROFILE=ci forge test --no-match-contract BaseMainnetUSDCForkTest` |
| Fuzz test | 10,000 runs passed | `FOUNDRY_PROFILE=ci forge test --no-match-contract BaseMainnetUSDCForkTest` |
| Stateful invariants | 5 groups × 1,000 runs × 100 calls = 500,000 calls passed with zero unexpected handler reverts | `FOUNDRY_PROFILE=ci forge test --no-match-contract BaseMainnetUSDCForkTest` |
| Core Forge test entries | 73 passed | `FOUNDRY_PROFILE=ci forge test --no-match-contract BaseMainnetUSDCForkTest` |
| Base mainnet deployment gates | 14 passed: wrong chain, missing asset, wrong deployer, changed nonce, production audit/release gates, exact candidate/report hash, proposal approval/risk gates and pinned runtime identity | `FOUNDRY_PROFILE=ci forge test --match-contract DeployBaseMainnetTest` |
| I1-I16 source mutation gate | 16 of 16 compiling mutants killed | `./script/check-invariant-mutations.mjs --all` |
| Base mainnet USDC fork | 9 passed: pinned/latest compatibility, exact deltas, pause, vault/primary/fallback/terminal blacklist paths and lifecycle | `./script/check-base-mainnet-usdc-fork.sh` |
| Vault runtime size | 23,818 bytes; 758-byte EIP-170 margin | `forge build --sizes` |
| Factory runtime size | 2,995 bytes | `forge build --sizes` |
| Gas snapshot | Matches committed baseline | `forge snapshot --check` |
| Coverage snapshot | 92.07% lines; 90.51% statements; 55.96% branches; 88.51% functions | `forge coverage --report summary --no-match-contract BaseMainnetUSDCForkTest` |
| Web lint | Passed | `cd apps/web && npm run lint` |
| Web production build/render | Passed | `cd apps/web && npm test` |
| R1 funded-vault release monitor | Passed: registry, identity, Active state, 20 USDC balance, zero allowance, config, runtime and liveness nonce at least 3 | `./script/check-base-sepolia-vault.sh` |
| Browser QA | Desktop and 390 × 844 mobile; four navigation surfaces; no app-origin console errors | Manual local preview inspection |
| Public Sites deployment | Version 2 succeeded from exact source commit `b0e5fc3`; anonymous request and social image both returned HTTP 200 | [Heirloom public product](https://heirloom-base-v31.gnanasekaran-sekaree.chatgpt.site) |
| Hosted public-product CI | Passed all four jobs on exact Sites source commit `b0e5fc3`: protocol/gas, 16/16 source mutation, 9/9 Base USDC fork and web lint/build/render | [GitHub Actions run 31888690289](https://github.com/gnanam1990/heirloom-protocol/actions/runs/31888690289) |
| Prior hosted protocol CI | Passed on the pre-remediation M7 source commit; retained as historical evidence, not final-candidate approval | [GitHub Actions run 31820092793](https://github.com/gnanam1990/heirloom-protocol/actions/runs/31820092793) |
| Internal audit remediation | H-01, M-01, L-01 and L-02 closed internally on exact source commit `50461c5`; independent review still pending | `proof/internal-remediation-50461c5.json` |
| Hosted remediation CI | Passed all four jobs on exact evidence commit `1f3b682`: high-intensity protocol/gas, 16/16 source mutation, 9/9 Base mainnet USDC fork and web lint/build/render | [GitHub Actions run 31827335863](https://github.com/gnanam1990/heirloom-protocol/actions/runs/31827335863) |
| Hosted v3.1-R1 release CI | Passed all four jobs on exact deployment evidence commit `02b0ea5` | [GitHub Actions run 31829730293](https://github.com/gnanam1990/heirloom-protocol/actions/runs/31829730293) |
| Hosted v3.1-R1 funded-vault CI | Passed all four jobs on exact funded-evidence index commit `6cbe47d`: protocol/gas, 16/16 source mutation, Base USDC fork and web lint/build/render | [GitHub Actions run 31868538265](https://github.com/gnanam1990/heirloom-protocol/actions/runs/31868538265) |
| Historical audit-candidate CI | Passed all four jobs on immutable tag commit `02fd204`, but the candidate was later superseded when a different randomized seed exposed a test-model gap; it is not the current audit authority | [GitHub Actions run 31873954459](https://github.com/gnanam1990/heirloom-protocol/actions/runs/31873954459) |
| Randomized harness-gap detection | A later hosted seed correctly blocked release evidence because the model expected an empty vault to remain `Distributing` instead of atomically settling; exact seed reproduced locally before correction | [GitHub Actions run 31874342355](https://github.com/gnanam1990/heirloom-protocol/actions/runs/31874342355) |
| Hosted candidate-2 CI | Passed all four jobs on immutable audit commit `7ea6617`: 59 core entries, 500,000 stateful calls, gas, 16/16 source mutations, 9/9 Base mainnet USDC fork and web lint/build/render | [GitHub Actions run 31875147068](https://github.com/gnanam1990/heirloom-protocol/actions/runs/31875147068) |
| Hosted proposal-preparation CI | Passed all four jobs on exact release-proof commit `4ce1d86`: protocol/gas, 16/16 source mutation, Base USDC fork and web lint/build/render | [GitHub Actions run 31882181868](https://github.com/gnanam1990/heirloom-protocol/actions/runs/31882181868) |
| Base mainnet preparation | Production and explicitly unaudited proposal paths are separate and fail closed. Local fork mechanics passed with predicted factory `0x524A…eEcf`; deployer, nonce, factory and both runtime hashes were pinned before broadcast | `proof/base-mainnet-preparation-fork-50000700.json` |
| Base mainnet unaudited proposal factory | Success at block `50005381`; reviewed dry-run/live input exact match; runtime/config identity and both sources verified; factory vault count remains zero | [`0xf049…9270`](https://base.blockscout.com/tx/0xf04990ce21cbe3a3a78d3ae347c1250f10d23cccd6437aa5bdba090ddcce9270) |
| Hosted mainnet-deployment evidence CI | Passed all four jobs on exact evidence commit `5ca330d`: high-intensity protocol/gas, 16/16 source mutation, 9/9 Base USDC fork and web lint/build/render | [GitHub Actions run 31887270792](https://github.com/gnanam1990/heirloom-protocol/actions/runs/31887270792) |
| v3.1-R1 Base Sepolia factory deployment | Success at block `45483268`; reviewed dry-run/live input exact match; factory and implementation source verified | [`0x839c…f0732`](https://base-sepolia.blockscout.com/tx/0x839cb78414d54cd2e584d44b3f1062c43e7d6643741d6685c0d6218d8dff0732) |
| v3.1-R1 smoke vault creation | Success at block `45500300`; predicted address, registry, config and runtime identity match | [`0x8f68…6312`](https://base-sepolia.blockscout.com/tx/0x8f6879fa53eab91288f1c21597573fd17746c06b50b7d6f49e7fec0f04a66312) |
| v3.1-R1 20 USDC funding | Approval and two deposits verified; final state is Active with 20 USDC, zero owner balance/allowance and liveness nonce 3 | [`0x233b…f615`](https://base-sepolia.blockscout.com/tx/0x233bec0ae165905a397616be5222132225c368f1400765a47f8b26cb3433f615) |
| Historical Base Sepolia factory deployment | Success at block `45473582` | [`0x09ba…8fc7`](https://sepolia.basescan.org/tx/0x09ba628d90f17db61580d4a68d95948fc80321e3d01a4aa86fb8a1ff04cb8fc7) |
| Historical Base Sepolia owner vault creation | Success at block `45474409` | [`0x2d02…e077`](https://base-sepolia.blockscout.com/tx/0x2d02230c3c3fb7d70d704769b8ff08032f979db7be3ed06d60b147d9863ce077) |
| Historical Base Sepolia 20 USDC funding | Success at block `45475123` | [`0xec16…6e97`](https://base-sepolia.blockscout.com/tx/0xec16454ee3dc197f1df5f3c50ccd200d752c3728f2d0c5323d22fbfa5ca46e97) |

The original hosted workflow allocation blocker was cleared on 2026-08-14. The rerun completed
both the protocol and web jobs successfully.

## Base mainnet unaudited proposal-factory evidence

This transaction deploys public proposal proof only. It does not assert completion of an
independent audit and does not authorize a mainnet vault, deposit or user onboarding.

| Field | Verified value |
|---|---|
| Transaction | [`0xf049…9270`](https://base.blockscout.com/tx/0xf04990ce21cbe3a3a78d3ae347c1250f10d23cccd6437aa5bdba090ddcce9270), block `50005381`, success |
| Factory | [`0x524A…eEcf`](https://base.blockscout.com/address/0x524A95082dAD59fd8bf18FA27F89E3f55202eEcf) — source verified |
| Implementation | [`0xd746…3E80`](https://base.blockscout.com/address/0xd746Ca02cCFd0CA86d61eDd026810fdb8a0b3E80) — source verified and initializer locked |
| Bound asset | Official Base USDC `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| Deployment chain | `8453` |
| Version ID | `0x2307fc907cb859b0cb1ee608138ba346e301805703f489f8370477c357b73f56` |
| Dry-run/live input hash | `0xb8246c25cd4b0432ba8baf6513d2c8bd1ae8d34fd350ac08663ee4e7d3bb0498` — exact match |
| Factory runtime code hash | `0xbce0f26e2d6fc4eb3cfea3184113b7cdd01ae123b775ca6ac16938a6b18ec547` |
| Implementation runtime code hash | `0x48bfce26a7b15d9f7ceaa248db541a41a5afdc84ca9ac27252ff8d6dc2770ab9` |
| Factory vault count | `0` |
| Actual deployment fee | `0.000044855512122058 ETH` |
| Product authorization | External audit: no; production release: no; vault creation: no; user funding: no |

The machine-readable record is
[`deployments/base-mainnet-4ce1d86-v3.1-r1-proposal.json`](../deployments/base-mainnet-4ce1d86-v3.1-r1-proposal.json).

## Base Sepolia v3.1-R1 deployment evidence

The audit-remediated release was broadcast from hosted-CI-passed evidence commit
`02b0ea56041f9b892215f599777fdc9b5f0a5bb6` using deployer
`0xE8405844a45C209895afE2e49be6aA2C6C6202a6`.

| Field | Verified value |
|---|---|
| Transaction | [`0x839c…f0732`](https://base-sepolia.blockscout.com/tx/0x839cb78414d54cd2e584d44b3f1062c43e7d6643741d6685c0d6218d8dff0732), block `45483268`, success |
| Factory | [`0x935e5101d7563429BC152889603D3A17f466f4e4`](https://base-sepolia.blockscout.com/address/0x935e5101d7563429BC152889603D3A17f466f4e4) — source verified |
| Implementation | [`0x93C9a8b47d558F8C30F1e1754Ad2b050933F0FE3`](https://base-sepolia.blockscout.com/address/0x93C9a8b47d558F8C30F1e1754Ad2b050933F0FE3) — source verified |
| Bound asset | Circle Base Sepolia USDC `0x036CbD53842c5426634e7929541eC2318f3dCF7e` |
| Deployment chain | `84532` |
| Version ID | `0x2307fc907cb859b0cb1ee608138ba346e301805703f489f8370477c357b73f56` |
| Dry-run/live input hash | `0xddd96a3238f383db036ef8d7bcd97512a2985328024a876e3c3f0987aa7eb7eb` — exact match |
| Factory runtime code hash | `0x40f3e848262c7f28cef2b0f803785d2baea93fbae940beab023954378d744e0e` |
| Implementation runtime code hash | `0x48bfce26a7b15d9f7ceaa248db541a41a5afdc84ca9ac27252ff8d6dc2770ab9` — matches local artifact |
| Implementation initializer lock | Storage slot `29` contains the constructor-set initialized flag |

The machine-readable record is
[`deployments/base-sepolia-02b0ea5-v3.1-r1.json`](../deployments/base-sepolia-02b0ea5-v3.1-r1.json).

## Base Sepolia v3.1-R1 funded-vault evidence

The first R1 vault was created with the reviewed minimum schedule and the same destination set used
by the historical test configuration. It now holds 20 official Base Sepolia USDC. The funding trail
includes a 20 USDC approval, a one-atomic-unit preflight deposit caused by a temporary local gate
encoding defect, and a corrected deposit of the remaining `19,999,999` atomic units. No funds were
misdirected: both deposits reached this vault, and the final balance is exactly 20 USDC. Recording
the preflight transaction preserves the complete audit trail.

| Field | Verified value |
|---|---|
| Vault | [`0x21ea6A01Dd4A7C9F87Bdc80773fbB765FF6fa371`](https://base-sepolia.blockscout.com/address/0x21ea6A01Dd4A7C9F87Bdc80773fbB765FF6fa371) — verified EIP-1167 clone |
| Create | [`0x8f68…6312`](https://base-sepolia.blockscout.com/tx/0x8f6879fa53eab91288f1c21597573fd17746c06b50b7d6f49e7fec0f04a66312), block `45500300`, success |
| Prediction and registry | Predicted address matched; `vaultAt(0)` matched; `isVault(vault) == true` |
| Owner and asset | `0xE8405844a45C209895afE2e49be6aA2C6C6202a6`; official Base Sepolia USDC |
| Version | `0x2307fc907cb859b0cb1ee608138ba346e301805703f489f8370477c357b73f56` |
| Approval | [`0xaeb3…6df6`](https://base-sepolia.blockscout.com/tx/0xaeb3787db2c64bbf6c62d6cba71d6e8cacc5a24f2643765b82b823d4bc596df6), block `45501588`, 20 USDC Approval event |
| Atomic-unit preflight | [`0xef16…e1a`](https://base-sepolia.blockscout.com/tx/0xef168d573323b2cfaa76f24ea78129520562917f8aad342b3e7227f51d644e1a), block `45501693`, 1 atomic unit deposited |
| Remaining deposit | [`0x233b…f615`](https://base-sepolia.blockscout.com/tx/0x233bec0ae165905a397616be5222132225c368f1400765a47f8b26cb3433f615), block `45502623`, `19,999,999` atomic units deposited |
| State and balances | `Active` (`0`); vault `20 USDC`; owner `0 USDC`; allowance `0` |
| Liveness | `lastSeen = 1786773534`; nonce `3`; claim eligible `2026-11-13T05:58:54Z` |
| Config | One 40% standard route; one 60% terminal-last route; 2-of-3 guardians |
| Config hash | `0xbdc507dcc83036b928e0a56ee2040435e270a56b6ad1543d1d767e528da4e7ff` |
| Clone runtime hash | `0x100016fa0ed9ba6b03d57af1e255e6e1c475093a2dce36b8d407f9e0cc7b2aaa` |

The exact configuration, receipt, event-derived salts and post-create reads are recorded in
[`deployments/base-sepolia-v3.1-r1-vault-0x21ea6a01.json`](../deployments/base-sepolia-v3.1-r1-vault-0x21ea6a01.json).

This proves creation, funding and owner-liveness behavior on the deployed R1 bytecode. A complete
real-time claim-to-settlement run cannot finish before the configured inactivity, challenge and
destination windows elapse; time-warped local and fork suites cover those transitions meanwhile.

## Historical pre-remediation Base Sepolia evidence

The factory was deployed from clean source commit
`770b05bfd44799cbb780e7bf8ee91116eb5dd01a` using the funded deployer
`0xE8405844a45C209895afE2e49be6aA2C6C6202a6`.

This deployment predates audit remediation commit `50461c5`. It remains useful historical and UI
evidence but is not bytecode evidence for the remediated candidate.

| Field | Verified value |
|---|---|
| Factory | [`0x524A95082dAD59fd8bf18FA27F89E3f55202eEcf`](https://base-sepolia.blockscout.com/address/0x524A95082dAD59fd8bf18FA27F89E3f55202eEcf) — source verified |
| Implementation | [`0xd746Ca02cCFd0CA86d61eDd026810fdb8a0b3E80`](https://base-sepolia.blockscout.com/address/0xd746Ca02cCFd0CA86d61eDd026810fdb8a0b3E80) — source verified |
| Bound asset | Circle Base Sepolia USDC `0x036CbD53842c5426634e7929541eC2318f3dCF7e` |
| Deployment chain | `84532` |
| Version ID | `0x7cd4187df3151f8b6dba7f8b29a43eb0d551f30262c0c0885dd40f776328670f` |
| Factory runtime code hash | `0x2f249b59d9d8b67ba29af37bc000be9168eb022c78ce84807c6b9ce3cfe0d5b8` |
| Implementation runtime code hash | `0x3525b99ee637757d4e7b42c5c7a70c86b97f76dfd780527f359e259a9000bbc2` |
| Implementation initializer lock | Storage slot `29` contains the constructor-set initialized flag |

The machine-readable record is
[`deployments/base-sepolia-770b05b.json`](../deployments/base-sepolia-770b05b.json).

## Base Sepolia funded owner-vault evidence

The first owner vault was created through the live product UI and funded with 20 official
Base Sepolia USDC. All values below were reproduced from Base Sepolia RPC receipts, event logs
and contract reads after the deposit transaction.

| Field | Verified value |
|---|---|
| Vault | [`0x45004e3a5992606201B53Cd0FBab7f9439B4476C`](https://base-sepolia.blockscout.com/address/0x45004e3a5992606201B53Cd0FBab7f9439B4476C) |
| Owner | `0xE8405844a45C209895afE2e49be6aA2C6C6202a6` |
| Factory registry | `isVault(vault) == true` |
| Create | [`0x2d02…e077`](https://base-sepolia.blockscout.com/tx/0x2d02230c3c3fb7d70d704769b8ff08032f979db7be3ed06d60b147d9863ce077), block `45474409`, success |
| Approve 20 USDC | [`0x49e3…d617`](https://base-sepolia.blockscout.com/tx/0x49e3e654c5b8b7ddf1fdb907920a8cc65a7d258f025d0a5a8753be266269d617), block `45474672`, success |
| Deposit 20 USDC | [`0xec16…6e97`](https://base-sepolia.blockscout.com/tx/0xec16454ee3dc197f1df5f3c50ccd200d752c3728f2d0c5323d22fbfa5ca46e97), block `45475123`, success |
| Vault state | `Active` (`0`) |
| Vault balance | `20,000,000` atomic units = `20 USDC` |
| Owner balance | `0 USDC` |
| Remaining allowance | `0 USDC` |
| Liveness | `lastSeen = 1786718534`; nonce `2`; claim eligible `2026-11-12T14:42:14Z` |
| Config | One 40% standard route; one 60% terminal route; 2-of-3 guardians |
| Timing | 90-day inactivity; 7-day challenge; 30-day primary/fallback windows |
| Config hash | `0xbdc507dcc83036b928e0a56ee2040435e270a56b6ad1543d1d767e528da4e7ff` |
| Clone runtime hash | `0xc20bd075c8734260925eaf1f285e15f554734510cc81c3a3b45bcda05680bed2` |

The exact destinations, guardians, timing values, event data, receipts and post-deposit reads
are recorded in
[`deployments/base-sepolia-vault-0x45004e3a.json`](../deployments/base-sepolia-vault-0x45004e3a.json).

## Reproduction

```bash
git submodule update --init --recursive
forge --version
forge fmt --check
forge build --sizes
forge test -vv
FOUNDRY_PROFILE=ci forge test --no-match-contract BaseMainnetUSDCForkTest
forge snapshot --check --no-match-contract BaseMainnetUSDCForkTest
./script/check-invariant-mutations.mjs --all
./script/check-base-mainnet-usdc-fork.sh
```

Frontend reproduction:

```bash
cd apps/web
npm ci --ignore-scripts --no-audit --no-fund
npm run lint
npm test
```

## Evidence policy

- CI must run on every pull request and every push to `main`.
- `main` must remain releasable; unfinished work uses branches.
- Every security fix references a failing regression test.
- Base Sepolia and mainnet manifests are separate and chain-ID checked.
- Mainnet deployment is prohibited until the audit gate is recorded here.

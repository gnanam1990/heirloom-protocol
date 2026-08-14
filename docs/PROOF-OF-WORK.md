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

## Current verified results

Verified locally from clean committed source on 2026-08-14:

| Gate | Result | Reproduction |
|---|---:|---|
| Deterministic tests | 28 passed | `FOUNDRY_PROFILE=ci forge test` |
| Fuzz test | 10,000 runs passed | `FOUNDRY_PROFILE=ci forge test` |
| Stateful invariants | 4 × 1,000 runs × 100 calls passed | `FOUNDRY_PROFILE=ci forge test` |
| Total Forge test entries | 33 passed | `FOUNDRY_PROFILE=ci forge test` |
| Vault runtime size | 23,602 bytes; 974-byte EIP-170 margin | `forge build --sizes` |
| Factory runtime size | 2,995 bytes | `forge build --sizes` |
| Gas snapshot | Matches committed baseline | `forge snapshot --check` |
| Coverage snapshot | 84.42% lines; 81.40% statements; 38.98% branches; 80.88% functions | `forge coverage --report summary` |
| Web lint | Passed | `cd apps/web && npm run lint` |
| Web production build/render | Passed | `cd apps/web && npm test` |
| Browser QA | Desktop and 390 × 844 mobile; four navigation surfaces; no console warnings/errors | Manual local preview inspection |
| Private Sites deployment | Version 1 succeeded | `https://heirloom-base-v31.gnanasekaran-sekaree.chatgpt.site` |
| Hosted protocol CI | Passed: protocol and web jobs | [GitHub Actions run 31803767578](https://github.com/gnanam1990/heirloom-protocol/actions/runs/31803767578) |
| Base Sepolia factory deployment | Success at block `45473582` | [`0x09ba…8fc7`](https://sepolia.basescan.org/tx/0x09ba628d90f17db61580d4a68d95948fc80321e3d01a4aa86fb8a1ff04cb8fc7) |

The original hosted workflow allocation blocker was cleared on 2026-08-14. The rerun completed
both the protocol and web jobs successfully.

## Base Sepolia deployment evidence

The factory was deployed from clean source commit
`770b05bfd44799cbb780e7bf8ee91116eb5dd01a` using the funded deployer
`0xE8405844a45C209895afE2e49be6aA2C6C6202a6`.

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

## Reproduction

```bash
git submodule update --init --recursive
forge --version
forge fmt --check
forge build --sizes
forge test -vv
FOUNDRY_PROFILE=ci forge test
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

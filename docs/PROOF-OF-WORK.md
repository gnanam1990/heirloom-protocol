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

## Current verified results

Verified locally from clean committed source on 2026-08-14:

| Gate | Result | Reproduction |
|---|---:|---|
| Deterministic tests | 25 passed | `FOUNDRY_PROFILE=ci forge test` |
| Fuzz test | 10,000 runs passed | `FOUNDRY_PROFILE=ci forge test` |
| Stateful invariants | 4 × 1,000 runs × 100 calls passed | `FOUNDRY_PROFILE=ci forge test` |
| Total Forge test entries | 30 passed | `FOUNDRY_PROFILE=ci forge test` |
| Vault runtime size | 23,602 bytes; 974-byte EIP-170 margin | `forge build --sizes` |
| Factory runtime size | 2,995 bytes | `forge build --sizes` |
| Gas snapshot | Matches committed baseline | `forge snapshot --check` |
| Web lint | Passed | `cd apps/web && npm run lint` |
| Web production build/render | Passed | `cd apps/web && npm test` |
| Browser QA | Desktop and 390 × 844 mobile; four navigation surfaces; no console warnings/errors | Manual local preview inspection |
| Private Sites deployment | Version 1 succeeded | `https://heirloom-base-v31.gnanasekaran-sekaree.chatgpt.site` |

The GitHub workflow was triggered on commit `0765cd3`, but GitHub did not allocate a runner because
the account reported a billing or spending-limit problem. No workflow step ran, so this is an
external automation blocker rather than a test failure. Local pinned commands above remain green;
the hosted check must be rerun after the account billing limit is corrected.

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

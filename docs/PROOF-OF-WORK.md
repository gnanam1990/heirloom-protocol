# Proof of Work

This file is the human-readable index for reproducible engineering evidence. It must contain
only outputs produced by repository commands or verified deployment records. No test count,
coverage percentage, bytecode hash or deployment address may be entered manually without the
command that reproduces it.

## Milestone commits

| Milestone | Scope | Required evidence |
|---|---|---|
| M0 | Repository and v3.1 freeze | Private GitHub repository, pinned toolchain, signed specification |
| M1 | Asset-control kernel | Build, unit tests, contract sizes, ABI diff |
| M2 | Adversarial verification | Fuzz tests, invariant tests, mutation evidence, coverage |
| M3 | Base product UI | Typecheck, production build, responsive screenshots, accessibility checks |
| M4 | Base Sepolia | Verified contracts, bytecode hashes, full lifecycle transaction table |
| M5 | Mainnet candidate | Independent audit, remediation commit, reproducible release tag |

## Reproduction

```bash
git submodule update --init --recursive
forge --version
forge fmt --check
forge build --sizes
forge test -vv
FOUNDRY_PROFILE=ci forge test
```

Frontend commands will be added with the first UI milestone.

## Evidence policy

- CI must run on every pull request and every push to `main`.
- `main` must remain releasable; unfinished work uses branches.
- Every security fix references a failing regression test.
- Base Sepolia and mainnet manifests are separate and chain-ID checked.
- Mainnet deployment is prohibited until the audit gate is recorded here.

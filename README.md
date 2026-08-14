# Heirloom Protocol

Heirloom is a non-custodial asset-continuity vault for Base. It converts prolonged owner
inactivity into a deterministic, challengeable and permissionlessly executable USDC
distribution without giving the executor payout authority.

## Status

**Pre-production. Base Sepolia first. No mainnet asset deployment before an independent audit
and remediation.**

The normative implementation source is
[`docs/HEIRLOOM-BASE-PRD-TDD-v3.1.md`](docs/HEIRLOOM-BASE-PRD-TDD-v3.1.md).

## Security constitution

1. Only fresh current-owner authorization creates liveness.
2. Fallback and rollover are timestamp-derived, never failure-detected.
3. Permissionless executors cannot choose a payout route.
4. Terminal is paid once, after every non-terminal entitlement resolves.
5. Claim requests bind to liveness and configuration epochs.
6. Deployed vaults have no admin, pause or upgrade authority.

## Repository proof

The project is delivered through reviewable milestone commits. Current evidence includes 30
tests, 10,000 fuzz runs per CI fuzz case and four stateful invariants. CI publishes:

- Build and test results.
- Unit, fuzz and stateful invariant evidence.
- Coverage and gas reports.
- Runtime and creation bytecode hashes.
- Base Sepolia deployment manifests and explorer links.
- Reproduction commands for every claimed property.

See [`docs/PROOF-OF-WORK.md`](docs/PROOF-OF-WORK.md).

## Pinned toolchain

- Foundry 1.7.1
- Solidity 0.8.30
- OpenZeppelin Contracts 5.7.0
- forge-std 1.16.2

Dependencies are pinned as Git submodules. Initialize with:

```bash
git submodule update --init --recursive
```

## Local verification

```bash
forge fmt --check
forge build --sizes
forge test
FOUNDRY_PROFILE=ci forge test
```

Fork tests require `BASE_MAINNET_RPC_URL`. Deployment uses a hardware wallet or Foundry
keystore; raw private keys are never stored in this repository.

## Product UI

The Base-themed owner dashboard lives in `apps/web`. It includes responsive owner, beneficiary,
security, activity and public-proof surfaces plus a Base Account connector for passkey-backed
wallet onboarding.

```bash
cd apps/web
npm ci
npm run lint
npm test
```

Displayed vault values are clearly marked as interface-preview data until the verified Base
Sepolia factory address is configured.

## Release track

```text
v3.1 specification
    -> executable model
    -> contract implementation
    -> Base Sepolia evidence
    -> independent audit and remediation
    -> guarded Base mainnet release
```

## License

All rights reserved while the protocol is under private development. Contract licensing will
be selected before public source verification.

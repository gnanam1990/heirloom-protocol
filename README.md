# Heirloom Protocol

Heirloom is a non-custodial asset-continuity vault for Base. It converts prolonged owner
inactivity into a deterministic, challengeable and permissionlessly executable USDC
distribution without giving the executor payout authority.

## Status

**Pre-production v3.1-R1 audit-remediated candidate, source verified on Base Sepolia. No mainnet
asset deployment before an independent external audit and remediation re-verification.**

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

The project is delivered through reviewable milestone commits. Current evidence includes 69 core
test entries, nine Base mainnet USDC fork cases, 10,000 fuzz runs per CI fuzz case, five stateful
I1-I16 coverage groups and 16 of 16 killed production-source mutants. CI publishes:

- Build and test results.
- Unit, fuzz and stateful invariant evidence.
- I1-I16 source-mutation evidence.
- Coverage and gas reports.
- Runtime and creation bytecode hashes.
- Base Sepolia deployment manifests and explorer links.
- Reproduction commands for every claimed property.

See [`docs/PROOF-OF-WORK.md`](docs/PROOF-OF-WORK.md).

The current R1 testnet factory is
[`0x935e5101d7563429BC152889603D3A17f466f4e4`](https://base-sepolia.blockscout.com/address/0x935e5101d7563429BC152889603D3A17f466f4e4).
Its deployment manifest is
[`deployments/base-sepolia-02b0ea5-v3.1-r1.json`](deployments/base-sepolia-02b0ea5-v3.1-r1.json).

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
forge test --no-match-contract BaseMainnetUSDCForkTest
FOUNDRY_PROFILE=ci forge test --no-match-contract BaseMainnetUSDCForkTest
./script/check-invariant-mutations.mjs --all
./script/check-base-mainnet-usdc-fork.sh
```

Run `./script/check-base-mainnet-usdc-fork.sh` for the pinned and latest Base USDC suite. It uses
`BASE_MAINNET_RPC_URL` when supplied and otherwise the public Base RPC. Deployment uses a hardware
wallet or Foundry keystore; raw private keys are never stored in this repository.

The independent review handoff is
[`docs/INDEPENDENT-AUDIT-PACK.md`](docs/INDEPENDENT-AUDIT-PACK.md).
The quote-request and private-access workflow is
[`docs/EXTERNAL-AUDIT-OUTREACH.md`](docs/EXTERNAL-AUDIT-OUTREACH.md).
The remediation ledger is
[`docs/EXTERNAL-AUDIT-FINDINGS-REGISTER.md`](docs/EXTERNAL-AUDIT-FINDINGS-REGISTER.md).

The fail-closed Base mainnet preparation path is
[`docs/BASE-MAINNET-RUNBOOK.md`](docs/BASE-MAINNET-RUNBOOK.md). It supports dry-run evidence but
cannot authorize or replace the required independent audit and release-owner approval.

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

The dashboard is pinned to the R1 factory and verified owner vault. Funding, allowance, liveness,
routing and recovery state are reconstructed from public contract reads. The R1 vault holds 20
official Base Sepolia USDC; its approval, deposits, final zero allowance and liveness nonce are
recorded in the release-vault manifest. This is funded testnet evidence, not a completed real-time
claim lifecycle or a production audit.

## Base Builder proposal

The reviewer-ready proposal package is intentionally scoped to the Base Sepolia prototype:

- [`docs/BASE-BUILDER-GRANT-PROPOSAL.md`](docs/BASE-BUILDER-GRANT-PROPOSAL.md) — application narrative, evidence, risks, milestones and form-ready copy.
- [`docs/BASE-GRANT-ONE-MINUTE-DEMO.md`](docs/BASE-GRANT-ONE-MINUTE-DEMO.md) — exact 60-second reviewer walkthrough and recording checklist.
- [`outputs/Heirloom_Base_Proposal_Deck.pptx`](outputs/Heirloom_Base_Proposal_Deck.pptx) — shareable Base-themed proposal deck.

The grant nomination has not been submitted. A public unauthenticated demo URL, public one-minute
video and owner-controlled application identity fields are still required. Mainnet remains outside
the proposal scope until independent audit, remediation and re-verification are complete.

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

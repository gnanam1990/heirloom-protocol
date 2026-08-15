# Heirloom — Base Reviewer Information Pack

**Prepared:** 2026-08-15  
**Project:** Heirloom  
**Category:** Payments / Stablecoins; non-custodial asset continuity  
**Base Builder Code:** `bc_dsenshfx`

## Executive summary

Heirloom is a non-custodial USDC continuity vault for Base. An owner precommits beneficiaries,
fallback destinations, guardians and time windows. If the owner stops producing fresh wallet
authorization for the configured inactivity period, anyone can advance a challengeable
distribution—but the caller cannot choose the recipient, amount or valid destination phase.

Heirloom observes authorization and time; it does not claim to detect death, incapacity or key
loss. The current public product is a working Base Sepolia proposal prototype with a funded test
vault, source-verified contracts, an open-source Base-themed interface and reproducible security
evidence.

## Start here

| Resource | Link | What it shows |
|---|---|---|
| Live product | [Open Heirloom](https://heirloom-protocol-production.up.railway.app) | Public Base-themed product and onchain evidence surfaces |
| Interactive product walkthrough | [Open the 60-second demo](https://heirloom-protocol-production.up.railway.app/demo) | Text-led HTML walkthrough with chapters, controls and optional music; no wallet required |
| Public source | [GitHub repository](https://github.com/gnanam1990/heirloom-protocol) | MIT-licensed protocol, application, tests, deployment manifests and evidence |
| Proposal deck | [Heirloom Base proposal deck](https://github.com/gnanam1990/heirloom-protocol/blob/main/outputs/Heirloom_Base_Proposal_Deck.pptx) | Shareable Base-themed presentation |
| Grant narrative | [Base Builder Grant proposal](https://github.com/gnanam1990/heirloom-protocol/blob/main/docs/BASE-BUILDER-GRANT-PROPOSAL.md) | Problem, product, differentiation, milestones, metrics and risks |

### Product-video alternative

A conventional narrated video is not currently provided. The canonical demonstration is the
[interactive 60-second walkthrough](https://heirloom-protocol-production.up.railway.app/demo).
It runs directly in the browser, uses real product captures and public explorer evidence, and lets
reviewers pause, seek or jump to any chapter without creating an account or connecting a wallet.

## Product mechanics

1. An owner creates and funds a vault with precommitted recipients and time windows.
2. Fresh authorization attributable to the current owner extends the liveness clock.
3. After inactivity, any account can request a claim; requesting a claim moves no assets.
4. A challenge period lets fresh owner activity cancel the request.
5. If unchallenged, the contract snapshots the balance and distribution becomes irreversible.
6. Time selects exactly one destination phase: primary, fallback or rollover.
7. Terminal settlement occurs once, after every non-terminal entitlement is resolved.

This separates permissionless execution from payout authority: a third party may pay gas to
advance the committed plan, but cannot aim or resize the payout.

## Technical and security documentation

| Document | Link |
|---|---|
| Normative PRD + TDD v3.1 | [Architecture, state machine, decisions and 16 invariants](https://github.com/gnanam1990/heirloom-protocol/blob/main/docs/HEIRLOOM-BASE-PRD-TDD-v3.1.md) |
| Proof of work | [Milestone commits, test results and deployment receipts](https://github.com/gnanam1990/heirloom-protocol/blob/main/docs/PROOF-OF-WORK.md) |
| Release candidate | [v3.1-R1 identity and Base Sepolia verification](https://github.com/gnanam1990/heirloom-protocol/blob/main/docs/RELEASE-CANDIDATE-V3.1-R1.md) |
| Reviewer walkthrough specification | [Exact 60-second sequence and evidence sources](https://github.com/gnanam1990/heirloom-protocol/blob/main/docs/BASE-GRANT-ONE-MINUTE-DEMO.md) |
| Independent-audit handoff | [Scope, threat model and reproduction commands](https://github.com/gnanam1990/heirloom-protocol/blob/main/docs/INDEPENDENT-AUDIT-PACK.md) |
| Internal mainnet-readiness review | [Verified findings and explicit external-audit boundary](https://github.com/gnanam1990/heirloom-protocol/blob/main/docs/PR-REVIEW-MAINNET-READINESS-2026-08-15.md) |

## Public onchain evidence

| Evidence | Link | Status |
|---|---|---|
| Base Sepolia v3.1-R1 factory | [0x935e…f4e4](https://base-sepolia.blockscout.com/address/0x935e5101d7563429BC152889603D3A17f466f4e4) | Source verified |
| Base Sepolia implementation | [0x93C9…0FE3](https://base-sepolia.blockscout.com/address/0x93C9a8b47d558F8C30F1e1754Ad2b050933F0FE3) | Source verified; initializer locked |
| Funded Base Sepolia vault | [0x21ea…371](https://base-sepolia.blockscout.com/address/0x21ea6A01Dd4A7C9F87Bdc80773fbB765FF6fa371) | Active; funded with 20 official testnet USDC |
| Base mainnet proposal factory | [0x524A…eEcf](https://base.blockscout.com/address/0x524A95082dAD59fd8bf18FA27F89E3f55202eEcf) | Source verified; proposal proof only; zero vaults and no user funds |
| Base mainnet deployment receipt | [0xf049…9270](https://base.blockscout.com/tx/0xf04990ce21cbe3a3a78d3ae347c1250f10d23cccd6437aa5bdba090ddcce9270) | Successful receipt with pinned runtime/config identity |

## Reproducible engineering evidence

- `73` core Forge test entries plus `9` Base mainnet USDC fork cases.
- `10,000` fuzz runs for the CI fuzz case.
- Five stateful invariant groups covering `500,000` randomized lifecycle calls per
  high-intensity run.
- `16/16` compiling production-source mutants killed across invariants I1-I16.
- `92.07%` line coverage and `90.51%` statement coverage in the recorded snapshot.
- Source-bound deployment manifests, exact dry-run/live transaction comparisons and runtime hashes.
- Frontend lint, production build and server-rendered route tests.

Every claim and its reproduction command is indexed in
[Proof of Work](https://github.com/gnanam1990/heirloom-protocol/blob/main/docs/PROOF-OF-WORK.md).

## Why Base

- Low-cost owner heartbeats and permissionless execution are practical on Base.
- Native USDC provides a familiar initial asset scope.
- Base Account-compatible onboarding can reduce seed-phrase friction with passkeys.
- Public Base state lets owners and beneficiaries verify vault identity, deadlines and routes
  without trusting the frontend.
- Heirloom expands Base utility beyond trading into long-duration self-custody continuity.

## Current status and limitations

- The Base Sepolia product is a proposal prototype, not a production inheritance service.
- The Base mainnet factory is explicitly unaudited proposal proof; it has no vaults or user funds.
- Mainnet vault creation, deposits and onboarding remain blocked pending an independent external
  smart-contract audit, remediation and auditor re-verification.
- Heirloom detects owner inactivity, not death, incapacity or lost keys.
- Circle can pause, blacklist or upgrade USDC.
- Public configuration exposes recipient and guardian addresses.

## Contact

- **Founder:** Gnanasekaran Jaganathan
- **Email:** `gamingtushar04@gmail.com`
- **X:** [@pindropsx](https://x.com/pindropsx)
- **Telegram:** `@gnanamccnOOb`
- **GitHub:** [gnanam1990](https://github.com/gnanam1990)
- **Basename:** `kratoss.base.eth`


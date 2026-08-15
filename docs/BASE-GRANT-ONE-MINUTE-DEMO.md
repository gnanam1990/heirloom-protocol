# Heirloom — One-Minute Base Grant Demo

**Goal:** Give a Base grants reviewer enough evidence to understand, verify and remember Heirloom in
60 seconds through an interactive HTML walkthrough without claiming mainnet readiness or user
traction.

## Interactive setup

- The walkthrough is rendered entirely with HTML, CSS and public image assets.
- It starts automatically when motion is allowed and remains fully controllable.
- Reviewers can pause, restart, seek or jump directly to any chapter.
- No wallet connection, account, audio or downloadable video is required; optional ambient music is off by default.
- Reduced-motion visitors start paused and can navigate manually.

## 60-second sequence

| Time | Screen | On-screen explanation |
|---:|---|---|
| 0–7s | Heirloom landing/owner view | “Self-custody works until the only key holder becomes unavailable. Heirloom adds a precommitted USDC continuity plan on Base.” |
| 7–17s | Connect wallet and Base Sepolia network | “The owner connects with a wallet or passkey-backed Base Account and remains in control while active.” |
| 17–29s | Funded vault summary | “This verified Base Sepolia vault holds 20 USDC. Its owner, asset, routes, guardians and deadlines are reconstructed from public contract reads.” |
| 29–41s | Lifecycle timeline | “Fresh owner actions reset liveness. After inactivity and a challenge window, distribution becomes irreversible.” |
| 41–50s | Beneficiary/security view | “Any caller may execute, but the contract—not the caller—derives the recipient, amount and valid time phase.” |
| 50–57s | Public proof/explorer | “The factory, implementation and funded vault are source-verifiable, with high-intensity state-machine and Base USDC evidence.” |
| 57–60s | Closing title | “Heirloom: permissionless execution without payout authority, built for Base.” |

## On-screen proof labels

- `Base Sepolia · 84532`
- `20 USDC funded test vault`
- `Destination-locked payouts`
- `73 contract tests · 5 stateful groups · 16/16 mutants`
- `Proposal prototype — not public mainnet`

## Acceptance checks

- The automatic sequence lasts exactly 60 seconds.
- Public demo opens in a logged-out/incognito window.
- Every claim is readable without audio.
- Play, pause, restart, seek and chapter controls work from keyboard and touch input.
- Every address shown matches the committed deployment manifests.
- No screen implies that Heirloom detects death or lost keys.
- No screen says externally audited, production-ready or live on Base mainnet.
- The owner has reviewed and accepted the nomination form's multimedia license before submission.

## Published artifact

- Format: text-led interactive HTML/CSS animation with play, pause, seek, chapters and optional low-volume ambient music
- Duration: `60 seconds`
- Visual sources: live Heirloom UI captures and Base Sepolia Blockscout proof
- Public URL:
  `https://heirloom-protocol-production.up.railway.app/demo`
- Accessibility: persistent explanations, keyboard controls and reduced-motion support

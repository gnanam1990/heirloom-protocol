# Heirloom Web

The owner dashboard and public evidence surface for Heirloom on Base.

## Prerequisites

- Node.js `>=22.13.0`

## Local verification

```bash
npm ci
npm run lint
npm test
```

The app currently targets Base Sepolia. Preview values remain explicitly labeled until a verified
factory address is added and live contract reads are enabled. Wallet connection uses Base Account,
so passkey-backed accounts work without seed-phrase onboarding.

## Brand direction

- Base Blue `#0000FF` is a restrained action and state accent.
- White, gray and black remain dominant.
- No gradients.
- Technical identity and addresses use the mono typeface.

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

The app targets Base Sepolia and pins the source-verified v3.1 factory at
`0x524A95082dAD59fd8bf18FA27F89E3f55202eEcf`. The launch panel reads factory identity and
USDC balances live, validates the production minimum schedule, creates deterministic owner vaults,
and exposes approval, deposit and heartbeat actions. Injected wallets are preferred when present;
Base Account remains available through the shared Wagmi configuration.

## Brand direction

- Base Blue `#0000FF` is a restrained action and state accent.
- White, gray and black remain dominant.
- No gradients.
- Technical identity and addresses use the mono typeface.

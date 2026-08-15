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

The app targets Base Sepolia and pins the source-verified v3.1-R1 factory at
`0x935e5101d7563429BC152889603D3A17f466f4e4`. The launch panel reads factory identity and
USDC balances live, validates the production minimum schedule, creates deterministic owner vaults,
and exposes approval, deposit and heartbeat actions. After creation, the dashboard derives funding,
allowance, liveness, configuration, routes, guardian quorum and recovery state from Base Sepolia.
Reloading between approval and deposit is safe because the approval gate is reconstructed from the
token contract rather than browser memory. Injected wallets are preferred when present; Base
Account remains available through the shared Wagmi configuration.

The dashboard also presents the source-verified Base mainnet proposal factory as read-only public
evidence. Mainnet vault creation, deposits and user onboarding remain intentionally unavailable;
all product write actions stay bound to Base Sepolia.

## Brand direction

- Base Blue `#0000FF` is a restrained action and state accent.
- White, gray and black remain dominant.
- A restrained dark proof surface separates mainnet evidence from testnet product controls.
- Technical identity and addresses use the mono typeface.

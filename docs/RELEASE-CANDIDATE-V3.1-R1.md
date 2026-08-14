# Heirloom v3.1-R1 Release Candidate

**Release commit:** `286b0e98d3372262410de54363759f17a1becb41`  
**Target:** Base Sepolia only  
**Mainnet status:** Blocked pending independent external audit  
**Version preimage:** `HEIRLOOM_V3_1_R1`  
**Version ID:** `0x2307fc907cb859b0cb1ee608138ba346e301805703f489f8370477c357b73f56`

## Purpose

R1 gives the audit-remediated implementation a unique release identity. The historical Base
Sepolia factory uses `HEIRLOOM_V3_1` and predates remediation. Reusing that identifier for different
factory/implementation bytecode would make deployment evidence ambiguous.

The R1 commit changes only:

- `HeirloomFactory.VERSION_ID` from `HEIRLOOM_V3_1` to `HEIRLOOM_V3_1_R1`.
- The deployment identity assertion and runbook.
- Release-status documentation.

`HeirloomVault.sol`, its storage layout and its runtime bytecode are unchanged from remediation
commit `50461c50f5dd9d8505d684286d75ba6e3ed58ee1`.

## Source identity

| File | SHA-256 |
|---|---|
| `src/HeirloomFactory.sol` | `456373f6ae289df7b973a6f483e3676962ff7168ca8063f84ab137ed536dd90a` |
| `src/HeirloomVault.sol` | `7f5e61cf51e80739e30315003a7c7f14c1d0f261d9d22115bec901e1baef7c71` |
| `src/HeirloomTypes.sol` | `98181688a1ee2234c94bef8781f9629b269184735d99d7884b6ca1427aa48285` |
| `src/interfaces/IHeirloomVault.sol` | `651f44819a90794d2b4597538f9567b9fb413639da1c64ecac2bcf7fa4621e78` |

## Pre-deployment verification

- 58 core Forge entries passed.
- Five stateful groups completed 500,000 calls with zero unexpected handler reverts.
- The vault remains 23,818 bytes with a 758-byte EIP-170 margin.
- The factory remains 2,995 bytes.
- The gas snapshot matches.

The candidate may be simulated and deployed on Base Sepolia only after its hosted CI run passes.
The deployment transaction, addresses, hashes and explorer verification must be committed in a new
manifest. No mainnet script or authorization is created by this release candidate.

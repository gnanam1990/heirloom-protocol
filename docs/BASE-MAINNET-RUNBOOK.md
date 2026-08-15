# Base Mainnet Preparation and Release Runbook

**Status:** Preparation only; no Base mainnet deployment is authorized.

The mainnet script is intentionally fail-closed. A dry-run may execute before the external audit,
but `--broadcast` and `--resume` require all release-authorization inputs. Environment flags are
operational guardrails; they are not a substitute for an independent report or release-owner
review.

## Pinned identity

| Field | Required value |
|---|---|
| Chain | Base mainnet, `8453` |
| Deployer | `0xE8405844a45C209895afE2e49be6aA2C6C6202a6`, nonce `0` |
| Circle-issued USDC | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| Predicted factory | `0x524A95082dAD59fd8bf18FA27F89E3f55202eEcf` |
| Expected factory runtime hash | `0xbce0f26e2d6fc4eb3cfea3184113b7cdd01ae123b775ca6ac16938a6b18ec547` |
| Version preimage | `HEIRLOOM_V3_1_R1` |
| Version ID | `0x2307fc907cb859b0cb1ee608138ba346e301805703f489f8370477c357b73f56` |
| Audit candidate | `v3.1-r1-audit-candidate-2` → `7ea6617625615e41469e153bc19f020eeb692d4a` |
| Expected implementation runtime hash | `0x48bfce26a7b15d9f7ceaa248db541a41a5afdc84ca9ac27252ff8d6dc2770ab9` |

If an audit finding changes production bytecode, stop. Create a new version ID, audit candidate,
runtime hash and deployment manifest; never reuse this release identity for different code.

## Mandatory release gates

Every item must have evidence before broadcasting:

- The independent report resolves to the exact candidate commit.
- No unresolved Critical or High findings remain.
- Medium and Low findings are fixed or explicitly accepted in the final report.
- The independent reviewer re-verifies every remediation commit.
- The latest hosted protocol, mutation, Base USDC fork and web jobs are green.
- Circle's Base USDC proxy, implementation and relevant roles are refreshed.
- The release owner records explicit approval.
- The dedicated deployer uses a hardware wallet or encrypted keystore and has only the reviewed gas
  budget.
- The reviewed dry-run and proposed live transaction input are byte-for-byte identical.
- The deployer remains at nonce `0`; any nonce change invalidates the predicted factory and this
  release manifest.

The current same-address deployer preflight showed `0 ETH` on Base mainnet. Funding is intentionally
deferred until the dry-run, gas estimate and release decision are reviewed.

## Dry-run before audit completion

Dry-runs do not need approval flags and do not broadcast:

```bash
forge script script/DeployBaseMainnet.s.sol:DeployBaseMainnet \
  --rpc-url base \
  --sender "$DEPLOYER_ADDRESS"
```

Record the chain, deployer nonce, predicted factory, implementation, gas estimate, transaction
input hash, official USDC address, version ID and implementation runtime hash. A dry-run is not a
release approval.

The first fork preparation receipt is recorded in
`proof/base-mainnet-preparation-fork-50000700.json`. Its successful transaction exists only on an
ephemeral local Anvil fork and uses a plainly labeled synthetic report hash to test gate mechanics;
it is not a Base transaction or release evidence.

## Future broadcast authorization

Set these only after the evidence above is complete:

```bash
export HEIRLOOM_EXTERNAL_AUDIT_APPROVED=true
export HEIRLOOM_MAINNET_RELEASE_APPROVED=true
export HEIRLOOM_AUDITED_COMMIT=0x7ea6617625615e41469e153bc19f020eeb692d4a000000000000000000000000
export HEIRLOOM_EXTERNAL_AUDIT_REPORT_HASH=0x<keccak256-of-final-report-bytes>
```

Then run a second simulation with the release gates forced:

```bash
HEIRLOOM_ENFORCE_RELEASE_GATES=true \
forge script script/DeployBaseMainnet.s.sol:DeployBaseMainnet \
  --rpc-url base \
  --sender "$DEPLOYER_ADDRESS"
```

Only after comparing that simulation to the reviewed manifest may the release owner separately
approve a secure-signer broadcast:

```bash
forge script script/DeployBaseMainnet.s.sol:DeployBaseMainnet \
  --rpc-url base \
  --sender "$DEPLOYER_ADDRESS" \
  --account heirloom-mainnet-deployer \
  --broadcast \
  --verify
```

Never use a raw private key in this repository, shell history, CI, a browser page or a support
message. Never treat a wallet review screen as a successful transaction.

## Post-deployment evidence

Copy `deployments/base-mainnet.example.json` to a commit-bound manifest. Confirm from two RPC or
explorer reads:

1. Receipt status, block hash, gas used and deployment fee.
2. Factory `asset()` equals official Base USDC.
3. `deploymentChainId()` equals `8453`.
4. `VERSION_ID()` equals the pinned v3.1-R1 ID.
5. Factory address and runtime hash equal the pinned values.
6. Implementation code exists and its runtime hash equals the reviewed hash.
7. Factory and implementation source verification succeeds.
8. The implementation initializer is permanently locked.
9. No vault is created or funded until the factory evidence commit and hosted CI are green.

The first mainnet vault must use a separate, explicitly capped smoke-release decision. Factory
deployment does not authorize depositing meaningful-value USDC.

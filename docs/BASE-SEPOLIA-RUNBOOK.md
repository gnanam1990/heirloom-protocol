# Base Sepolia Deployment Runbook

This runbook prepares reproducible testnet evidence. It does not authorize mainnet deployment.

## Preconditions

- All local and hosted CI gates are green.
- The deployment commit is clean, pushed and recorded.
- `DEPLOYER_ADDRESS` is a dedicated, funded Base Sepolia address.
- Signing uses a hardware wallet or encrypted Foundry keystore.
- The official Circle Base Sepolia USDC address is still
  `0x036CbD53842c5426634e7929541eC2318f3dCF7e` when checked immediately before
  deployment.
- The RPC reports chain ID `84532`.

## Simulate

```bash
forge script script/DeployBaseSepolia.s.sol:DeployBaseSepolia \
  --rpc-url base_sepolia \
  --sender "$DEPLOYER_ADDRESS"
```

Review the predicted factory, implementation, asset, gas and chain before broadcasting.

## Broadcast and verify

Use exactly one of Foundry's secure signer integrations. Example with an encrypted keystore:

```bash
forge script script/DeployBaseSepolia.s.sol:DeployBaseSepolia \
  --rpc-url base_sepolia \
  --sender "$DEPLOYER_ADDRESS" \
  --account heirloom-testnet-deployer \
  --broadcast \
  --verify
```

Never pass or store a raw private key in this repository, shell history, CI variable or support
message.

## Required evidence

Copy `deployments/base-sepolia.example.json` to a commit-specific manifest and fill every field
from RPC or explorer evidence. Before accepting the deployment:

1. Confirm factory `asset()` equals official Base Sepolia USDC.
2. Confirm `deploymentChainId()` is `84532`.
3. Confirm `VERSION_ID()` equals `keccak256("HEIRLOOM_V3_1_R1")`. The `R1` suffix binds the
   audit-remediated bytecode and distinguishes it from the historical pre-remediation factory.
4. Confirm the implementation initializer is permanently locked.
5. Create a vault and confirm predicted and deployed addresses match.
6. Fund the release vault and record approval, deposit, exact balances, zero residual allowance and
   liveness. Then observe the real-time claim stages as their configured windows become eligible;
   do not claim completion before those timestamps actually elapse.
7. Record every completed transaction, block, code hash and explorer verification link. Use local
   time-warp and Base-fork tests for full lifecycle regression coverage while real time is pending.
8. Configure the UI only after the manifest is reviewed.

## Release-vault monitor

Run the read-only release monitor against the public Base Sepolia RPC:

```bash
./script/check-base-sepolia-vault.sh
```

Set `BASE_SEPOLIA_RPC_URL` to use another provider. The monitor fails closed if the factory
registry, owner, asset, version, state, manifest-pinned balance, zero residual allowance, runtime
hash or minimum liveness nonce differs from the recorded R1 evidence. Update the expected balance
and nonce only in the same commit as a verified funding or heartbeat receipt.

## Mainnet boundary

There is intentionally no mainnet deployment script. Add one only after independent audit,
remediation, Base Sepolia evidence review and an explicit mainnet release decision.

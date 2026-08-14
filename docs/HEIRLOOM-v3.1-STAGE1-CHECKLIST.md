# Heirloom v3.1 - Stage 1 Implementation Checklist

## Before coding

- [ ] Product owner signs D1-D40.
- [ ] Security reviewer signs I1-I16.
- [ ] Duration constants and bounds are copied exactly from v3.1.
- [ ] Official Base Sepolia USDC address is verified again.
- [ ] Reference model covers every transition and timestamp equality.

## Contract kernel

- [ ] Four states only: Active, ClaimRequested, Distributing, Settled.
- [ ] `lastSeen` changes only through the v3.1 liveness matrix.
- [ ] Permissionless config execution never heartbeats.
- [ ] Claim request stores liveness and config epochs.
- [ ] `executePayout(index)` has no destination argument.
- [ ] Primary, fallback and rollover phases are mutually exclusive.
- [ ] Terminal remains locked until all non-terminal entries resolve.
- [ ] Terminal pays `snapshotRemaining` once.
- [ ] Exact token balance deltas are checked.
- [ ] Unsupported-token rescue is absent.

## Recovery and configuration

- [ ] Guardians cannot choose an owner.
- [ ] Recovery has threshold, delay, owner veto and expiry.
- [ ] Activation invalidates claim, config and old nonces atomically.
- [ ] Config hash binds chain, vault, version, nonce and full payload.
- [ ] Config is frozen from ClaimRequested onward.

## Evidence and testing

- [ ] All four P0 regression suites are green.
- [ ] I1-I16 pass under stateful fuzzing.
- [x] Each I1-I16 invariant has a compiling source mutant killed by its mapped regression test.
- [ ] Exact timestamp boundaries are exhaustively tested.
- [ ] Base Sepolia lifecycle is source-verified and reproducible.
- [x] Pinned and latest Base mainnet-fork USDC tests are green locally and in hosted CI.
- [ ] Runtime bytecode hash matches the announced factory version.

## Prohibited shortcuts

- [ ] No proxy or admin key.
- [ ] No automated heartbeat service.
- [ ] No transfer-failure-driven fallback.
- [ ] No caller-selected payout destination.
- [ ] No terminal payout before non-terminal resolution.
- [ ] No custom relayed signature interface in V1.
- [ ] No mainnet deployment before independent audit and remediation.

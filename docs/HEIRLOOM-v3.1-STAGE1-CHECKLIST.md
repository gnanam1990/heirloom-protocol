# Heirloom v3.1 - Stage 1 Implementation Checklist

## Before coding

- [ ] Product owner signs D1-D40.
- [ ] Security reviewer signs I1-I16.
- [x] Duration constants and bounds are copied exactly from v3.1.
- [x] Official Base Sepolia USDC address is verified again.
- [x] Reference model covers every transition and timestamp equality.

## Contract kernel

- [x] Four states only: Active, ClaimRequested, Distributing, Settled.
- [x] `lastSeen` changes only through the v3.1 liveness matrix.
- [x] Permissionless config execution never heartbeats.
- [x] Claim request stores liveness and config epochs.
- [x] `executePayout(index)` has no destination argument.
- [x] Primary, fallback and rollover phases are mutually exclusive.
- [x] Terminal remains locked until all non-terminal entries resolve.
- [x] Terminal pays `snapshotRemaining` once.
- [x] Exact token balance deltas are checked.
- [x] Unsupported-token rescue is absent.

## Recovery and configuration

- [x] Guardians cannot choose an owner.
- [x] Recovery has threshold, delay, owner veto and expiry.
- [x] Activation invalidates claim, config and old nonces atomically.
- [x] Config hash binds chain, vault, version, nonce and full payload.
- [x] Config is frozen from ClaimRequested onward.
- [x] Guardian quorum blocks permissionless config execution until recovery is resolved.
- [x] Distribution clears unreachable pending config state.
- [x] Vault self-address is rejected from destinations and recovery authorities.

## Evidence and testing

- [x] All four P0 regression suites are green.
- [x] I1-I16 pass under stateful fuzzing.
- [x] Atomic-unit rounding and positive-snapshot zero entitlements are covered.
- [x] Each I1-I16 invariant has a compiling source mutant killed by its mapped regression test.
- [x] Exact timestamp boundaries are exhaustively tested.
- [x] R1 Base Sepolia creation, funding and owner-liveness evidence is source-verified and reproducible.
- [ ] Complete R1 real-time claim-to-settlement lifecycle has elapsed and is independently reproduced.
- [x] Pinned and latest Base mainnet-fork USDC tests are green locally and in hosted CI.
- [x] Runtime bytecode hash matches the announced factory version.

## Prohibited shortcuts

- [x] No proxy or admin key.
- [x] No automated heartbeat service.
- [x] No transfer-failure-driven fallback.
- [x] No caller-selected payout destination.
- [x] No terminal payout before non-terminal resolution.
- [x] No custom relayed signature interface in V1.
- [x] No mainnet deployment before independent audit and remediation.

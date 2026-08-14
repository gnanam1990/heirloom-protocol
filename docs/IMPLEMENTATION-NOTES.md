# Implementation Notes

These notes record implementation-level decisions that preserve the v3.1 security constitution
without reopening D1-D40.

## Deterministic minimal clones

The first direct-deployment factory build embedded the complete vault creation code and produced a
29,615-byte factory runtime, exceeding the 24,576-byte EIP-170 limit. The implementation therefore
uses deterministic OpenZeppelin minimal clones:

- The factory deploys one `HeirloomVault` implementation in its constructor.
- The implementation constructor permanently locks its own initializer.
- Every user vault is a separately initialized deterministic clone.
- The factory salt binds owner, user salt and complete initial configuration hash.
- Every official clone has the same public runtime code hash.
- The implementation exposes no upgrade, admin, pause or self-destruct path.

This reduced factory runtime to 2,995 bytes while retaining deterministic prediction and public
code-identity verification.

## Recovery invalidation on owner activity

Any successful owner-liveness action deletes a pending guardian recovery request. This is the
same safety outcome as an explicit owner veto, emits recovery invalidation evidence and prevents
guardians from activating an old request after the owner has freshly demonstrated control.

Configuration execution and distribution start also invalidate pending recovery. Distribution
remains the irreversible boundary.

## Production boundary

The contracts and UI are pre-production. Base Sepolia deployment evidence, pinned/latest Base
mainnet USDC fork compatibility, I1-I16 source-mutation evidence and full I1-I16 stateful coverage
are recorded. An independent audit and remediation remain mandatory before a mainnet release.

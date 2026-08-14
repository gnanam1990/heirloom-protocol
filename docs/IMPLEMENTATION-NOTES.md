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

Configuration execution invalidates a pending recovery only before guardian threshold is reached.
Once quorum is reached, config execution reverts until the owner vetoes recovery, recovery activates,
or an expired request is cleared. Distribution start invalidates recovery and any pending config;
distribution remains the irreversible boundary.

## Self-address configuration rejection

The vault rejects its own address as a primary/fallback destination, recovery address or guardian.
A supported-token transfer to self would not reduce the vault balance and therefore cannot satisfy
exact-delta accounting. Rejecting the configuration prevents an owner from scheduling an incapable
route or authority while exact-delta enforcement remains the runtime backstop.

## Terminal rounding model

Every non-terminal entitlement is floored independently. The terminal base is the full snapshot
minus those non-terminal floors, not merely the floor of the terminal BPS share. The terminal thus
absorbs every atomic-unit rounding remainder and every later rollover exactly once. Stateful tests
use a snapshot not divisible by 10,000 so this rule is exercised continuously.

## Production boundary

The contracts and UI are pre-production. Base Sepolia deployment evidence, pinned/latest Base
mainnet USDC fork compatibility, I1-I16 source-mutation evidence and full I1-I16 stateful coverage
are recorded. An independent audit and remediation remain mandatory before a mainnet release.

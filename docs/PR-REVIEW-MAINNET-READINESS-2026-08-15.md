# Heirloom v3.1-R1 Mainnet-Readiness Code Review

**Method:** Updated multi-pass `pr-review` protocol  
**Reviewed candidate:** `v3.1-r1-audit-candidate-2` → `7ea6617625615e41469e153bc19f020eeb692d4a`  
**Base:** `b1dc61c97b950b96ab1e63b99866cf2383bb8e83`  
**Verdict:** Approve for the internal review gate; not an independent external audit

## Outcome

No blocking correctness or security finding survived the verification gate. Current `main` and the
immutable audit candidate are byte-identical across `src/`, `test/`, `script/`, `apps/` and
`mutations/`; later changes before this review were evidence and proposal artifacts.

## Executed evidence

- Forge 1.7.1 build and size check passed.
- The non-fork CI profile passed `59/59` entries, including 500,000 stateful calls.
- The committed gas snapshot matched.
- All `16/16` I1-I16 production-source mutants were killed.
- A scratch gut-the-fix removed the remediation checks while keeping tests unchanged. Exactly the
  three remediation-binding tests failed: distribution invalidation, recovery/config ordering and
  vault self-destination rejection. This proves those fixes are load-bearing.
- The zero-snapshot boundary test maps to a real cached invariant failure sequence.
- The locally compiled implementation runtime keccak matches
  `0x48bfce26a7b15d9f7ceaa248db541a41a5afdc84ca9ac27252ff8d6dc2770ab9`.
- The version preimage `HEIRLOOM_V3_1_R1` hashes to the deployed version ID.

The saved-plan fan-out could not read Zero's host configuration from its sandbox, so the same eight
reading lenses ran sequentially as the skill's documented fallback. The sandbox could not install
web dependencies or access the Base RPC; the exact source subsequently had all four hosted CI jobs
green in run `31877143185`.

## Non-blocking observations

1. The vault runtime is 23,818 bytes, leaving a 758-byte EIP-170 margin.
2. The 16-source-mutant suite covers I1-I16 but not the later H-01/M-01/L-01 remediation lines. The
   scratch gut-the-fix proved them manually; dedicated automated mutants remain desirable.
3. The product UI still stated `58 core` after the candidate added the fifty-ninth test. The
   remediated mainnet-preparation suite adds ten deployment-gate tests, so the current UI and render
   assertion now state `69`; historical candidate evidence remains `59` and historical release evidence
   remains intact.
4. Post-settlement direct USDC transfers are sweepable to the settled terminal destination by
   design. This behavior must remain explicit in the independent report and product copy.

## Mainnet boundary

This internal approval does not close the mainnet release gate. The external report, any remediation
and the original auditor's re-verification remain mandatory. The mainnet deployment path may be
prepared and dry-run, but no broadcast or meaningful-value vault funding is authorized by this
review.

## Mainnet-preparation diff review

The updated review protocol was applied again to the preparation diff. One release-integrity issue
survived verification: the initial script pinned only the implementation runtime hash, so a wrong
deployer or a later-modified factory could still produce a different release identity while the
four environment approvals passed. The remediation now pins the intended deployer and nonce,
predicted factory address, factory runtime hash and implementation runtime hash. Focused tests cover
wrong deployer and changed nonce in addition to every authorization gate.

Zero was available, but its configured model/provider pair could not start the isolated run. Per the
review protocol's fallback, the same formatting, build, focused, full-suite, fork, web and mutation
checks ran directly. No blocking finding remains in the remediated preparation diff. This is an
approval of preparation only, not an external audit or Base mainnet broadcast authorization.

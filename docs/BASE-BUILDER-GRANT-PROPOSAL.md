# Heirloom — Base Builder Grant Proposal

**Submission status:** Draft complete; not submitted

**Current network:** Base Sepolia

**Proposal posture:** Working testnet prototype with verified onchain and engineering evidence

**Mainnet posture:** Not required for this proposal; independent review remains a future public-launch gate

## Executive summary

Heirloom is a non-custodial USDC continuity vault for Base. An owner configures beneficiaries,
fallback destinations, guardians and time windows. If the owner stops producing fresh wallet
authorization for the configured inactivity period, anyone can advance a challengeable,
destination-locked distribution. The caller pays gas but cannot choose where funds go, how much is
paid or which destination phase is valid.

The proposal demonstrates a working Base Sepolia system rather than an idea-only pitch: a deployed
factory and implementation, a funded owner vault, an owner-facing Base-themed application,
source-bound deployment manifests, and automated state-machine evidence. Heirloom does not claim
to detect death or lost keys. It observes only owner authorization and time.

## Why this belongs on Base

- Base makes low-cost periodic owner heartbeats and permissionless execution practical.
- Native Base USDC gives the product a familiar, dollar-denominated asset for an initial scope.
- Base Account-compatible onboarding can reduce seed-phrase friction with passkey-backed wallets.
- Public Base state lets owners, beneficiaries and third parties verify vault identity, deadlines
  and destination rules without trusting the Heirloom frontend.
- The product expands Base beyond trading: it addresses long-duration custody continuity for
  families, solo operators and small onchain organizations.

## The problem

Self-custody normally has two brittle outcomes: one person retains total control, or sensitive
recovery material is shared early. If that person becomes unavailable, assets can remain
inaccessible indefinitely. Traditional scheduled transfers introduce a trusted operator or an
executor who can aim the payment. Existing wallet recovery can restore account control, but it does
not express a transparent, challengeable asset-distribution policy.

## The product

Heirloom separates execution from payout authority:

1. The owner creates and funds a vault with fixed recipients and time windows.
2. Fresh owner-authorized actions reset the liveness clock.
3. After inactivity, any account may request a claim; no asset moves.
4. A challenge window lets fresh owner activity cancel the claim.
5. If unchallenged, distribution snapshots the vault balance and becomes irreversible.
6. Time selects exactly one valid destination phase: primary, fallback, then rollover.
7. Terminal settlement occurs once, after every standard entitlement is resolved.

This makes execution open while keeping payout economics destination-locked.

## What is live today

| Evidence | Verified state |
|---|---|
| Network | Base Sepolia, chain ID `84532` |
| Factory | `0x935e5101d7563429BC152889603D3A17f466f4e4` |
| Implementation | `0x93C9a8b47d558F8C30F1e1754Ad2b050933F0FE3` |
| Funded vault | `0x21ea6A01Dd4A7C9F87Bdc80773fbB765FF6fa371` |
| Test vault funding | `20 USDC` |
| Core Forge entries | `59` passed |
| Stateful evidence | `500,000` randomized calls per high-intensity run |
| Mutation evidence | `16/16` production-source mutants killed |
| Base USDC evidence | `9/9` pinned/latest fork cases passed |
| Hosted release evidence | GitHub Actions run `31875566790`, four jobs passed |

These are engineering and testnet milestones, not user-adoption claims. The current externally hosted
demo requires authentication and must be replaced with a public reviewer URL before submission.

## Differentiation

| Common approach | Limitation | Heirloom response |
|---|---|---|
| Share a seed phrase | Immediate theft and privacy risk | Beneficiaries never need the owner credential |
| Multisig recovery | Restores control but may not define distribution | Fixed entitlements and time-derived routes |
| Scheduled transfer | Usually needs a trusted operator | Anyone can execute without aiming funds |
| Transfer-failure fallback | Cannot detect a lost-key EOA | Fallback eligibility is explicitly time-based |
| Centralized inheritance service | Adds custody and operational trust | Vault logic and deadlines are public on Base |

## Intended users

- Self-custody users who want a transparent continuity plan without sharing a seed phrase.
- Solo founders and creators holding operational USDC on Base.
- Small onchain teams that need a precommitted continuity route for treasury assets.
- Beneficiaries who may not be active crypto users but can receive to a preconfigured address.

## Grant impact plan

The next delivery phase converts the verified prototype into a reviewer-accessible pilot:

| Phase | Delivery | Success evidence |
|---|---|---|
| Public access | Publish a stable read-only/public Base Sepolia demo | Reviewer opens without authentication and reaches explorer proof |
| Onboarding | Simplify Base Account/passkey connection and vault setup education | Completion funnel and failed-step telemetry |
| Pilot | Recruit opt-in testnet owners and beneficiaries | Created/funded vaults and completed walkthroughs |
| Execution support | Add non-authoritative reminders and permissionless execution guidance | Reminder delivery and successful testnet actions |
| Learnings | Publish limitations, pilot results and product decisions | Public changelog and measured next-stage decision |

Grant support would be used for public hosting, monitoring, pilot operations, onboarding refinement,
documentation and user research. It would not be represented as approval for a public mainnet
launch. Mainnet security review and launch funding remain a separate future stage.

## Metrics to report

- Unique pilot participants and completed onboarding sessions.
- Base Sepolia vaults created and funded through the product.
- Heartbeats, claim requests and permissionless actions produced through the UI.
- Setup completion rate and the step where users abandon.
- Beneficiary comprehension of primary, fallback, rollover and terminal behavior.
- Public proof-page visits and explorer-link engagement.

No fabricated TVL, users or transaction volume will be included. Zero user traction will be stated
as zero until measured.

## Risks and honest limitations

- Heirloom detects inactivity, not death, incapacity or key loss.
- A compromised owner can withdraw while the vault is Active.
- Circle can pause, blacklist or upgrade USDC.
- Public configuration exposes recipient and guardian addresses.
- Permissionless execution does not guarantee that someone will pay gas.
- Distribution is intentionally irreversible after its snapshot boundary.
- The current deployment is testnet evidence, not a public mainnet product.

## Current Base Grant nomination form

The official form currently requests the fields below. Placeholders are intentionally unresolved
where only the project owner can supply or authorize the answer.

| Field | Proposed answer |
|---|---|
| Email | `[OWNER EMAIL REQUIRED]` |
| Nominator name | `[OWNER NAME REQUIRED]` |
| Project name | `Heirloom` |
| Project URL | `[PUBLIC DEMO URL REQUIRED — current private URL returns 401]` |
| Project Twitter | `[PROJECT X HANDLE REQUIRED]` |
| Project Farcaster/channel | `[PROJECT FARCASTER REQUIRED]` |
| Builder Twitter | `[BUILDER X HANDLE REQUIRED]` |
| Builder Farcaster | `[BUILDER FARCASTER REQUIRED]` |
| Is the project live on Base? | `No — live on Base testnet` |
| One-minute demo | `[PUBLIC VIDEO URL REQUIRED]` |
| Multimedia license | `[OWNER MUST REVIEW AND CONFIRM]` |
| Marketing communications | `[OWNER CHOICE REQUIRED]` |

## Form-ready answer: why Heirloom deserves a Base grant

> Heirloom is a working Base Sepolia USDC continuity vault that turns prolonged owner inactivity
> into a challengeable, destination-locked distribution. Owners retain full control while active;
> after inactivity, anyone can execute the precommitted plan without choosing recipients, amounts,
> or payout phases. This makes execution permissionless without making funds aimable. The prototype
> includes a deployed factory and implementation, a funded 20 USDC vault, a Base-themed owner
> dashboard, public explorer evidence, 59 passing Forge entries, 500,000-call stateful runs, 16/16
> killed source mutants, and Base USDC fork tests. Heirloom expands Base beyond trading into
> long-duration self-custody continuity for individuals, solo operators, and small onchain teams.
> Grant support would help us publish a frictionless public demo, run an opt-in testnet pilot,
> improve passkey-based onboarding, measure comprehension and activation, and document learnings
> before any separately reviewed public mainnet launch.

The answer is 133 words and remains below the form's 150-word limit.

## Reviewer links

- Base Sepolia factory:
  `https://base-sepolia.blockscout.com/address/0x935e5101d7563429BC152889603D3A17f466f4e4`
- Base Sepolia implementation:
  `https://base-sepolia.blockscout.com/address/0x93C9a8b47d558F8C30F1e1754Ad2b050933F0FE3`
- Funded Base Sepolia vault:
  `https://base-sepolia.blockscout.com/address/0x21ea6A01Dd4A7C9F87Bdc80773fbB765FF6fa371`
- Hosted verification:
  `https://github.com/gnanam1990/heirloom-protocol/actions/runs/31875566790`
- Repository: private during proposal development; reviewer access requires an explicit decision.

## Submission gate

Do not submit until every required placeholder above is resolved, the one-minute video is publicly
accessible, the project URL opens without authentication, and the owner has reviewed the form's
multimedia license and privacy terms.

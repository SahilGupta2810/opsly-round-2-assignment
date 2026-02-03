# Task 2 — AWS Account Structure & Security

This folder contains documentation for **Part 2: AWS Account Structure & Security**.

## Completion status

| Requirement | Status | Notes |
| --- | --- | --- |
| Multi-account structure (dev / uat / prod, shared services, security/audit) | Done | Proposed OU/account layout is in `solution.md`. |
| Control Tower / Organizations + SCPs | Done | Includes example SCPs and a suggested OU structure. |
| SSO for team access + permission sets | Done | Describes IAM Identity Center usage and example roles. |
| Centralized security + logging services | Done | Covers CloudTrail, Config, GuardDuty, Security Hub, Macie, Inspector, and centralized log archive. |

## Artifacts

- `solution.md` — the proposed multi-account design, guardrails (SCPs), SSO approach, and security services.
- `my_thoughts.md` — reasoning and threat-model style narrative behind the design choices.

## Notes / improvements to consider

- Tighten SCP examples to your actual allowed regions and add explicit “break-glass” operational guidance for Prod.
- Add a short “day-2 ops” section (patching, incident response, access reviews, and logging retention).

# How I Thought About This While Working on the Design

When I started working on this task, I didn't begin with services or diagrams. I started with a simpler question:

> What are the worst things that can go wrong if this isn't designed properly?

From experience, most issues in AWS environments don't come from lack of features. They come from accidental changes and too much access. So the entire design is built around reducing access and incident scope and protecting the most critical systems first.

---

## First: What can realistically go wrong?

These are problems I've either seen directly or seen teams struggle with.

### Logging gets disabled or deleted

This usually happens during:
- Cleanup
- Cost optimization
- Someone "just testing something"

Once logs are gone:
- Investigations become impossible
- Compliance is immediately at risk

So centralized, protected logging became non-negotiable.

### People deploy resources in the wrong place

Without guardrails:
- Resources end up in random regions
- No one monitors them
- Costs increase silently
- Compliance issues appear later

That pushed me to think about region restrictions early, not as an afterthought.

### IAM users and access keys creep in

Even with good intentions, people create IAM users because it's "quick". That leads to:
- Long-lived credentials
- Leaked keys
- Painful cleanup later

This is why I decided to force SSO everywhere and block IAM users at the org level.

### Shared infrastructure gets modified or deleted

Networking is a classic example. One wrong change can:
- Break connectivity for multiple accounts
- Take down multiple applications at once

That’s what led me to introduce a dedicated Networking OU with strong protection.

### Security tooling gets turned off

Security tools don't break things immediately, so they're easy to ignore. But disabling them means:
- No early warnings
- Delayed incident detection

That’s why security services are centralized and protected by SCPs.

### Production gets treated like another environment

This is probably the biggest risk. If Prod is not clearly separated:
- People experiment there
- Changes are rushed
- Incidents become more likely

So I intentionally made Prod stricter, not because teams shouldn't be trusted, but because mistakes in Prod are expensive.

---

## Second: What are the systems I must protect at all costs?

Once I listed the risks, a few systems stood out as critical:
- Identity (IAM / SSO)
- Logging (CloudTrail, Config)
- Networking (VPCs, Transit Gateway, DNS)
- Security services (GuardDuty, Security Hub)
- Production workloads and data
- Backups

These are the systems where accidental destruction causes org-wide impact. Everything else is secondary.

---

## Third: How do I prevent destruction, not just manage access?

This is where SCPs and account structure come in.

I didn't use SCPs to micromanage teams. I used them to block irreversible actions:
- Deleting logs
- Disabling security tools
- Creating IAM users
- Deleting shared network resources
- Exposing Prod publicly

The idea was:

> If someone makes a mistake, the system should stop them before damage is done.

---

## Why the OU structure looks the way it does

Each OU exists because something needed isolation:
- **Security OU:** Security tools need protection from misuse.
- **Networking OU:** Shared network components should not be casually modified.
- **Shared Services OU:** Identity and backups should be stable and boring.
- **Application OU (Non-Prod vs Prod):** Speed and safety require different rules.

This separation wasn't theoretical; it came directly from thinking about failure scenarios.

---

## How I balanced speed vs safety

I didn't want this design to slow teams down. So:
- Non-Prod stays flexible
- Prod stays strict
- Guardrails focus on destruction, not daily work

Developers can still move fast. They just can't accidentally break the entire organization.

---

## How I would summarize my approach

If I had to describe my thinking in one sentence:

> I designed this assuming people will make mistakes, and focused on making sure those mistakes are small, contained, and recoverable.

That mindset drove:
- The multi-account structure
- The OU separation
- The SCP choices
- The emphasis on central logging and security

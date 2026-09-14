---
type: tech-spec
status: Draft
created: {{DATE}}
updated: {{DATE}}
product-spec:
linear-project:
slack-channel:
eng-lead:
---

# {{TITLE}}

> [!info] About this spec
> A tech spec exists to (1) describe the implementation plan for engineers and stakeholders, (2) lay out a timeline and milestones, (3) demonstrate alignment/sign-off, and (4) serve as a historical record of what was done, why, how, and by whom.
> **Not every section is required.** Delete any section that doesn't serve those goals for this project.

## General Info

| | |
|---|---|
| **Product spec** | |
| **Engineering lead** | |
| **Engineers** | |
| **Product / Project manager** | |
| **Design mockups** | |
| **Slack channel** | |
| **Linear project** | |
| **Source of truth** | |

### Engineering sign-offs

Include any cross-squad engineers if applicable.

| Name | Sign-off | Date |
|---|---|---|
| | | |

### Stakeholder (non-engineering) alignment sign-offs

Single place for stakeholders to sign off on the items they should align on. Add/remove rows as needed.

| Item | Name | Sign-off | Date |
|---|---|---|---|
| Events | | | |
| Notification campaigns | | | |
| Milestones & timeline | | | |
| Proposed non-eng work | | | |
| Coordinated launch plan | | | |

## Overview

### Problem statement

_What are we solving and why? One or two paragraphs._

### Deliverables

- _Key deliverable_

### Out of Scope (Non-deliverables)

- _Explicitly out of scope, and why_

## Relevant Tickets

_Linear project/tickets and any related specs or prior work worth linking._

-

## Technical Background

_Relevant logic/terminology to orient an engineer without prior context. Link to related docs._

<!-- Optional: delete if there is no meaningful existing solution -->
### Current / existing solution

- **Description:**
- **Pros:**
- **Cons:**

## Recommended Solution

_Summary of the solution._

- **Pros & cons** (limitations, scalability):
- **Performance considerations** (impact on app performance?):
- **Permissioning / role restrictions:**

## Trade-offs & Other Considerations

_The key trade-offs baked into the recommended approach and anything else worth flagging. If serious alternatives were considered, note them briefly here — why they were passed over, and a migration path if the recommended approach falls through — rather than as a full parallel design._

-

<!-- Optional: delete if no schema changes -->
## Data Model / Schema Changes

- **New models:**
- **Modified models:**
- **Validations:**
- **Backfill & limitations:**

<!-- Optional: delete if no API changes -->
## APIs

Prefer GraphQL for new work (`app/graphql/main_schema.rb`). Note REST only where legacy.

- **Design** (queries/mutations or HTTP methods, request/response payloads):
- **Authentication** (per endpoint/query):
- **Happy path** (pseudocode / flow):
- **Failure scenarios & error states:**

<!-- Optional: delete if no frontend work -->
## Frontend Pages & Components

- **New routes/pages** (and their authentication):
- **New components** (shared vs specialized; can we reuse/generalize an existing one?):

## Automated Testing

_Describe the coverage: which behaviors and edge cases are tested, and by which kind of test (unit / integration / system / component). Prose, not a checklist of whether testing was done._

<!-- Optional -->
## Other Business Logic / Tech

_Modules, jobs, gems, or other tech worth calling out._

<!-- Optional: delete if no events. If kept, tag consumers in the stakeholder sign-off. -->
## Events Created

Link to event descriptions in product spec: _link_

| Event name | Attributes | Trigger | Consumer (messaging campaign, analytics, etc.) |
|---|---|---|---|
| | | | |

<!-- Optional: delete if no campaigns. Owner goes in the stakeholder sign-off. -->
## Notification Campaigns

- **Owner** (Engineering or Ops):

| Campaign name | Trigger | Link (once created) |
|---|---|---|
| | | |

<!-- Optional: multi-PR / multi-sprint projects only -->
## Milestones & Overall Timeline

Factor in OOO/vacation, on-call, company events (QBR, Stepfest), and interviewing.

| Milestone | Target date |
|---|---|
| Tech spec sign-off | |
| Development kickoff | |
| _Milestone 1_ | |
| _Milestone 2_ | |
| QA | |
| Launch | |

**Capacity considerations** (company-wide and per-engineer OOO/on-call/interviewing):

-

<!-- Optional: multi-PR / multi-sprint projects only -->
## Proposed Work

Includes dev, QA, launch, and non-engineering tasks. Include non-eng owners in the stakeholder sign-off.

| Priority | Milestone | Task | Owner | Est. points | Ticket |
|---|---|---|---|---|---|
| P0 | 1 | | | | |

## QA

_Copy the sign-off + test plan for each round as needed._

### Sign-offs

| Team | Name | Date | Notes |
|---|---|---|---|
| Engineer | | | |
| PM | | | |
| Stakeholder | | | |

### Test plan

| Test case / situation | Expected outcome | Eng QA | PM QA | Stakeholder QA | Repro / notes |
|---|---|---|---|---|---|
| | | | | | |

<!-- Optional: multi-PR / multi-sprint projects only -->
## Release / Rollout

_How is the release controlled? Feature flag, phased roll-out, or safe to ship directly?_

<!-- Optional: delete if no coordinated launch is needed -->
### Coordinated launch plan

- **Owner** (tag them; include in stakeholder sign-off if not the eng lead):
- **Launch plan link:**
- _Who are we launching to? A specific segment or partner, or everyone?_

<!-- Optional: delete if no rollback is needed -->
### Rollback plan

-

### Post-release chores (not captured in Linear)

- [ ] Communicate launch to the company (announcements channel, demos)
- [ ] Train operators/users on new features, if applicable
- [ ] Dashboards built by stakeholders (BI tool)
- [ ] Docs for the wider team and/or engineering

## Risks

_List the risks this work introduces and how each is mitigated._

- **Users affected:** _which segments/groups (or "all"), and who to proactively inform._
- **Compliance & audit:** _PII / sensitive-data exposure, any new ActiveAdmin-editable values (enable PaperTrail or justify not), and mitigations._
- **Other risks:**

<!-- Optional checklist: keep only the rows you've thought through; delete the rest -->
## Additional Considerations

- **Monitoring & alerting plan:**
- **Scalability:**
- **Performance impact** (usually mandatory — if skipping, say why):
- **Cache considerations** (Redis usage: est. # keys + size per key):
- **Impact on other teams:**
- **Cost considerations:**
- **Privacy & security considerations:**
- **Support considerations:**
- **Third-party services & platforms:**

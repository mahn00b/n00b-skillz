<%*
const title = await tp.system.prompt("Tech spec title");
await tp.file.move(`tech-specs/${title}/${title}`);
-%>
---
type: tech-spec
status: Draft
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
product-spec:
linear-project:
slack-channel:
eng-lead:
---

# <% title %>

## Overview

### Problem statement

_What are we solving and why? One or two paragraphs._

### Deliverables

- _Key deliverable_

## Technical Background

_Relevant logic/terminology to orient an engineer without prior context. Link to related docs._

### Current / existing solution

- **Description:**
- **Pros:**
- **Cons:**

## Recommended Solution

_Summary of the solution._

- **Pros & cons** (limitations, scalability):
- **Performance considerations** (impact on app performance?):
- **Permissioning / role restrictions:**

## Automated Testing

_Describe the coverage: which behaviors and edge cases are tested, and by which kind of test (unit / integration / system / component). Prose, not a checklist of whether testing was done._

### Engineering sign-offs

Include any cross-squad engineers if applicable.

| Name | Sign-off | Date |
|---|---|---|
| | | |

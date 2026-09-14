---
name: address-pr-comments
description: >
  Pull the unresolved review comments on the current branch's PR, classify each by severity,
  draft a proposed fix, and present everything as severity-grouped tables for approval BEFORE
  changing any code. Use whenever the user asks to address PR comments, work through review
  feedback, handle reviewer comments, or resolve PR threads. This is a review-and-approve flow:
  nothing gets edited until the user signs off.
argument-hint: "[PR number] (optional — defaults to the current branch's open PR)"
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, AskUserQuestion
---

# address-pr-comments

Turn a pile of PR review feedback into a clear, severity-ranked plan the user approves before
anything changes. The guiding principle: **propose first, act second.** Draft a solution for
every comment, surface the ambiguous ones as explicit questions, lay it all out in tables, and
only touch the code once the user has approved specific items.

## Step 1: Fetch the unresolved comments

```bash
bash <skill-dir>/fetch_comments.sh [PR_NUMBER]
```

`<skill-dir>` is this skill's own directory. `PR_NUMBER` is optional — omit it to auto-detect
the open PR for the current branch. If the script errors (no open PR), tell the user and
suggest passing a number explicitly.

The output has two parts:

1. **Unresolved comment threads** — file/line review comments (each carries a `thread_id` and
   `reply_to_comment_id`, and may be flagged `[OUTDATED]`).
2. **Top-level PR comments** — issue-level comments with no file/line (bots already filtered
   out). These can't be "resolved", only replied to.

## Step 2: Classify severity and draft a solution for each comment

For every thread and top-level comment, work out two things: **how serious it is** and **what
you'd do about it.** Read the referenced code (`path:line`) before drafting a solution — a fix
proposed without looking at the surrounding code is a guess.

Severity is about impact if left unaddressed, not about how much code it takes to fix:

| Severity   | What belongs here                                                                                                                              |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **High**   | Correctness bugs, security/privacy issues, data loss, broken behavior, N+1s on hot paths, anything a reviewer flags as blocking merge.          |
| **Medium** | Real maintainability or design concerns, missing test coverage, unhandled edge cases, non-blocking "please change this" requests.               |
| **Low**    | Nits, naming/style preferences, optional suggestions, doc tweaks, open-ended questions, praise that needs only a reply.                          |

Some comments need no code change — mark them so they don't clutter the fix plan:

- **Already addressed / OUTDATED** — the code already reflects the request. Solution = reply
  confirming it's done, then resolve.
- **Dismissed by author** — the PR author already replied dismissing it. Solution = resolve, no
  change.

## Step 3: Ask clarifying questions for anything ambiguous

Before presenting the plan, resolve genuine ambiguity — a comment with multiple valid
interpretations, or where the right fix depends on intent you don't have. Use the
**`AskUserQuestion`** tool so the user gets the same click-to-select option UI as normal chat.
Batch related questions together; give each a small set of concrete options (plus the implicit
"Other"). Don't ask about comments whose fix is unambiguous — save the questions for real forks
in the road. Fold the answers back into the drafted solutions before moving on.

## Step 4: Present the plan as severity-grouped tables

Show the user **three tables — High, then Medium, then Low** (omit a table if that bucket is
empty). Keep rows scannable; put detail in the solution cell. Use this shape:

```
### 🔴 High severity

| # | Location        | Reviewer  | Comment (summary)              | Proposed solution                          |
|---|-----------------|-----------|--------------------------------|--------------------------------------------|
| 1 | app/foo.rb:42   | alice     | N+1 on `orders.each`           | Preload with `.includes(:line_items)`      |

### 🟡 Medium severity
...

### 🟢 Low severity
...
```

The `#` is a stable handle the user references to approve items. Below the tables, list any
**no-change items** (already-addressed / dismissed) separately so the user sees they were
considered, and note they'll just be replied to and resolved.

Then ask what to apply — e.g. "all", "just High + Medium", or specific numbers. Wait for an
explicit answer. **Do not edit any code before this point.**

## Step 5: Perform the approved changes

For each approved item:

1. Make the code change.
2. Reply to the thread confirming the fix, then resolve it.

Replies **must** be prefixed with `[ai]` on its own line so it's clear the response was
AI-generated:

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments -f body="[ai]
<reply>" -F in_reply_to=<reply_to_comment_id>
```

Resolve a thread:

```bash
gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "<thread_id>"}) { thread { isResolved } } }'
```

Top-level PR comments have no `thread_id` — reply with a new issue comment (they can't be
resolved):

```bash
gh pr comment {pr} --body "[ai]
<reply>"
```

Resolve `{owner}/{repo}` and `{pr}` once up front:

```bash
gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'
gh pr view --json number --jq '.number'
```

After all code changes, run the repo's linter/formatter over the modified files and fix
anything it flags before finishing.

## Step 6: Summary

Report back:

- What was changed and which threads were replied to / resolved.
- Items the user declined or deferred.
- Anything still needing a decision.

## Guardrails

- **Never edit code before Step 4 approval** — that separation is the whole point of this skill.
- **Load the `technical-writing` skill** before drafting any reply, and hold each one to the
  inline-review-comment register: Tier 1, no Tier 2. One claim per reply, lead with it, and
  never name a ticket identifier.
- **Every reply posted to a PR** — thread reply or top-level comment — **must be prefixed with `[ai]` on its own line**, so it's always clear the response was AI-generated.
- Never resolve a thread without either a code fix or a reply explaining why no change is needed.
- For OUTDATED threads already satisfied by the code, still reply confirming before resolving.
- When reviewer intent is unclear, ask (Step 3) rather than guessing at a fix.

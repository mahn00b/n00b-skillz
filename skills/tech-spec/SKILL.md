---
name: tech-spec
description: Start a new engineering tech spec in your document store and drive the conversation to fill it in. Creates tech-specs/{name}/{name} from the bundled tech-spec template, pre-fills what it can (optionally from a product-spec link), then asks targeted questions to build out the spec. Use when the user wants to write, start, or draft a tech spec / technical design doc — pass --long-form to force the heavyweight planning sections. After creation, the rest of the session is oriented around building up that one spec.
argument-hint: <title> [--prd <prd-url>] [--long-form]
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, WebFetch
---

# tech-spec

Create a new engineering tech spec in the user's document store and then interactively build it up with the user. Once created, **the working document for the rest of this session is that spec** — subsequent questions and answers update it in place.

## Writing rules (keep it lean)

**Load the `technical-writing` skill and hold every edit to it.** It owns voice, economy,
citation, diagrams, and evidence across all engineering prose — Tiers 1 and 2 both apply to a
spec. The rules below are the spec-specific additions: what each section is for and when it
earns its place.

First-pass specs balloon fast. A reader should skim one and understand the shape of the work
without wading through repetition or premature implementation detail.

1. **Proposed solutions are ideas, not implementations.** Keep the Recommended Solution
   high-level and descriptive — the shape of the approach and why it's right, not
   method-by-method detail. When the work genuinely introduces new classes, models, or APIs,
   document those in their dedicated sections (Data Model, APIs, Frontend) rather than inflating
   the solution narrative.
2. **Release / Rollout is for big work only.** Draft the Release / Rollout section only for
   multi-sprint, multi-PR projects. For a single-PR change, delete it.
3. **So is heavyweight planning.** Same gate for **Milestones & Overall Timeline** and
   **Proposed Work** — keep them only on multi-sprint / multi-PR projects; a single-PR spec
   doesn't need a milestone table or a work-breakdown grid.
4. **Scope is a section, not an afterthought.** Keep Deliverables and an **Out of scope** `###`
   subheading together under the Overview/Scope section; never trail "out of scope" as a one-off
   line at the end.
5. **Recommended Solution opens with a goal statement.** Lead with one sentence naming what the
   change creates or achieves (e.g. "Add a retry queue to the webhook dispatcher so failed
   deliveries are retried with backoff instead of dropped"), then the approach.
6. **Recommended Solution builds on the Technical Background.** Describe how the components
   named there change or behave differently after the work — reuse their names instead of
   re-introducing them.
7. **Recommended Solution carries at least one diagram.** Include a Mermaid diagram of the
   post-change flow or structure, so the shape of the approach is legible without reading prose.

## Document store

Specs live in a **document store**, configured by `DOC_STORE` and `DOC_STORE_PATH`. Read
`references/document-stores.md` before the first step: it defines the store operations used
below (`setup`, `exists`, `create`, `update`, `locate`) and how each supported store performs
them. Never touch the store any other way, and never hard-code a store location.

`<skill-dir>` is this skill's own directory, wherever it's installed. The bundled template is
`<skill-dir>/assets/tech-spec-template.md`.

## 1. Set up the store

Resolve the store from its configuration and run its `setup` operation. If setup fails, report
why and stop.

## 2. Parse the arguments

`$ARGUMENTS` is a positional title plus optional flags:

- **`<title>`** (positional) — everything that isn't a flag or flag value is the spec title, e.g. `Checkout retry flow redesign`. This is the primary input.
- **`--prd <prd-url>`** — a product-requirements / product-spec link. Capture the URL; if it's fetchable, you may WebFetch it to seed the problem statement and deliverables.
- **`--long-form`** (boolean, no value) — force the **long-form** spec: keep the heavyweight planning sections (Milestones & Overall Timeline, Proposed Work, Release / Rollout) regardless of apparent size. When the flag is **absent**, you decide long-form vs. lean by sizing the work yourself (see the scope gate in step 5).

If no title was given, ask the user for a short one.

If a PRD lookup fails, tell the user and continue with what you have — a missing link is not a blocker.

Derive a **slug** from the title: lowercase, spaces → hyphens, strip characters other than `[a-z0-9-]`, collapse repeats. Keep a human-readable **display title** (the original) for the document heading.

## 3. Create the spec

The spec's store path is `tech-specs/{slug}/{slug}`. If it already `exists`, **stop and tell the user** — don't overwrite. Offer to continue the existing one instead.

Otherwise, read the bundled template and `create` the spec from it with these substitutions:

- `{{TITLE}}` → the display title
- `{{DATE}}` → today's date as `YYYY-MM-DD` (both `created` and `updated` in the frontmatter)

## 4. Pre-fill what you can

Before asking anything, fill in everything already known — do not ask for information you already have:

- **From `--prd`:** set the `product-spec` frontmatter field. If it's a fetchable URL, you may WebFetch it to seed the problem statement and deliverables.
- **From the conversation so far / repo context:** if the user has already described the work, draft the Problem statement, Deliverables, and a high-level Recommended Solution. Ground any technical claims in the actual codebase — read relevant files rather than guessing. Per the writing rules, keep concrete code and `path:line` references in Technical Background; keep the solution itself descriptive.

Leave every field you genuinely don't know as its template placeholder. Never invent dates, names, or ticket numbers.

## 5. Prune, then interview for the gaps

The bundled template is deliberately robust and **most specs don't need every section**. Work the spec toward a solid draft in a few focused rounds rather than one giant questionnaire:

1. **Propose a section list.** Based on what the spec is, tell the user which optional sections you'd keep and which you'd delete (the template marks optional sections with `<!-- Optional -->`). First settle the **scope gate** — long-form vs. lean:
   - If **`--long-form`** was passed, it's long-form: keep **Milestones & Overall Timeline**, **Proposed Work**, and **Release / Rollout**.
   - Otherwise, size the work yourself. Treat it as long-form only when it's genuinely multi-sprint / multi-PR (multiple milestones, phased rollout, several engineers or PRs). A single-PR / single-sprint change is lean — delete those three sections outright (writing rules 2–3). When it's a close call, state your read and let the user override.

   Other common prune candidates regardless of size: Data Model changes, APIs, Frontend, QA, Rollback, Additional Considerations. Confirm, then delete the sections they don't want.
2. **Ask targeted questions for the gaps** — use `AskUserQuestion` for choices with clear options (rollout strategy, feature-flag vs direct ship, testing scope) and plain prose questions for open-ended detail. Batch related questions; keep each round small. Prioritize the sections that drive alignment: Problem statement, Deliverables / Out of Scope, Recommended Solution, Risks, and (for multi-PR work) Milestones and Rollout.
3. **Write answers straight into the spec** with `update` after each round, and bump the `updated` frontmatter date. Show the user what changed rather than pasting the whole document.

Don't block on exact dates or ticket numbers — flag them as TODO and move on.

## 6. Orient the rest of the session around this spec

After the initial draft, state plainly that this spec is now the working document, and that follow-up messages will continue to refine it. For the remainder of the session, treat further requests as edits to this spec (unless the user clearly changes topic): keep updating the same document, keep the `updated` date current, and re-run the prune/interview loop as the spec grows.

## 7. Report back

Output:

- Where the spec lives, from the store's `locate`
- The display title
- Which sections you kept vs. deleted
- The top 2–3 gaps still needing input, as the immediate next step

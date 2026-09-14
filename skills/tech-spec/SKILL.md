---
name: tech-spec
description: Start a new engineering tech spec in your notes vault and drive the conversation to fill it in. Creates tech-specs/{name}/{name}.md from the bundled tech-spec template, pre-fills what it can (optionally from a Linear ticket/project or product-spec link), then asks targeted questions to build out the spec. Use when the user wants to write, start, or draft a tech spec / technical design doc — pass --mini for a stripped-down half-page spec (mini tech spec), --long-form to force the heavyweight planning sections. After creation, the rest of the session is oriented around building up that one spec.
argument-hint: <title> [--linear <project-or-ticket-url>] [--prd <prd-url>] [--mini | --long-form]
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, WebFetch, mcp__plugin_linear_linear__get_issue, mcp__plugin_linear_linear__get_project, mcp__plugin_linear_linear__list_projects
---

# tech-spec

Create a new engineering tech spec in the user's notes vault and then interactively build it up with the user. Once created, **the working document for the rest of this session is that spec file** — subsequent questions and answers update it in place.

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
   change creates or achieves (e.g. "Create a parser within the billing plan composer to produce
   structured views of outstanding liability over time"), then the approach.
6. **Recommended Solution builds on the Technical Background.** Describe how the components
   named there change or behave differently after the work — reuse their names instead of
   re-introducing them.
7. **Recommended Solution carries at least one diagram.** Include a Mermaid diagram of the
   post-change flow or structure, so the shape of the approach is legible without reading prose.
8. **Leave author-owned metadata for the author.** Project-management placeholders — PM / owner,
   target dates, milestone targets, and the sign-off table — are the spec author's to fill when
   they migrate the doc out of the vault (into the tracker, etc.). Leave them as `_TODO_` in their
   home field; never promote them into Open Questions, and don't ask the user to fill them.

### `--mini` (same rules, smaller template)

The rules above and the `technical-writing` skill apply identically to every spec. **Mini and
full differ only in the template — which sections exist — never in writing style.** The mini
template ships a reduced section set; don't reintroduce a section it omits (General Info,
Relevant Tickets, Trade-offs, Data Model, APIs, Frontend, Events, Milestones, Proposed Work, QA,
Release / Rollout, Risks). If one turns out to be genuinely load-bearing, say so and offer the
full template instead of growing the mini one.

## Paths

Two placeholders resolve per user — never hard-code either:

- **`$SPEC_VAULT`** — the notes vault (or plain docs directory) specs live in. Read it from the `SPEC_VAULT` environment variable; if unset, ask the user for the path once and use it for the rest of the session.
- **`<skill-dir>`** — this skill's own directory, wherever it's installed.

Derived from those:

- **Specs folder:** `$SPEC_VAULT/tech-specs`
- **Vault Templater templates:** `$SPEC_VAULT/Templates/Tech Spec.md` and `.../Templates/Mini Tech Spec.md` (Obsidian only — skip if the vault isn't an Obsidian vault)
- **Bundled markdown templates:** `<skill-dir>/assets/tech-spec-template.md`, `<skill-dir>/assets/mini-tech-spec-template.md`
- **Bundled Templater templates:** `<skill-dir>/assets/Tech Spec.md`, `<skill-dir>/assets/Mini Tech Spec.md`

## 1. Ensure the Obsidian templates are installed

Skip this step entirely when the vault isn't an Obsidian vault (no `.obsidian/` directory). Otherwise, for each of `Tech Spec.md` and `Mini Tech Spec.md`, check whether it exists in `$SPEC_VAULT/Templates/`. Copy any that's missing so the user can also spawn specs natively from Obsidian:

```bash
cp -n "<skill-dir>/assets/Tech Spec.md" "$SPEC_VAULT/Templates/Tech Spec.md"
cp -n "<skill-dir>/assets/Mini Tech Spec.md" "$SPEC_VAULT/Templates/Mini Tech Spec.md"
```

Do not overwrite an existing template.

If the vault reads back `Operation not permitted` and it lives under `~/Documents` on macOS, TCC is denying this launch context access to that folder. Confirm with `stat` (metadata succeeds) versus `head -c1` (content is denied). The fix is granting the host terminal app the Documents folder under Privacy & Security — it takes effect on the running process, so no restart is needed. Report it and stop; never propose relocating the vault.

## 2. Parse the arguments

`$ARGUMENTS` is a positional title plus optional flags:

- **`<title>`** (positional) — everything that isn't a flag or flag value is the spec title, e.g. `Checkout retry flow redesign`. This is the primary input.
- **`--linear <project-or-ticket-url>`** — a Linear project or ticket URL/ID (e.g. `ABC-123` or a `linear.app/...` link). Fetch it with the Linear MCP tools (`get_issue` / `get_project`, resolving via `list_projects` if needed) and capture its URL and description to pre-fill later.
- **`--prd <prd-url>`** — a product-requirements / product-spec link. Capture the URL; if it's fetchable, you may WebFetch it to seed the problem statement and deliverables.
- **`--mini`** (boolean, no value) — use the **mini** template (`assets/mini-tech-spec-template.md`) instead of the full one. Six headings only: Overview (Problem statement, Deliverables), Technical Background (Current / existing solution), Recommended Solution, Automated Testing, Engineering sign-offs. Skips the prune round in step 5 entirely — the section list is already fixed.
- **`--long-form`** (boolean, no value) — force the **long-form** spec: keep the heavyweight planning sections (Milestones & Overall Timeline, Proposed Work, Release / Rollout) regardless of apparent size. When the flag is **absent**, you decide long-form vs. lean by sizing the work yourself (see the scope gate in step 5).

`--mini` and `--long-form` are mutually exclusive. If both appear, ask which one they meant rather than guessing.

**Title precedence:** the positional title wins. If no title was given but `--linear` was, derive the title from the Linear ticket/project name. If neither yields a title, ask the user for a short one.

If a Linear or PRD lookup fails, tell the user and continue with what you have — a missing link is not a blocker.

Derive a **slug** from the title: lowercase, spaces → hyphens, strip characters other than `[a-z0-9-]`, collapse repeats. Keep a human-readable **display title** (the original) for the note heading.

## 3. Create the spec note

Target folder-per-spec, mirroring the `tickets/` convention:

- Folder: `tech-specs/{slug}/`
- File:   `tech-specs/{slug}/{slug}.md`

If the folder or file already exists, **stop and tell the user** — don't overwrite. Offer to open/continue the existing one instead.

Otherwise:

```bash
mkdir -p "$SPEC_VAULT/tech-specs/{slug}"
```

Read the bundled template — `assets/mini-tech-spec-template.md` when `--mini` was passed, otherwise `assets/tech-spec-template.md` — then write it to the target file with substitutions:

- `{{TITLE}}` → the display title
- `{{DATE}}` → today's date as `YYYY-MM-DD` (both `created` and `updated` in the frontmatter)

## 4. Pre-fill what you can

Before asking anything, fill in everything already known — do not ask for information you already have:

- **From `--linear`:** set the `linear-project` frontmatter field and the General Info "Linear project" row to the URL, and list the ticket/project under **Relevant Tickets**. Seed the Overview → Problem statement from the ticket description (prefixed with `> From Linear:` so the user knows to rewrite it).
- **From `--prd`:** set the `product-spec` frontmatter field and the General Info "Product spec" row. If it's a fetchable URL, you may WebFetch it to seed the problem statement and deliverables.
- **Under `--mini`:** the General Info table and Relevant Tickets don't exist. The frontmatter carries those links instead — set `linear-project` / `product-spec` there and nowhere else.
- **From the conversation so far / repo context:** if the user has already described the work, draft the Problem statement, Deliverables, and a high-level Recommended Solution. Ground any technical claims in the actual codebase — read relevant files rather than guessing. Per the writing rules, keep concrete code and `path:line` references in Technical Background; keep the solution itself descriptive.
- Set `eng-lead` to the user unless told otherwise.

Leave every field you genuinely don't know as its template placeholder. Never invent sign-offs, dates, names, ticket numbers, or story points.

## 5. Prune, then interview for the gaps

The bundled template is deliberately robust and **most specs don't need every section**. Work the spec toward a solid draft in a few focused rounds rather than one giant questionnaire:

**Under `--mini`, skip sub-step 1 outright** — the section list is the template's, and there's no scope gate to settle. Go straight to sub-step 2 with a single round covering Problem statement, Deliverables, and Recommended Solution, then write it and stop. Cut any section that comes back empty rather than leaving its placeholder.

1. **Propose a section list.** Based on what the spec is, tell the user which optional sections you'd keep and which you'd delete (the template marks optional sections with `<!-- Optional -->`). First settle the **scope gate** — long-form vs. lean:
   - If **`--long-form`** was passed, it's long-form: keep **Milestones & Overall Timeline**, **Proposed Work**, and **Release / Rollout**.
   - Otherwise, size the work yourself. Treat it as long-form only when it's genuinely multi-sprint / multi-PR (multiple milestones, phased rollout, several engineers or PRs). A single-PR / single-sprint change is lean — delete those three sections outright (writing rules 4–5). When it's a close call, state your read and let the user override.

   Other common prune candidates regardless of size: Data Model changes, APIs, Events, Notification campaigns, Coordinated launch, Rollback. Confirm, then delete the sections they don't want.
2. **Ask targeted questions for the gaps** — use `AskUserQuestion` for choices with clear options (rollout strategy, feature-flag vs direct ship, testing scope) and plain prose questions for open-ended detail. Batch related questions; keep each round small. Prioritize the sections that drive alignment: Problem statement, Deliverables / Out of Scope, Recommended Solution, Risks, and (for multi-PR work) Milestones and Rollout.
3. **Write answers straight into the file** after each round, and bump the `updated` frontmatter date. Show the user what changed rather than pasting the whole file.

Don't block on sign-off tables, exact dates, or ticket numbers — those get filled in later by the user or during planning. Flag them as TODO and move on.

## 6. Orient the rest of the session around this spec

After the initial draft, state plainly that this spec file is now the working document, and that follow-up messages will continue to refine it. For the remainder of the session, treat further requests as edits to this spec (unless the user clearly changes topic): keep editing the same file, keep the `updated` date current, and re-run the prune/interview loop as the spec grows.

A mini spec stays mini. If follow-ups start pulling it toward sections the mini template omits, say so and offer to regenerate from the full template rather than bolting them on.

## 7. Report back

Output:

- The full path to the created spec note
- The display title
- Which sections you kept vs. deleted
- The top 2–3 gaps still needing input, as the immediate next step

## Publish to Linear

Specs live in the vault and publish to Linear as documents. Author the `.md` in the vault, then push it to the project's Linear doc via the Linear MCP `save_document`. Linear renders Mermaid natively and stores images in-doc.

Linear has its own markdown dialect — collapsibles are `>>>` fences, not `<details>`; links get wrapped; images are bare re-signed URLs. Prefer `patch` over a full overwrite so uploaded images survive.

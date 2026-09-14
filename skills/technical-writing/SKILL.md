---
name: technical-writing
description: >
  The house writing rules for engineering prose — economy, citation, diagrams, and evidence.
  Load before drafting or editing any technical document or comment: a tech spec, PR
  description, PR review comment, tracker ticket, ticket note, engineering guide,
  postmortem, or repo doc. Owns voice and structure discipline; the consuming skill owns
  which sections its document has.
---

# technical-writing

One voice across every engineering document. **Tier 1 applies to everything.** Tier 2 applies
to long-form documents. Inline review comments take Tier 1 plus the routing note at the end.

This skill does not cover **code comments** — the repo's own agent instructions (`CLAUDE.md`,
`AGENTS.md`) own those, and their rules win inside source files.

## Tier 1 — Always

1. **Size the writing to the work.** A single-PR change reads in well under a page; a one-file
   change gets a few sentences and a bullet or two. Don't pad a small change to look like a big
   one. Scale up only when the work is genuinely multi-PR.
2. **Don't repeat yourself.** State the problem, the change, and the reasoning once, in the
   section that owns them. Later sections add new information rather than re-summarizing
   earlier ones. Restate something only when it's genuinely needed to make a new point land.
3. **State each decision (and its "why") once.** Put the justification for an approach in
   exactly one place. When the same "why" turns up in three sections, keep the fullest and
   reference it elsewhere.
4. **Cut analysis that doesn't change a decision.** Investigation narrative, pros/cons lists,
   alternatives considered, and supporting data earn their place only when they actually drive
   or defend the chosen approach. Prevalence numbers justify a fix's existence; a table of them
   rarely does.
5. **No narration or hedging.** Drop meta-commentary, throat-clearing, and vague qualifiers
   ("safe-ish", "basically", "as mentioned above", "worth noting"). Prefer tight, single-clause
   bullets over prose paragraphs. When explaining a set of components, fields, or options and
   why each exists, use a term–definition list (**`term`** — definition), not a paragraph that
   strings them together — a wall of prose hides the individual points.
6. **Describe behavior, not code churn.** Write each item as what the change does or delivers.
   Name a concrete class, file, or utility only when it clarifies the explanation or tells the
   reader where to look — otherwise leave code detail to the diff.
7. **Describe the invariant, not the execution path.** State the semantic guarantee relevant to
   the change — what must hold, what a value means — instead of walking the reader down a chain
   of nested method calls. A call-by-call trace is noise that belongs to code review.
8. **Reference code freely; keep implementation out.** Cite code by `path:line` and name the
   real classes, models, and methods wherever it grounds a claim. What stays out is
   *implementation*: pasted code blocks, diffs, and method-by-method detail. A reference points
   a reader at the code; a diff prescribes it. When the reader already has the diff, a
   description that reproduces it is noise.
9. **Link every PR, issue, and file reference.** A `#1234`, `PR #1234`, or issue mention is a
   hyperlink to its URL wherever it appears, never a bare number
   (`https://github.com/<owner>/<repo>/pull/<n>`). Link file paths to the file on GitHub
   (`.../blob/<default-branch>/<path>`, or `/tree/` for a directory), taking owner/repo and
   default branch from the repo's `origin` remote. Leave a path unlinked only when it isn't on
   the default branch yet — note that inline.
10. **Ship no unfilled prompts.** Delete any template section or sub-bullet that has nothing
    real to say rather than leaving its placeholder. Required checkboxes, frontmatter, and
    sign-off tables are the exceptions — they stay for a human to fill.

## Tier 2 — Long-form documents

Specs, engineering guides, postmortems, PR descriptions, ticket notes, and repo docs. Skip this
tier entirely for inline comments.

11. **Merge or delete "no-change" sections.** Don't give a section its own heading just to
    announce an absence. When several amount to "nothing new," fold them into a single line
    (e.g. "Data Model / APIs / Frontend: no schema changes, no new endpoints, no new
    components"). Delete a section outright when it says nothing.
12. **Trim scaffolding to what carries information.** Boilerplate tables (General Info,
    sign-offs) keep the rows holding real values plus the few that matter as TODO; collapse or
    drop the rest rather than parading empty placeholders.
13. **Cite references in the document that makes the claim.** Collect a document's linked
    citations in its own References section, backing the statements that document makes. In a
    multipart document, the overview references only what its own text relies on; phase-specific
    references live in each phase document, not hoarded in the overview.
14. **Diagram the background, don't narrate it.** Background sections exist to illustrate the
    high-level components the work builds on. Prefer a Mermaid diagram (most renderers handle
    ` ```mermaid ` fences natively) over prose, and show how the pieces connect rather than
    every detail.
15. **Preface every diagram.** A diagram never stands alone. Precede each with a sentence or two
    saying what it shows and what to look for, so a reader understands it before parsing the
    nodes — never "component X matters" followed immediately by an unexplained flow. The preface
    orients; the diagram illustrates.
16. **Author every Mermaid diagram per the `mermaid` skill.** It owns diagram-type selection
    (flowchart / sequence / ER / gantt / gitGraph / state), the compact styling header,
    orientation, and label quoting — load it whenever you add or edit a diagram.
17. **Show new data structures, don't just name them.** When the work adds a column, payload, or
    config shape, paste a short concrete example (a representative JSON/hash literal) and say
    why it's shaped that way — the structural trade-off, not the field list the reader can see.
    Pretty-print every JSON literal — one field per line, 2-space indent — never a single-line
    blob.
18. **Scale claims carry napkin math.** Whenever the writing asserts a load, cost, or scaling
    concern (rate limits, connection counts, query volume), back it with a quick best-case /
    worst-case estimate — state the assumptions (users, actions/interval, calls/action), multiply
    them out, and compare to the ceiling. A named worst case the reader can check beats "this
    could get expensive." Put the arithmetic in a fenced code block, not woven into a sentence —
    a worked calculation reads more cleanly stacked (assumption → multiply → result → ceiling).
19. **Describe every frontend component as a card in a preview grid.** Whenever frontend
    components are introduced or described, present them in a table — one row per component
    (a "card") — carrying a cropped screenshot preview captured from the design source (saved
    under the document's `images/` and referenced relatively), the component name, a link to
    that node in the design tool, and a one-line semantic description plus a build/reuse note.
    Never a prose inventory. When no design exists yet, keep the table and mark the preview and
    link pending.
20. **Testing describes coverage, not completion.** Write which behaviors and edge cases are
    covered and by which kind of test (unit / integration / system / component), as prose. It is
    not a checkbox list of whether testing happened.
21. **Front-load the key touchpoints; push background to the end.** A reader spends attention
    top-down — lead with problem, deliverables, and what changes, and move reference-grade
    material (technical background, component glossaries, deep mechanics) toward the end,
    appendix-style. A section that only matters to a reader who wants more detail belongs after
    the ones every reader needs.
22. **Open a section with its takeaway, bolded.** Lead each substantive section with a single
    bolded sentence stating the point, so a skimming reader catches it before the supporting
    detail. The bold is the one line they must not miss.
23. **Enumerated steps or strategy get a real numbered list.** When you name an ordered set —
    the phases of a strategy, a sequence of steps — use a `1./2./3.` list, never inline
    "(1)… (2)… (3)…" buried in a sentence.
24. **Don't nest substantive sections under a generic wrapper.** Give each real section its own
    top-level heading rather than burying Problem statement, Deliverables, and the rest under a
    catch-all "Overview." A wrapper heading that only groups adds a level of nesting without
    adding information.
25. **Leave a pointer where you move detail from.** When you relocate a section (background to
    the end, a detail into an appendix), drop a one-line signpost at the spot the reader first
    wants it, linking to where it now lives — the reader following the narrative shouldn't hit a
    hole.
26. **A load-bearing invariant gets its own heading.** When a guarantee governs many parts of the
    design (a visibility rule, an ordering constraint), give it a named section of its own rather
    than embedding it in a paragraph — so it is findable and citable.

## Inline review comments

PR review replies, batched review findings, and Hunk session comments. **Tier 2 does not
apply** — no diagrams, no References section, no component tables. Tier 1 does, and rules 2, 5,
6, 7, and 9 carry the most weight: one claim per comment, no preamble before it, the invariant
rather than the trace, and a real link instead of a bare reference.

Four additions specific to the register:

27. **Never put ticket identifiers or ticket sequences in a review comment.** Ticket context
    belongs in the PR description and the tracker. This holds for individual identifiers
    (`ABC-123`, `[XYZ-…]`) and sequences alike.
28. **Don't pad to look thorough.** Six real findings beat fifteen with nine hedges. A comment
    you can't tie to a concrete consequence doesn't get written.
29. **Compose, then ship only the compression.** Draft a finding in parts if it helps you think
    — the claim, the mechanism that produces it, the consequence — then post the claim and the
    consequence in two or three sentences and let the mechanism live in the `path:line` you cite.
    The reader has the code; a comment that re-derives it is a comment they have to skim. Write
    the short version first where you can: a finding you can only state at length is usually one
    you haven't reduced yet.
30. **When the remedy is one line, lead with it.** "These failures have no visibility — a log
    line when the retry budget runs out would be enough" replaces a paragraph deriving how the
    budget runs out. Proving the problem at length is how a comment gets long; naming the fix is
    how it gets short.

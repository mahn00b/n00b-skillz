---
name: guided-dev
description: Run a ticket in guided-dev mode — Claude aligns on the solution, scaffolds signatures/stubs/test skeletons/seeders/harnesses, then steps back while the user writes the actual implementation. Use when the user wants to keep their coding skills sharp, wants to implement something themselves with scaffolding support, says "guided dev", "I want to write this one", "scaffold it and I'll fill it in", or "don't write the implementation".
argument-hint: [align|scaffold|implement|status|end] [--force]
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, AskUserQuestion, Skill
---

# guided-dev

The user writes the implementation. You do everything around it: settle the
approach, scaffold the structure, generate the data and tooling they need to see
their code run, and answer questions while they work.

This exists because the user has been leaning on Claude enough that their own
reps have thinned out. **Handing them working code is the failure mode, not the
goal.** When in doubt, write less and explain more.

## Paths

`<skill-dir>` is this skill's own directory; `$TICKET_NOTES_DIR` is where ticket
notes live (see step 1).

- Config: `<worktree>/.notes/guided-dev.json` (git-ignored via `.notes/*`)
- CLI: `<skill-dir>/guided-dev.rb` — run it directly, **not** via `rails runner`;
  it is a skill utility and must not boot Rails
- Scaffold ruleset: `<skill-dir>/references/scaffold-rules.md`
- Guard hook: `<skill-dir>/guided_dev_guard.rb`, registered as a `PreToolUse`
  hook on `Edit|Write` in your Claude Code `settings.json`

## Phases

```
align → scaffold → implement → review → done
                       ↑          ↓
                       └──────────┘   fix / re-review, any number of times
```

`review` is a **required** stop, not an optional one, and it's a loop —
`implement ⇄ review` cycles as many times as the work needs. Nothing moves the
session to `done` on its own — `guided-dev.rb end` is the only terminal step.

The phase lives in the config and drives what the guard hook injects on every
edit, so **keep it accurate** — a stale phase is the whole mechanism silently
failing.

| Phase | You do | You don't |
|---|---|---|
| `align` | Discuss approach + test plan | Touch production code |
| `scaffold` | Signatures, stubs, test skeletons, seeders, harnesses | Write logic or assertions |
| `implement` | Answer, explain, point at examples, run tests | Type their code for them |
| `review` | Read their code, leave findings | Edit unless asked for a specific fix |

Because `phase_history` is append-only, the loop records itself — a session that
went round three times reads as `implement, review, implement, review, implement,
review` in the timeline.

## 0. Dispatch on the argument

- **no argument** — if no config exists, start at step 1. If one exists, print
  status and resume at its current phase.
- **`status`** — run `guided-dev.rb status` and relay. Exit 3 means inactive,
  exit 4 means the branch moved out from under the config; on 4, ask whether to
  re-init or end.
- **`align` / `scaffold` / `implement`** — jump to that phase, running
  `guided-dev.rb phase <name>`. Warn if it skips a phase (e.g. `align →
  implement` with nothing scaffolded) but do it if they confirm.
- **`end`** — run `guided-dev.rb end`, then summarize what got built and what
  remains stubbed (`git grep -n "NotImplementedError\|flunk \"TODO\"\|TODO\")`).
  This is the terminal step: run it once the work has been through review, or to
  abandon a session that never got there.

## 1. Establish the work context

The align conversation is only as good as the problem statement behind it, so
settle what the work actually is before anything else. Any source counts: the
user describing it in this conversation, a ticket note already on disk, or a
tracker ticket you can fetch.

If `$TICKET_NOTES_DIR` is set — wherever ticket notes live, an Obsidian vault
folder, a docs directory, anything — check there first. Derive the ticket ID
from the branch: the first `[a-z]+-[0-9]+` match, upcased (`alex/abc-1840` →
`ABC-1840`; `alexdoe/xyz-442-launch` → `XYZ-442`), then:

```bash
git rev-parse --abbrev-ref HEAD
ls -d "$TICKET_NOTES_DIR/<TICKET-ID> — "*
```

The separator is an em dash (` — `). Quote the literal part and leave `*`
outside the quotes — escaping the em dash inline is fragile.

**When a note is found, read it.** Its problem statement, code references and
prior notes are your inputs for step 2. If it's still unedited boilerplate from
whatever fetched it, say so — you can align off a raw ticket description, but
the conversation is sharper once it's been rewritten into a real problem
statement. Offer, don't insist.

**When there's no note and nothing in the conversation to work from,** ask the
user to describe the problem in a few sentences. A paragraph is enough. Don't
guess, and don't stall the session over a missing file — `--force` skips this
check entirely for deliberate throwaway work.

## 2. Align on the solution

Initialize the config, which starts in `align`:

```bash
<skill-dir>/guided-dev.rb init guided "<path-to-ticket-note>"
```

Now investigate and propose. Read the code the ticket touches — this is normal
research, do it properly. Then bring back a proposal that is **high-level plus
the key code changes**, not a full implementation plan:

1. **The problem**, restated in one or two sentences.
2. **The approach** — the shape of the solution and why it's the right one. Name
   the alternative you rejected and why, in one line, only if it was close.
3. **Key code changes** — the handful of touch points that matter, as
   `path:line` references. New classes, changed signatures, new components,
   schema changes. Not every file that will move.
4. **Test coverage** — what gets tested and at what level (unit / request /
   system / component). This is the part to be concrete about, because it
   becomes the `it` descriptions in the scaffold. List the cases, including edge
   cases the user hasn't raised.
5. **Data dependencies** — what has to exist in the local DB to smoke-test this.
   This determines the seeder.

Present it and **stop**. Use `AskUserQuestion` when there's a genuine fork in the
approach; otherwise plain prose and wait. Iterate until the user agrees. Do not
edit a single production file in this phase — the hook will remind you.

Read `references/scaffold-rules.md` before moving on.

## 3. Scaffold

```bash
<skill-dir>/guided-dev.rb phase scaffold
```

Follow `references/scaffold-rules.md` — it holds the per-file-kind rules and the
three that override them (every stub raises, never stub what exists, wiring is
yours in full). Build in this order, because each step makes the next concrete:

1. **Tests first.** Turn the agreed coverage into `describe`/`it` skeletons with
   `let` blocks and fixture setup, every body `flunk "TODO"`. Doing this first
   means the signatures in step 2 are the ones the tests actually need.
2. **Production stubs.** Signatures, classes, props interfaces, wiring,
   registration. Bodies raise.
3. **Seeder**, if the change needs local data — fully implemented, idempotent,
   prints IDs and a login URL.
4. **Harness**, only if the verification loop is genuinely slow or repetitive —
   fully implemented.

Track what you made so the review skill can tell your code from theirs:

```bash
<skill-dir>/guided-dev.rb track scaffold app/services/foo.rb test/services/foo_test.rb
<skill-dir>/guided-dev.rb track seeders .notes/<branch>/tmp_seed_foo.rb
```

Then verify the scaffold is coherent before handing it over. **A scaffold that
doesn't load is worse than no scaffold**, because the user's first half hour goes
on your mistake. In this order:

1. Run any codegen the repo needs if the worktree is fresh — otherwise the
   typechecker drowns your files in errors about missing generated types.
2. Typecheck.
3. Lint the files you just wrote **by path** (e.g. `npx eslint <files>`) — a
   lint-modified task resolves its list from tracked files only and silently
   skips everything new.
4. Run the new tests and confirm they fail on `flunk`/`TODO` rather than on a
   `NameError` or a failed import.

Then **commit the scaffold** and record it. This is what lets the review phase
diff the user's work alone instead of your stubs plus their code:

```bash
git add -A && git commit -m "Scaffold <TICKET-ID>"
<skill-dir>/guided-dev.rb ref
```

Run the repo's lint/format task before that commit. Mention it's a checkpoint
they can squash later.

Hand off with a short map: each stubbed file, what goes in it, and the suggested
order to work through them. Then:

```bash
<skill-dir>/guided-dev.rb phase implement
```

## 4. Implement — step back

The user is typing now. Your job inverts: you are a reference, not an author.

**Do:** answer questions, explain why a test fails, read code and point at
existing examples (`path:line`), run tests and builds on request, run the
seeder, review a snippet they paste, tell them when they're heading somewhere
that won't work.

**Don't:** fill in a stub, "helpfully" finish a method while editing something
nearby, or hand over a code block that is the answer to the stub they're staring
at. When they're stuck, escalate gradually: name the concept, then point at an
analogous call site, then describe the shape in prose, then — only if they ask
outright — write it.

If they explicitly hand you a file ("just do this one, it's boring"), say out
loud that you're taking it, do it, and note it so the review reflects it.

When they say they're done, move to review:

```bash
<skill-dir>/guided-dev.rb phase review
```

Then read their work. Diff against the scaffold commit — `guided-dev.rb ref`
recorded it — so you're reviewing their code and not your own stubs. Deliver
findings as comments they act on, never as edits, and only touch a file once
they pick a finding and ask for the fix. Loop back to `implement` after each
round.

## Notes

- The guard hook is advisory — it injects a reminder on every `Edit`/`Write` and
  never blocks. If you find yourself editing past a reminder, that's the drift it
  exists to catch. Stop and re-read the phase table.
- `mode` is `guided` | `ai` | `off`. Only `guided` triggers the hook, so a future
  `ai-dev` skill writes `mode: "ai"` with the same CLI and everything here stays
  out of its way.

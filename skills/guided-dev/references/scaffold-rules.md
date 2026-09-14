# Scaffold rules

What a scaffold contains, per kind of file. **This file is meant to grow** — when
a case comes up that isn't covered, add a section rather than improvising twice.

## The universal line

A scaffold gives the user **structure without decisions**. Anything a reader
could not derive from the ticket and the surrounding code — names, arities,
return shapes, where a thing lives, which existing helper to reuse — belongs in
the scaffold. Anything that constitutes the actual reasoning of the change —
branch conditions, arithmetic, query composition, assertions — belongs to the
user.

Three rules that override everything below:

1. **Every stub raises or flunks.** A stub that returns `nil` compiles, passes,
   and lies. `raise NotImplementedError` / `flunk "TODO"` cannot be mistaken for
   done, and `git grep NotImplementedError` is the remaining-work checklist.
2. **Never stub what already exists.** Search first. If a method, hook, factory
   or fixture already does the job, wire it up and say so — a scaffold that
   reinvents an existing helper teaches the wrong thing.
3. **Imports, wiring and registration are yours, in full.** Route entries,
   feature-registry keys, GraphQL field mounting, barrel exports, DI
   registration. These are lookup work, not reps, and getting them wrong costs
   the user an hour of confusion for zero learning.

---

## Ruby — service / command object

Full: class, `include`/`extend`, `initialize` with real keyword args, public
method names, `private` marker, RBS-relevant docs.
Stubbed: every method body.

```ruby
module Refunds
  class HoursProration
    def initialize(enrollment:, as_of:)
      @enrollment = enrollment
      @as_of = as_of
    end

    # fee(tail) + max(tuition per leg)
    def amount
      raise NotImplementedError
    end

    private

    attr_reader :enrollment, :as_of

    def attended_hours
      raise NotImplementedError
    end
  end
end
```

## Ruby — model

Full: associations, validations, scopes' *names*, enums, `has_pii` declarations,
delegations. Stubbed: instance/class method bodies, and scope bodies where the
query is the interesting part.

Associations and validations are declarative lookup work — write them. A scope
whose body is `where(state: :active)` is also lookup work; write it. A scope
joining four tables with a window function is the reps; stub it.

## Ruby — job

Full: class, `queue_as`, `retry_on` / `discard_on`, `perform` signature.
Stubbed: `perform` body.

## Rails controller

Full: class, `before_action` filters, strong-params method, action names,
response format blocks. Stubbed: action bodies.

## GraphQL — type

Full: every `field` declaration with name, type, nullability, `description`,
arguments. Stubbed: only resolver methods that need custom logic; a field
resolving straight off the model needs no method at all.

Dataloader choice is a decision — leave a stub with the n+1 risk named:

```ruby
def enrollments
  # n+1 risk: batch by cohort_id
  raise NotImplementedError
end
```

## GraphQL — query / mutation

Full: class, `argument` declarations, `type` / `field` return declaration,
`authorize`d policy call if the pattern is established. Stubbed: `resolve` body.

Run the repo's GraphQL codegen as part of the scaffold so the user's TS types
exist before they start.

## React — component

Full: `Props` interface (every prop, typed, no `any`), component declaration,
destructured props, imports, the design-system wrapper skeleton with layout props,
and `export`. Stubbed: event handlers, derived state, conditional rendering.

```tsx
interface RefundEstimateProps {
  enrollmentId: string
  onConfirm: (amount: number) => void
}

export const RefundEstimate = ({ enrollmentId, onConfirm }: RefundEstimateProps) => {
  const handleConfirm = () => {
    throw new Error("TODO")
  }

  return (
    <VStack align="stretch" gap={4}>
      {/* TODO: estimate rows */}
      <Button onClick={handleConfirm}>Confirm</Button>
    </VStack>
  )
}
```

The `Props` interface is the highest-leverage thing to write in full — it is the
component's contract and it is pure lookup work. The JSX tree gets a skeleton
with the real wrapper components (so theme/layout conventions are right) and
`{/* TODO */}` where content goes.

## React — hook

Full: signature, return-type interface, the `useQuery`/`useMutation` call with
the real generated document and variables. Stubbed: transforms, memo bodies,
effect bodies.

## React — repo conventions

Repo-specific lookup work. Getting these wrong costs a typecheck round-trip, so
read them out of the codebase and write them right in the scaffold rather than
letting the user discover them. Before scaffolding the first component, settle:

- **Filename and directory casing**, and which directories are legacy. Match the
  newest files, not the oldest.
- **Where a primitive lives versus a composite.** Most design systems separate
  the two; find the boundary before choosing a path.
- **Export and declaration style** — named vs. default, function vs. arrow, how
  the props type is named and whether it's exported.
- **The design-system API in use, at the pinned version.** Props get renamed
  across major versions; grep for how the repo actually spells it rather than
  reaching for the version you remember.
- **Where icons and color tokens come from.** Invent no token names — read the
  theme file and use what's there.
- **Story and component-test boilerplate** — the `Meta`/`StoryObj` imports, the
  title convention, the render helper and providers a test needs. Copy the shape
  from the nearest existing example and cite it. Stories are **fully written** —
  they are the smoke test for a presentational component, not a stub. The test
  render helper is scaffolding; the assertions are not.

### Linting a scaffold

A lint task that resolves its file list from the diff against the default branch
(`--diff-filter=ACMR`) sees **tracked files only** — newly created scaffold files are
silently skipped and the run reports clean. Lint the paths directly instead:

```bash
npx eslint <the files you just wrote>
```

Two consequences of unused-by-design scaffold code:

- `no-unused-vars` fires on every stub parameter. A file-level
  `/* eslint-disable @typescript-eslint/no-unused-vars -- scaffold; delete when implemented */`
  is the cleanest suppression — one line, self-documenting, deleted by the user's
  first edit. Do **not** rename params to `_foo`; the user has to undo it.
- The **pre-commit hook runs `eslint --fix`, which deletes unused imports** and wins
  over that disable comment. Any import the scaffold provides for the user will be
  stripped if you commit. Prefer not committing a scaffold whose imports aren't yet
  referenced.

## Minitest

Full: `describe` nesting, every `it` description, `let` blocks, fixture and
factory setup, requires. Stubbed: **every assertion**, as `flunk "TODO"`.

`it` descriptions are the deliverable here — they are the test plan agreed in
the align phase, turned into executable placeholders. Write one per branch,
including the edge cases the user did not think of; a scaffolded `it` the user
deletes as unnecessary is still a useful prompt.

```ruby
describe Refunds::HoursProration do
  let(:enrollment) { enrollments(:active) }
  let(:proration) { Refunds::HoursProration.new(enrollment: enrollment, as_of: Date.current) }

  describe "#amount" do
    it "prorates tuition by hours attended" do
      flunk "TODO"
    end

    it "returns zero when no hours were attended" do
      flunk "TODO"
    end

    it "excludes the signup fee from the prorated portion" do
      flunk "TODO"
    end
  end
end
```

Prefer custom assertions from `test/support/test_assertions.rb` when naming what
a test should check — reference them in the description or a `let` so the user
reaches for the right one.

## Jest

Same split. `describe`/`it` structure, render helpers, mock setup and MSW
handlers in full; assertion bodies as `expect(true).toBe(false) // TODO`.

Mock and MSW handler setup is lookup work and often the fiddliest part of a
frontend test — write it completely.

## Seeders

**Fully implemented, always.** A seeder exists so a smoke test has data; a
stubbed seeder is useless. Rules:

- Live in `.notes/<branch>/tmp_seed_<thing>.rb`, run via
  `bundle exec rails runner`.
- Idempotent — safe to run twice. Find-or-create, and print what was reused.
- Print the IDs and a login path at the end. The user's next move is always
  "open this in the browser", so hand them the URL.
- Set a known password on any user created, per the repo's local-login convention.
- Never write to anything but the local dev database.

## Test harnesses

**Fully implemented, always.** A harness is a script that makes a slow or
awkward verification loop fast — a before/after differ, a bulk recompute, a
request replayer. Build one when the alternative is the user manually clicking
through the same flow more than about three times.

- Live in `.notes/<branch>/tmp_harness_<thing>.rb` (or `.ts`, run via `bun`).
- Print a diff or a pass/fail summary, not a wall of raw output.
- Take the interesting knobs as CLI args rather than requiring edits to run.

# N00b Skillz

## Description

A collection of some of my favorite agentic skills. At the time of this writing, all skills have been built in claude code, by anthropic models, to be used in claude code. 

Other than any that contain references to claude code specifically, all skills follow the Agent Skill spec and possibly can be used in other coding harnesses.

## Skills

**Six skills, grouped by what they help with.** Each one triggers from its slash command or from a matching request in plain language.

### Session context

- **[`/save-context`](https://github.com/mahn00b/n00b-skillz/tree/main/skills/save-context)** — writes a structured summary of the current conversation to `~/.claude-context/<repo>/<branch>/`, so work on the same branch stays consistent across sessions.
- **[`/load-context`](https://github.com/mahn00b/n00b-skillz/tree/main/skills/load-context)** — loads the most recent summary saved by `/save-context` for the current worktree and branch.

### Writing and docs

- **[`/technical-writing`](https://github.com/mahn00b/n00b-skillz/tree/main/skills/technical-writing)** — house rules for engineering prose: economy, citation, diagrams, and evidence. Agent writing tends to be block-heavy and hard to read; load this before drafting any spec, PR description, review comment, ticket, or repo doc.
- **[`/mermaid`](https://github.com/mahn00b/n00b-skillz/tree/main/skills/mermaid)** — rules for picking the right Mermaid diagram type and keeping diagrams compact. Other skills load it whenever they draw a diagram.
- **[`/tech-spec`](https://github.com/mahn00b/n00b-skillz/tree/main/skills/tech-spec)** — starts a tech spec from a bundled template and asks targeted questions to fill it in, optionally pre-filled from a product spec. Pass `--long-form` to keep the full planning sections. Specs are written to a document store set by `DOC_STORE` / `DOC_STORE_PATH` — a plain Markdown directory or an Obsidian vault, which also gets a Templater template.

### Code review

- **[`/address-pr-comments`](https://github.com/mahn00b/n00b-skillz/tree/main/skills/address-pr-comments)** — pulls the unresolved review comments on the current branch's PR, classifies each by severity, and drafts a fix for each. Nothing changes until you approve which fixes to apply, and you can swap in your own approach for any of them.

## Installation

Symlink each skill into your user-scope skills directory so edits in this repo apply immediately:

```sh
mkdir -p ~/.claude/skills
for d in skills/*/; do ln -s "$PWD/$d" ~/.claude/skills/; done
```

## Versioning

**Releases are cut automatically from [Conventional Commits](https://www.conventionalcommits.org/).** On every push to `main`, [semantic-release](https://github.com/semantic-release/semantic-release) reads the commits since the last tag, pushes a `vX.Y.Z` tag, and publishes a GitHub Release with generated notes.

- **`fix:`** — patch release
- **`feat:`** — minor release
- **`feat!:`** or a `BREAKING CHANGE:` footer — major release; minor while on `0.x`, via a `releaseRules` entry in [`.releaserc.json`](https://github.com/mahn00b/n00b-skillz/blob/main/.releaserc.json) that gets removed to cut `1.0.0`
- **`docs:`, `chore:`, `ci:`, `refactor:`, …** — no release

PRs run [commitlint](https://commitlint.js.org/) against every commit and fail on a non-conforming message. Scope commits by skill where it helps, e.g. `feat(tech-spec): add --long-form flag`.

## Contributing

Like the skill ideas? Want to contribute? Fork and PR — just follow the commit convention above.



# N00b Skillz

## Description

A collection of some of my favorite agentic skills. At the time of this writing, all skills have been built in claude code, by anthropic models, to be used in claude code. 

Other than any that contain references to claude code specifically, all skills follow the Agent Skill spec and possibly can be used in other coding harnesses.

## Skills

Note that some of the workflows that these skills introduce are tied to my usage of Obsidian. I will update those in the future, but for convenience I've just added the skills as they are now.

### `/save-context`

For saving per-directory contexts to retain a summary of the current conversation. Helps to maintain some consistency when iterating on a project in the same directory over several conversations.

### `/load-context`

Loads the context saved using the `/save-context` skill above

### `/technical-writing`

Agent technical writing tends to be block-heavy, unclear, and generally difficult to read. This skill provides a set rules to ensure that the writing is clear, concise, to the point, and visually appealing.

Hook this skill into documentation writing.

### `/mermaid` 

A set of rules to help an Agent compose mermaid diagrams. 

###  `/tech-spec`

Uses a combination of skills to put together a tech spec that has varying detail. Currently, it can create a more detailed tech-spec and a "mini" version of that. 

### `/guided-dev` 

Great for getting to know an unfamiliar codebase, flexing those dev skills again, or getting started on a human-coded project. It will help plan a change with you. Add files, stub classes and methods, and set you up with any relevant testing stubs.

Currently, it's design to really hold your hand through it. In the future I plan to add difficulty levels to that will produce less and less file stubs

### `/address-pr-comments`

Detects which PR you're working on based on the current branch of the coding harness. It pulls down all comments, categorizes them by impact, and provides suggestions around how each comments should be resolved. 

It will then print them in a list for you to select which suggestions to move forward with. You can also provide alternative suggestions to the agent's approach.

## Installation

Symlink each skill into your user-scope skills directory so edits in this repo apply immediately:

```sh
for d in skills/*/; do ln -s "$PWD/$d" ~/.claude/skills/; done
```

## Versioning

**Releases are cut automatically from [Conventional Commits](https://www.conventionalcommits.org/).** On every push to `main`, [semantic-release](https://github.com/semantic-release/semantic-release) reads the commits since the last tag, pushes a `vX.Y.Z` tag, and publishes a GitHub Release with generated notes.

- **`fix:`** — patch release
- **`feat:`** — minor release
- **`feat!:`** or a `BREAKING CHANGE:` footer — major release
- **`docs:`, `chore:`, `ci:`, `refactor:`, …** — no release

PRs run [commitlint](https://commitlint.js.org/) against every commit and fail on a non-conforming message. Scope commits by skill where it helps, e.g. `feat(tech-spec): add --long-form flag`.

## Contributing

Like the skill ideas? Want to contribute? Fork and PR — just follow the commit convention above.



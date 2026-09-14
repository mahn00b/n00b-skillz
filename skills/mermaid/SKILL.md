---
name: mermaid
description: Rules for authoring Mermaid diagrams — choosing the right diagram type for the case and keeping every diagram compact. Use whenever creating or editing a Mermaid diagram in a tech spec, guide, PR, or any doc: deciding between flowchart / sequence / ER / gantt / gitGraph / state, applying the compact styling header, and the orientation + label-quoting conventions.
---

# mermaid

Author Mermaid diagrams that are correctly typed and space-efficient. Apply all three sections, every time.

## 1. Pick the right diagram type

A `flowchart` is the fallback, not the default. Reach for the specific type first:

| Use case | Diagram type |
|---|---|
| Request/response lifecycles, sequential network calls, third-party interactions | `sequenceDiagram` |
| Introducing new database relationships | `erDiagram` |
| Project milestones over time / a timeline | `gantt` |
| Task/ticket dependencies and PR merge order | `gitGraph` |
| A sequential workflow with a clear begin and end state | `stateDiagram-v2` |
| Anything else — architecture, data flow, decision trees | `flowchart` |

Notes:

- **`gitGraph` is for task dependencies, not milestones.** Break a milestone down into tickets first, then arrange *those tickets'* dependency and merge order as branches off `main` (a ticket branches only after the ticket it depends on has merged). Milestones-against-time is a `gantt`, not a `gitGraph`.
- **There is no "treeview" diagram in Mermaid.** For file scaffolding, use a fenced `text` file tree, or a `flowchart TD` shaped as a tree.

## 2. Keep it compact

Prepend this header to every diagram — it shrinks the font and node spacing for ~40% less page space, and works across common Mermaid renderers (Obsidian, GitHub, Linear, exported docs):

```
%%{init: {'themeVariables': {'fontSize':'11px'}, 'flowchart': {'nodeSpacing':22,'rankSpacing':28,'padding':4}}}%%
```

- `themeVariables.fontSize` is universal. The second key is per-type — swap `flowchart` for `sequence`, `state`, `gantt`, `er`, or `gitGraph` to match the diagram, or drop it for types with no spacing knobs (use just `themeVariables`).
- Keep node labels short. Detail belongs in the surrounding prose, not the node.

## 3. Conventions

- **Top-down orientation** for flowcharts, graphs, and state diagrams: `flowchart TD` / `stateDiagram-v2` top-to-bottom, never `LR`. A tall diagram reads better in a doc than one that scrolls off the side. `sequenceDiagram`, `gantt`, and `gitGraph` have their own natural (time-based) orientation — don't force `TD` on them.
- **Quote labels with special characters.** Wrap any node label containing `#`, `::`, `()`, `/`, or a colon in double quotes — `X["Foo::Bar#baz"]` — or the render breaks. Avoid apostrophes inside edge labels (`|...|`).

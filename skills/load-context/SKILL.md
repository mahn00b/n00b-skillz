---
name: load-context
description: >
  Find and load the most recent saved context for the current worktree.
  Use when the user asks to: load context, restore context, "what were we doing", "pick up where we left off",
  "what's the context", or "catch me up". Reads from ~/.claude-context/ organized by repo and branch.
allowed-tools: Bash, Read
---

# load-context

Find and surface the most recent saved context snapshot for the current repo and branch.

## Steps

1. **Get the repo root and branch:**
   ```bash
   git rev-parse --show-toplevel
   git rev-parse --abbrev-ref HEAD
   ```

2. **Derive the context directory** using the same convention as save-context:
   - Repo subdir: strip the leading `/` from the repo root, then replace all remaining `/` with `-`.
     Example: `/home/dev/projects/acme` → `home-dev-projects-acme`
   - Branch subdir: replace all `/` in the branch name with `-`.
     Example: `alex/abc-123` → `alex-abc-123`
   - Context dir: `~/.claude-context/<repo-subdir>/<branch-subdir>/`

3. **List saved context files**, sorted newest first:
   ```bash
   ls -1r ~/.claude-context/<repo-subdir>/<branch-subdir>/*.md 2>/dev/null
   ```

4. **If no files found:** say "No saved context found for this worktree." and stop.

5. **Read the most recent file** using the Read tool and surface its full contents to the user.

6. **If multiple files exist:** after showing the most recent one, mention how many total context files exist and offer to load an older one if the user wants.

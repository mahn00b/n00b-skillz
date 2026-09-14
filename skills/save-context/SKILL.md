---
name: save-context
description: >
  Save a structured summary of the current conversation to disk so it can be reloaded in a future session.
  Use when the user asks to: save context, capture progress, summarize the conversation, create a checkpoint,
  or "save where we are". Writes a markdown file under ~/.claude-context/ organized by repo and branch.
allowed-tools: Bash, Read, Write
---

# save-context

Capture a structured snapshot of the current conversation and write it to disk for later retrieval.

## Steps

1. **Get the repo root and branch:**
   ```bash
   git rev-parse --show-toplevel
   git rev-parse --abbrev-ref HEAD
   ```

2. **Derive the storage path:**
   - Repo subdir: strip the leading `/` from the repo root, then replace all remaining `/` with `-`.
     Example: `/home/dev/projects/acme` → `home-dev-projects-acme`
   - Branch subdir: replace all `/` in the branch name with `-`.
     Example: `alex/abc-123` → `alex-abc-123`
   - Filename: `context-<YYYY-MM-DDTHH-MM-SS>.md` using `date +%Y-%m-%dT%H-%M-%S`
   - Full path: `~/.claude-context/<repo-subdir>/<branch-subdir>/<filename>`

3. **Create the directory:**
   ```bash
   mkdir -p ~/.claude-context/<repo-subdir>/<branch-subdir>
   ```

4. **Synthesize the summary** from the conversation:
   - A 2-3 sentence description of what the overall conversation is about
   - A bullet list of tasks completed so far, phrased as past-tense actions with enough detail to be meaningful out of context
   - A bullet list of planned next steps as discussed
   - A verbatim or close paraphrase of the last 3 turns between user and assistant, labeled "User:" and "Assistant:"

5. **Write the file** using the Write tool with this structure:
   ```markdown
   # Context: <repo-name> / <branch>
   **Saved:** <human-readable timestamp, e.g. "July 13, 2026 at 10:30 AM">
   **Repo:** <absolute repo root>
   **Branch:** <branch name>

   ## Description
   <2-3 sentence summary of what this conversation is about>

   ## Completed
   - <past-tense task with detail>
   - <past-tense task with detail>

   ## Up Next
   - <planned next step>
   - <planned next step>

   ## Recent Exchange
   **User:** <last user message, verbatim or close paraphrase>

   **Assistant:** <last assistant response summary>

   **User:** <second-to-last user message>

   **Assistant:** <second-to-last assistant response summary>

   **User:** <third-to-last user message>

   **Assistant:** <third-to-last assistant response summary>
   ```

6. **Report** the full absolute path where the file was saved.

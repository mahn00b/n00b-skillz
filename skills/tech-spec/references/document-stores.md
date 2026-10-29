# Document stores

Where specs are kept. **The skill touches a store only through the operations below**, so
supporting a new store (Google Docs, Notion, or any app with a document hierarchy and Markdown
rendering) means adding an adapter section here, not editing the skill's workflow.

## Configuration

- **`DOC_STORE`** — the adapter to use: `obsidian` or `filesystem`. When unset, detect it:
  `obsidian` if `DOC_STORE_PATH` contains a `.obsidian/` directory, otherwise `filesystem`.
- **`DOC_STORE_PATH`** — the store's root. When unset, ask the user for it once and reuse the
  answer for the rest of the session.

Both are read from the environment for now. They are named for the store, not for this skill, so
other skills can share the same configuration later.

## Document addressing

Every document has a **store path**: a `/`-separated location relative to the store root, with
no file extension — e.g. `tech-specs/checkout-retry/checkout-retry`. Each adapter maps store
paths onto its own hierarchy (directories and `.md` files, pages and sub-pages, folders and
docs). The document body is always Markdown; an adapter whose backend uses another format
converts on the way in and out.

## Operations

| Operation | Contract |
|---|---|
| **`setup`** | Once per session, before anything else. Verify the store is reachable and writable, and install any store-native extras. Stop and report if the store can't be reached. |
| **`exists(path)`** | Whether a document already lives at `path`. |
| **`create(path, markdown)`** | Create the document and any missing parents. **Never overwrites** — check `exists` first. |
| **`update(path, markdown)`** | Replace the document's body with the edited version. |
| **`locate(path)`** | What to show the user so they can open the document — a file path, a URL, or both. |

---

## `filesystem`

A plain directory of Markdown files. Every other local adapter builds on this one.

- **`setup`** — confirm `DOC_STORE_PATH` exists and is a writable directory.
- **`exists`** — `test -e "$DOC_STORE_PATH/<path>.md"`.
- **`create`** — `mkdir -p` the parent directory, then write `<path>.md`.
- **`update`** — edit `<path>.md` in place.
- **`locate`** — the absolute file path.

## `obsidian`

An Obsidian vault. **Behaves exactly like `filesystem`**, with two additions.

**`setup` also installs the Templater template**, so the user can start a spec from inside
Obsidian too. The template is generated from the skill's own Markdown template, so the two never
drift. Skip this if it already exists in the vault, and never overwrite one:

```bash
python3 - "<skill-dir>/assets/tech-spec-template.md" "$DOC_STORE_PATH/Templates/Tech Spec.md" <<'EOF'
import os, sys

src, dst = sys.argv[1], sys.argv[2]
if os.path.exists(dst):
    sys.exit(0)

header = (
    "<%*\n"
    'const title = await tp.system.prompt("Tech spec title");\n'
    "await tp.file.move(`tech-specs/${title}/${title}`);\n"
    "-%>\n"
)
body = open(src, encoding="utf-8").read()
body = body.replace("{{DATE}}", '<% tp.date.now("YYYY-MM-DD") %>').replace("{{TITLE}}", "<% title %>")

os.makedirs(os.path.dirname(dst), exist_ok=True)
with open(dst, "w", encoding="utf-8") as file:
    file.write(header + body)
EOF
```

**`locate` also returns an `obsidian://` link**, so the user can open the note directly:
`obsidian://open?vault=<url-encoded vault name>&file=<url-encoded store path>`, where the vault
name is the basename of `DOC_STORE_PATH`. Percent-encode both values in full (reserved
characters like `&`, `#`, `?`, `/` included), e.g. with
`python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "<value>"`.

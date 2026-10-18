# Product OS knowledge contract

`knowledge/` is a small, Git-native discovery layer for people and agents. The canonical operating instructions remain in `agents/` and `workflows/`; this directory indexes them without copying their prose.

## Source metadata

Every Markdown document under the configured source roots, including nested folders, begins with YAML frontmatter. The supported subset is deliberately small: one `key: value` per line and inline lists such as `[human, agent]`. Quoted list items may contain commas. Do not use nested objects, multiline scalars, YAML anchors, or unquoted commas.

Required fields and allowed values are in `schema.yml`:

- `id` is a stable dotted identifier, for example `workflow.bug-fix`.
- `kind` is `role` or `workflow`; `status` describes whether it is safe to use.
- `audience`, `tags`, and `applies_to` are lists.
- `depends_on` and `related` are lists of other catalog IDs. They may be empty, but cannot name the document itself. Roles have no dependencies; a workflow's dependencies are role IDs, which become its context-pack read order.
- `authority` identifies the decision boundary; `owner` identifies the maintainer; `updated` is an ISO date.

Tags must come from `taxonomy.yml`. Use slash-separated tags so broad and narrow queries remain legible (`workflow/bug-fix`, `risk/high-impact`). Add a taxonomy tag before using it in an artefact.

## Generated surfaces

`catalog.yml`, `catalog.md`, `taxonomy.md`, and every file in `context/` are generated. A workflow catalog entry exposes its precise `context` path; `catalog.md` is the human-readable discovery index used by the documentation site. Read generated files freely, but never edit them by hand. Change source frontmatter or this contract, then run:

```sh
product-os/bin/build-knowledge --write
product-os/bin/build-knowledge --check
```

The catalog is the first read for a Codex session choosing a Product OS role or route. A workflow context pack then gives the workflow source plus the linked role cards in the required read order. The builder validates missing/duplicate IDs, unknown tags, invalid values, broken relationships, self-references, and stale generated output.

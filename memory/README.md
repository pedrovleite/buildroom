# Memory Contract

Each target project owns `product/memory/index.md`, `product/memory/decision-log.md`, and per-workflow context packs. The index is the navigation surface; the decision log is chronological; a context pack selects only the material a role needs.

Use stable IDs (`PRD-001`, `SPEC-001`, `BUG-001`, `DEC-001`) and list related IDs in frontmatter. A future graph adapter can ingest IDs as nodes and `related` fields as edges, with `date` and `updated` as temporal facts. Do not remove the Markdown source after graph ingestion.

When information becomes stale, add a replacement decision and mark the old record superseded; do not rewrite history silently.

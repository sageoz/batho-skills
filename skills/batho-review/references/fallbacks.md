# batho-review — Fallbacks

## No runs recorded / graph record unavailable

- `batho_list_runs` empty → the artifact predates delta tracking or was built
  once. Fall back to `batho_diff(file_path=<touched>)` + `git diff`, and state
  in the review: "graph change record unavailable for this period".
- Criterion verification still proceeds via `get_entity` / `graph_query` on
  current state — only the delta narrative degrades.

## Spec folder missing or malformed

- `batho-specs/NN-<name>/` not found → list available folders, stop.
- `specs_<name>.md` missing required sections → note it in the review header
  ("spec predates template v1; reviewed against available sections").

## Working tree ahead of the artifact

`batho_status` shows pending files → CLI `batho patch` first; review the new
generation. Reviewing against a stale graph produces false GAPS.

## Orphan false positives

Zero-incoming entities that are legitimate: entry points (`main`, handlers),
reflection targets, framework callbacks, re-exports. Check for these classes
before flagging an orphan; when unsure, list as "possible orphan (verify)".

## Multi-spec reviews

- Resolve each named spec independently; one `review_<name>.md` per folder.
- Shared anchors across specs: verify once, cite in both reviews.
- Overall verdict is the worst per-spec verdict.

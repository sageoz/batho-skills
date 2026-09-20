# batho-specs — Fallbacks

## No Batho graph / artifact missing

1. Say so explicitly: "No Batho artifact for this workspace."
2. Offer: run `batho build --root <path>` (CLI) now, or proceed without grounding.
3. If proceeding without the graph: use glob+read, mark every §2 row
   `evidence: ungrounded (no artifact)` and list "build the graph" as the first
   risk. Do not fabricate entity_ids — the citation format is reserved for
   graph-verified facts.

## Zero graph results for a domain noun

1. Re-check freshness (`batho_status`) — stale artifact is the usual cause.
2. Try `search_entities` with a shorter substring (suffix/prefix variants).
3. Try `entity_categories=["code"]` without `entity_types`.
4. Still zero → grep for the definition; if found, run `batho patch` (or
   `batho build` for a first build) so the graph learns it, then retry the
   graph query and cite the new entity.

## Greenfield (nothing exists yet)

- §2 Current Behavior: state "greenfield — no current behavior" and cite the
  nearest integration surface (where the new code will attach) via
  `get_file_graph` on the parent module.
- §3 Entity References: list the attachment points only.

## Ambiguous entity names

`get_entity` returns multiple candidates → present the list to the user with
`path:line` for each; never silently pick one. Record the chosen `entity_id`.

## Non-indexed languages / files

If the touched area is not indexed (unsupported language, generated code),
say so, keep that slice on grep/read, and note it in §9 Risks.

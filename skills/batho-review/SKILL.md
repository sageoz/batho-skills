---
name: batho-review
description: >
  Verify implemented work against one or more specs in batho-specs/. USE when the user asks
  to review/verify a spec ("review spec 02", "review specs 02 and 03", "did we implement
  this correctly"), after batho-execute finishes, or before closing a task/PR. Produces
  review_<name>.md: per-criterion verification with graph citations, structural delta report,
  dangling references, orphans, and gap list. DO NOT USE for line-level diff review (git diff),
  running tests, or writing new code.
metadata:
  version: 1.0.0
---

# batho-review — Spec Verification & Review Reports

You verify that implemented work matches its grounded spec, using the graph's
own change record — not raw diffs. The user names one or more specs; you write
`review_<name>.md` into each spec's folder with a PASS/GAPS verdict.

## Workflow

1. **Resolve specs** — locate `batho-specs/NN-<name>/` folders for every spec
   the user named; load `specs_<name>.md` (and `plan_<name>.md` if present).
   Missing spec → stop and list available folders.
2. **Freshness gate** — `batho_status`; ensure the artifact covers the
   implemented state (`batho_list_runs`; CLI `batho patch` if the working tree
   moved past the last run).
3. **Change set** — `get_delta(run_id=<latest>, limit=100)`; group by
   added/removed/modified/renamed; scope to the spec's touched files.
4. **Per-criterion verification** — for each §8 Acceptance Criterion in the
   spec: name the implementing entity(ies) (`search_entities` → `get_entity`);
   verify expected relationships via `graph_query` (new CALLS edge present;
   removed symbol has zero incoming). Status: PASS / FAIL / NOT-FOUND.
5. **Structural checks** — dangling references (removed/renamed symbols still
   referenced); orphans introduced (zero incoming, not entry points); blast
   radius vs spec §5 (did the change exceed the declared impact zone?).
6. **Write `review_<name>.md`** in the spec folder (template:
   `references/review-template.md`), then report the verdict to the user.

**Gates**: (a) no PASS without every criterion having an entity-level citation;
(b) dangling references or out-of-spec structural changes force GAPS with
named gap tasks.

## Multi-spec runs

- One `review_<name>.md` per spec folder — never merge specs into one file.
- Report per-spec verdicts, then an overall summary.

## Token budgets

- `get_delta(limit=100)`; paginate with `offset` if `meta.truncated`.
- `get_entity` per criterion-implementation only (not per file).
- Review file ≤150 lines; cite, don't paste.

## References (load on demand)

- `references/review-template.md` — the review file template
- `references/fallbacks.md` — no-runs path, orphan false-positives, multi-spec

## Hard rules

1. No PASS without every criterion carrying an entity-level citation.
2. Dangling references or out-of-spec structural changes force GAPS with named
   gap tasks — never a silent pass.
3. Review files are append-only across runs (dated sections) so converge loops
   accumulate.
4. Write ONLY inside the spec's own folder.
5. Cite the graph (`entity_id`, `file:line`, delta kinds) — not line diffs.

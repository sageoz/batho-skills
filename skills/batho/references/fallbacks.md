# Fallbacks — when grep / read / glob is still the right tool

Batho owns structure; these are the cases where the classic tools win. Using
them is not a failure — silently using them for structural questions is.

## When grep wins (use Grep directly, say why)

| Case | Why grep | After the fallback |
|---|---|---|
| Exact string in file bodies (log message, error text, TODO, literal) | Graph indexes symbols and relationships, not raw text | none — grep is correct |
| Comment / docstring content | Not a graph entity | grep |
| Non-code files (`.md`, `.yaml`, `.json`, `.txt`, `.env`) | Not indexed as code entities | grep / read |
| Generated or vendored code excluded from the index | Not in the artifact | grep; consider whether it should be indexed |

## When read wins

- You are about to **edit** the file (always read before editing).
- You need line-exact context the graph does not carry (whitespace, formatting).
- The graph named the file and you need the surrounding lines around a hit —
  read the named range, not the whole file.

## When glob wins

- Filename lookup ("find all `*_test.py`") — `search_entities` matches symbol
  names, not filenames.

## Zero-result escape hatch

When a Batho query returns zero results and you expected otherwise:

1. Check freshness first: `batho_status` → stale? `batho patch` → retry.
2. Still zero → the symbol may be new/unindexed: grep for its definition,
   then run `batho build` (or `batho patch`) so the graph learns it, then retry
   the graph query.
3. If the symbol lives in a language/file type Batho does not index, say so
   and stay on grep for that question.

## After any fallback that found new code

If grep/read revealed code the graph missed, run `batho patch` (CLI) so the
artifact covers it, then re-anchor entity IDs before continuing spec or
execution work.

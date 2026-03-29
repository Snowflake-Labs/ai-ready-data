# Fix: embedding_dimension_consistency

Remediation guidance for inconsistent embedding dimensions.

## Context

Snowflake does not support in-place dimension conversion for `VECTOR` columns. Fixing inconsistent dimensions requires re-generating the embeddings at the target dimensionality and replacing the affected columns. Steps:

1. **Identify the target dimension** — use the diagnostic to find the most common `VECTOR` type (e.g. `VECTOR(FLOAT, 768)`). All columns should converge on this dimension unless a downstream model explicitly requires a different size.
2. **Re-embed source data** — for each inconsistent column, re-run the embedding model (or Snowflake Cortex `EMBED_TEXT_768` / `EMBED_TEXT_1024`) against the source text to produce vectors of the correct dimension.
3. **Replace the column** — `ALTER TABLE … DROP COLUMN` the old vector column and `ALTER TABLE … ADD COLUMN` with the correct `VECTOR` type, then backfill with the new embeddings.
4. **Validate** — re-run the check query to confirm a score of 1.0.
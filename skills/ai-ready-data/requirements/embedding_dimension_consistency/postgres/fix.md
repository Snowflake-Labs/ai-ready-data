# Fix: embedding_dimension_consistency

Remediation guidance for inconsistent embedding dimensions.

## Context

PostgreSQL with pgvector does not support in-place dimension conversion for `vector` columns. Fixing inconsistent dimensions requires re-generating the embeddings at the target dimensionality and replacing the affected columns.

## Remediation Guidance

1. **Identify the target dimension** — use the diagnostic to find the most common `vector(N)` type (e.g. `vector(768)`). All columns should converge on this dimension unless a downstream model explicitly requires a different size.

2. **Re-embed source data** — for each inconsistent column, re-run the embedding model against the source text to produce vectors of the correct dimension.

3. **Replace the column** — drop the old column and add a new one with the correct dimension, then backfill with the new embeddings:

   ```sql
   ALTER TABLE {{ schema }}.{{ table_name }}
       DROP COLUMN {{ vector_column_name }};

   ALTER TABLE {{ schema }}.{{ table_name }}
       ADD COLUMN {{ vector_column_name }} vector({{ target_dimension }});
   ```

4. **Backfill** — populate the new column with re-generated embeddings:

   ```sql
   UPDATE {{ schema }}.{{ table_name }}
       SET {{ vector_column_name }} = {{ embedding_expression }};
   ```

5. **Validate** — re-run the check query to confirm a score of 1.0.

# Fix: embedding_coverage

No fully automated fix is possible — remediation requires a human-chosen embedding model, target dimension, and refresh strategy. The SQL below provides the three standard steps once those decisions are made.

## Context

`{{ embedding_dim }}` and `{{ embedding_model }}` must match — Snowflake Cortex exposes separate functions per output dimension (`EMBED_TEXT_768`, `EMBED_TEXT_1024`, etc.), and each supports a fixed set of model identifiers. Common pairings:

- 768: `snowflake-arctic-embed-m-v1.5`, `snowflake-arctic-embed-m`, `e5-base-v2`
- 1024: `snowflake-arctic-embed-l-v2.0`, `nv-embed-qa-4`

Pick the dimension once per schema and reuse it — `embedding_dimension_consistency` measures whether the schema converges on a single dimension, so mixing dimensions across tables will hurt a downstream check.

## Fix: Add a vector column

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
    ADD COLUMN {{ vector_column }} VECTOR(FLOAT, {{ embedding_dim }});
```

## Fix: Populate embeddings

Use the `EMBED_TEXT_{{ embedding_dim }}` Cortex function. Replace the function name with the variant matching your chosen dimension.

```sql
UPDATE {{ database }}.{{ schema }}.{{ asset }}
SET {{ vector_column }} = SNOWFLAKE.CORTEX.EMBED_TEXT_{{ embedding_dim }}(
    '{{ embedding_model }}',
    {{ text_column }}
)
WHERE {{ text_column }} IS NOT NULL
  AND {{ vector_column }} IS NULL;
```

## Fix: Keep embeddings current

For ongoing freshness, schedule a task or use a `STREAM` + `TASK` pattern so new or updated rows are embedded incrementally rather than via periodic full-table updates.

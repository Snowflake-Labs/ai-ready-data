# Fix: embedding_coverage

No automated fix SQL is provided for this requirement. Remediation depends on the embedding model, dimensionality, and downstream retrieval pattern.

## Remediation Guidance

1. **Add a vector column** to each table flagged by the diagnostic as `NO_EMBEDDING`:

   ```sql
   ALTER TABLE {{ database }}.{{ schema }}.{{ table_name }}
     ADD COLUMN {{ vector_column_name }} VECTOR(FLOAT, 768);
   ```

2. **Populate embeddings** using Snowflake Cortex:

   ```sql
   UPDATE {{ database }}.{{ schema }}.{{ table_name }}
     SET {{ vector_column_name }} = SNOWFLAKE.CORTEX.EMBED_TEXT_768(
       'snowflake-arctic-embed-m-v1.5', {{ text_column }}
     );
   ```

   For 1024-dimension embeddings, use `EMBED_TEXT_1024` with an appropriate model instead.
3. **Keep embeddings current** by scheduling a task or using a stream + task pattern to embed new/updated rows incrementally.

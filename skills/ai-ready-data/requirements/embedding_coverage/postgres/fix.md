# Fix: embedding_coverage

No automated fix SQL is provided for this requirement. Remediation depends on the embedding model, dimensionality, and downstream retrieval pattern.

## Remediation Guidance

1. **Ensure pgvector is installed**:

   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   ```

2. **Add a vector column** to each table flagged by the diagnostic as `NO_EMBEDDING`:

   ```sql
   ALTER TABLE {{ schema }}.{{ table_name }}
       ADD COLUMN {{ vector_column_name }} vector(768);
   ```

3. **Populate embeddings** using your embedding model of choice (e.g., OpenAI, Sentence Transformers, or a PG-native solution). This is typically done application-side:

   ```sql
   UPDATE {{ schema }}.{{ table_name }}
       SET {{ vector_column_name }} = {{ embedding_expression }}
       WHERE {{ vector_column_name }} IS NULL;
   ```

4. **Keep embeddings current** by adding a trigger or scheduled job to embed new/updated rows incrementally.

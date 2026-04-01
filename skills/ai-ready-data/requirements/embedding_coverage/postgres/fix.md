# Fix: embedding_coverage

No automated fix SQL is provided for this requirement. Remediation depends on the embedding model, dimensionality, and downstream retrieval pattern.

## Context

PostgreSQL requires the `pgvector` extension for native vector storage and similarity search. Embeddings must be generated externally (e.g., via OpenAI, Sentence Transformers, or another embedding model) and inserted into vector columns.

## Remediation Guidance

1. **Install pgvector** (if not already installed):

   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   ```

2. **Add a vector column** to each table flagged by the diagnostic as `NO_EMBEDDING`:

   ```sql
   ALTER TABLE {{ schema }}.{{ table_name }}
       ADD COLUMN {{ vector_column_name }} vector(768);
   ```

   Replace `768` with the dimension of your embedding model's output.

3. **Populate embeddings** from your application layer. For example, using Python with `psycopg2`:

   ```python
   # Generate embedding with your model, then:
   cursor.execute(
       "UPDATE schema.table SET embedding = %s WHERE id = %s",
       (embedding_vector, row_id)
   )
   ```

4. **Keep embeddings current** by updating them in your data pipeline whenever the source text column changes. Consider a trigger-based or CDC-based approach to maintain freshness.

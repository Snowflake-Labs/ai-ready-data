# Fix: chunk_readiness

Remediation guidance for text content that is not optimally sized for embedding.

## Context

Chunk readiness issues fall into two categories:

1. **Content too long** — text exceeds the optimal range for embedding models and needs to be split into chunks. Chunking strategies include fixed-size with overlap, sentence-boundary splitting, or semantic chunking. The right approach depends on the content type (documents, articles, logs, etc.).

2. **Content too short** — text fragments lack sufficient semantic content for meaningful embeddings. Consider concatenating short records with surrounding context (e.g., combining a title with its description) or filtering them out of the embedding pipeline.

There is no universal SQL fix for chunking — the implementation depends on the content structure and the target embedding model. Below are common patterns for Snowflake.

## Fix: Create a chunked view for long content

Create a view or table that splits long text into overlapping chunks. Adjust the chunk size and overlap based on your embedding model's context window.

```sql
CREATE OR REPLACE TABLE {{ database }}.{{ schema }}.{{ asset }}_chunked AS
WITH RECURSIVE chunks AS (
    SELECT
        {{ key_columns }} AS source_id,
        1 AS chunk_index,
        SUBSTR({{ text_column }}, 1, 2000) AS chunk_text,
        LENGTH({{ text_column }}) AS total_length
    FROM {{ database }}.{{ schema }}.{{ asset }}
    WHERE {{ text_column }} IS NOT NULL AND LENGTH({{ text_column }}) > 0
    UNION ALL
    SELECT
        source_id,
        chunk_index + 1,
        SUBSTR({{ text_column }}, 1 + (chunk_index * 1800), 2000),
        total_length
    FROM chunks
    JOIN {{ database }}.{{ schema }}.{{ asset }} ON {{ key_columns }} = source_id
    WHERE 1 + (chunk_index * 1800) < total_length
)
SELECT source_id, chunk_index, chunk_text
FROM chunks
```

## Fix: Concatenate short content with context

If short text rows have associated context columns (e.g., title, category, description), concatenate them to create richer content for embedding:

```sql
CREATE OR REPLACE VIEW {{ database }}.{{ schema }}.{{ asset }}_enriched AS
SELECT
    {{ key_columns }},
    {{ title_column }} || ': ' || {{ text_column }} AS enriched_text
FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ text_column }} IS NOT NULL
```

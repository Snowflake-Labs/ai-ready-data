# Check: consent_coverage

Fraction of base tables tagged with a documented legal basis for AI processing of the data they contain.

## Context

Detects whether tables have been tagged with any of the recognized consent / legal-basis tags. The tag records that a legal basis has been documented; it does not validate the substance of the consent.

Typical legal basis values align with GDPR Article 6: `consent`, `legitimate_interest`, `contract`, `legal_obligation`, `public_interest`, `vital_interest`.

`account_usage.tag_references` has approximately 2-hour latency for newly applied tags.

Requires `{{ tag_names }}` — comma-separated quoted list, typically `'consent_basis','legal_basis','processing_basis','consent'`.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type = 'BASE TABLE'
),
tagged_tables AS (
    SELECT COUNT(DISTINCT tr.object_name) AS cnt
    FROM snowflake.account_usage.tag_references tr
    JOIN {{ database }}.information_schema.tables t
        ON UPPER(tr.object_name) = UPPER(t.table_name)
        AND UPPER(t.table_schema) = UPPER('{{ schema }}')
        AND t.table_type = 'BASE TABLE'
    WHERE UPPER(tr.object_database) = UPPER('{{ database }}')
        AND UPPER(tr.object_schema)   = UPPER('{{ schema }}')
        AND tr.domain = 'TABLE'
        AND LOWER(tr.tag_name) IN ({{ tag_names }})
)
SELECT
    tagged_tables.cnt AS tables_tagged,
    table_count.cnt   AS total_tables,
    tagged_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, tagged_tables
```

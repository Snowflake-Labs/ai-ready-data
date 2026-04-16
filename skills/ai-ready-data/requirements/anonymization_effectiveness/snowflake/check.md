# Check: anonymization_effectiveness

Fraction of PII-candidate columns in the schema with a masking policy attached (broader PII pattern than `column_masking`).

## Context

Identifies PII-candidate columns by name regex and checks `snowflake.account_usage.policy_references` for a `MASKING_POLICY`. The pattern set here is **broader** than `column_masking` — it includes name fields, which frequently surface PII but with more false positives. For high-confidence coverage, prefer `column_masking`; for broad anonymization auditing, use this check.

PII detection is heuristic. For thorough PII scanning, delegate to the `sensitive-data-classification` skill which uses Snowflake's `SYSTEM$CLASSIFY`.

A column tagged as `pii` but without a masking policy is still considered **unprotected** — tags indicate awareness but do not protect data.

`account_usage.policy_references` has approximately 2-hour latency for newly applied policies. Uses `ref_column_name` and `ref_entity_name` (not `column_name` / `table_name`).

Requires `{{ pii_patterns }}` — a regex matching PII column names. Default for this check: `'(^|_)(email|phone|ssn|first_name|last_name|full_name|person_name|name|address)($|_)'`.

Returns NULL (N/A) when the schema contains no PII-candidate columns.

## SQL

```sql
WITH pii_columns AS (
    SELECT
        UPPER(c.table_name)  AS table_name,
        UPPER(c.column_name) AS column_name
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name   = t.table_name
    WHERE UPPER(c.table_schema) = UPPER('{{ schema }}')
        AND t.table_type = 'BASE TABLE'
        AND REGEXP_LIKE(LOWER(c.column_name), '{{ pii_patterns }}')
),
masked_columns AS (
    SELECT DISTINCT
        UPPER(ref_entity_name) AS table_name,
        UPPER(ref_column_name) AS column_name
    FROM snowflake.account_usage.policy_references
    WHERE UPPER(ref_database_name) = UPPER('{{ database }}')
        AND UPPER(ref_schema_name) = UPPER('{{ schema }}')
        AND policy_kind = 'MASKING_POLICY'
)
SELECT
    COUNT(m.column_name) AS masked_pii_columns,
    COUNT(*)             AS total_pii_columns,
    COUNT(m.column_name)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM pii_columns pc
LEFT JOIN masked_columns m
    ON pc.table_name = m.table_name
   AND pc.column_name = m.column_name
```

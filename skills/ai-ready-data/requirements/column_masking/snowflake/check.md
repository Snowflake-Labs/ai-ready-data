# Check: column_masking

Fraction of PII-candidate columns in the schema with a masking policy attached.

## Context

Identifies PII columns by name regex and checks `snowflake.account_usage.policy_references` for a `MASKING_POLICY` on each. Compared to `anonymization_effectiveness` this check uses a **narrower, higher-confidence PII pattern** focused on directly identifying or credential-bearing columns.

Pattern matching uses `REGEXP_LIKE` with anchored underscores so `_` is not treated as a LIKE wildcard.

`account_usage.policy_references` has approximately 2-hour latency. It exposes column attachment via `ref_column_name` and `ref_entity_name` (not `column_name` / `table_name`).

Delegates to the `data-policy` skill for comprehensive masking policy management.

Requires `{{ pii_patterns }}` — a regex (POSIX ERE-compatible) that matches PII column names. Default for this check: `'(^|_)(email|phone|ssn|password|credit_card|address)($|_)'`.

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

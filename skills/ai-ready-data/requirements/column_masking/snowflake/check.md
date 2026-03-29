# Check: column_masking

Fraction of PII columns with masking policies applied.

## Context

Identifies PII columns by name-pattern heuristic (`%email%`, `%phone%`, `%ssn%`, `%password%`, `%credit_card%`, `%address%`) and checks whether each has a masking policy. This is a narrower PII pattern set than `anonymization_effectiveness` — focused on high-confidence PII indicators.

`account_usage.policy_references` has approximately 2-hour latency. Uses `ref_column_name` and `ref_entity_name` (not `column_name` / `table_name`).

Delegates to the `data-policy` skill for comprehensive masking policy management.

## SQL

```sql
WITH pii_columns AS (
    SELECT c.table_name, c.column_name
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_name = t.table_name AND c.table_schema = t.table_schema
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
        AND (
            LOWER(c.column_name) LIKE '%email%'
            OR LOWER(c.column_name) LIKE '%phone%'
            OR LOWER(c.column_name) LIKE '%ssn%'
            OR LOWER(c.column_name) LIKE '%password%'
            OR LOWER(c.column_name) LIKE '%credit_card%'
            OR LOWER(c.column_name) LIKE '%address%'
        )
),
masked_columns AS (
    SELECT DISTINCT
        UPPER(ref_entity_name) AS table_name,
        UPPER(ref_column_name) AS column_name
    FROM snowflake.account_usage.policy_references
    WHERE UPPER(ref_database_name) = UPPER('{{ database }}')
        AND UPPER(ref_schema_name) = UPPER('{{ schema }}')
        AND policy_kind = 'MASKING_POLICY'
),
coverage AS (
    SELECT
        COUNT(*) AS pii_count,
        COUNT(m.column_name) AS masked_count
    FROM pii_columns p
    LEFT JOIN masked_columns m
        ON UPPER(p.table_name) = m.table_name AND UPPER(p.column_name) = m.column_name
)
SELECT
    masked_count AS masked_pii_columns,
    pii_count AS total_pii_columns,
    masked_count::FLOAT / NULLIF(pii_count::FLOAT, 0) AS value
FROM coverage
```

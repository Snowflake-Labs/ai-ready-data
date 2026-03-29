# Check: anonymization_effectiveness

Fraction of PII-candidate columns that have masking policies applied.

## Context

PII detection is heuristic — this check identifies PII candidates by column name patterns (`%email%`, `%phone%`, `%ssn%`, `%first_name%`, `%last_name%`, `%full_name%`, `%person_name%`, `name`, `%address%`). This will miss PII stored in generically named columns and may flag non-PII columns that happen to match the patterns. For thorough PII scanning, delegate to the `sensitive-data-classification` skill which uses Snowflake's `SYSTEM$CLASSIFY`.

Only masking policies count toward the score — privacy tags indicate awareness but do not protect data. A column tagged as `pii` but without a masking policy is still considered unprotected.

`account_usage.policy_references` has approximately 2-hour latency for newly applied policies. Uses `ref_column_name` and `ref_entity_name` (not `column_name` / `table_name`).

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
            OR LOWER(c.column_name) LIKE '%first_name%'
            OR LOWER(c.column_name) LIKE '%last_name%'
            OR LOWER(c.column_name) LIKE '%full_name%'
            OR LOWER(c.column_name) LIKE '%person_name%'
            OR LOWER(c.column_name) = 'name'
            OR LOWER(c.column_name) LIKE '%address%'
        )
),
protected_columns AS (
    SELECT DISTINCT
        UPPER(ref_entity_name) AS table_name,
        UPPER(ref_column_name) AS column_name
    FROM snowflake.account_usage.policy_references
    WHERE UPPER(ref_database_name) = UPPER('{{ database }}')
        AND UPPER(ref_schema_name) = UPPER('{{ schema }}')
        AND policy_kind = 'MASKING_POLICY'
)
SELECT
    COUNT(*) AS total_pii_columns,
    COUNT(p.column_name) AS protected_pii_columns,
    COUNT(p.column_name)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM pii_columns pc
LEFT JOIN protected_columns p
    ON UPPER(pc.table_name) = p.table_name AND UPPER(pc.column_name) = p.column_name
```

# Check: column_masking

Fraction of PII columns with masking protection applied.

## Context

Identifies PII columns by name-pattern heuristic (`%email%`, `%phone%`, `%ssn%`, `%password%`, `%credit_card%`, `%address%`) and checks whether each has column-level SELECT restrictions. This is a narrower PII pattern set than `anonymization_effectiveness` — focused on high-confidence PII indicators.

PostgreSQL has no native masking policies. Protection is assessed by checking whether column-level SELECT has been revoked from `PUBLIC` or restricted to specific roles via `information_schema.column_privileges`. A PII column is considered "masked" if there is at least one explicit column-level grant (indicating column-level access control is active) and `PUBLIC` does not hold unrestricted SELECT.

This heuristic is imperfect — table-level grants may still expose the column. For stronger masking, consider the `postgresql_anonymizer` extension or masking views.

## SQL

```sql
WITH pii_columns AS (
    SELECT c.table_name, c.column_name
    FROM information_schema.columns c
    JOIN information_schema.tables t
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
restricted_columns AS (
    SELECT DISTINCT table_name, column_name
    FROM information_schema.column_privileges
    WHERE table_schema = '{{ schema }}'
      AND privilege_type = 'SELECT'
      AND grantee <> 'PUBLIC'
),
coverage AS (
    SELECT
        COUNT(*)              AS pii_count,
        COUNT(r.column_name)  AS masked_count
    FROM pii_columns p
    LEFT JOIN restricted_columns r
        ON p.table_name = r.table_name AND p.column_name = r.column_name
)
SELECT
    masked_count  AS masked_pii_columns,
    pii_count     AS total_pii_columns,
    masked_count::NUMERIC / NULLIF(pii_count::NUMERIC, 0) AS value
FROM coverage;
```

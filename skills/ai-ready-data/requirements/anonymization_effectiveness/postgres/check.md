# Check: anonymization_effectiveness

Fraction of PII-candidate columns that have access restrictions applied.

## Context

PII detection is heuristic — this check identifies PII candidates by a broad set of column name patterns (`%email%`, `%phone%`, `%ssn%`, `%first_name%`, `%last_name%`, `%full_name%`, `%person_name%`, `name`, `%address%`). This will miss PII stored in generically named columns and may flag non-PII columns that happen to match the patterns.

PostgreSQL has no native masking policies. A PII column is considered "protected" if it has column-level SELECT restrictions (explicit grants to non-PUBLIC roles) via `information_schema.column_privileges`, or if a security label has been applied via `pg_seclabel` (indicating awareness and potential masking via `postgresql_anonymizer`).

Only column-level access restrictions and security labels count toward the score. Table-level comments indicating PII awareness do not provide enforcement and are not counted.

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
          OR LOWER(c.column_name) LIKE '%first_name%'
          OR LOWER(c.column_name) LIKE '%last_name%'
          OR LOWER(c.column_name) LIKE '%full_name%'
          OR LOWER(c.column_name) LIKE '%person_name%'
          OR LOWER(c.column_name) = 'name'
          OR LOWER(c.column_name) LIKE '%address%'
      )
),
col_restricted AS (
    SELECT DISTINCT table_name, column_name
    FROM information_schema.column_privileges
    WHERE table_schema = '{{ schema }}'
      AND privilege_type = 'SELECT'
      AND grantee <> 'PUBLIC'
),
col_labeled AS (
    SELECT DISTINCT
        c.relname AS table_name,
        a.attname AS column_name
    FROM pg_seclabel sl
    JOIN pg_class c ON c.oid = sl.objoid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = sl.objsubid
    WHERE n.nspname = '{{ schema }}'
      AND sl.objsubid > 0
),
protected AS (
    SELECT table_name, column_name FROM col_restricted
    UNION
    SELECT table_name, column_name FROM col_labeled
)
SELECT
    COUNT(*)              AS total_pii_columns,
    COUNT(pr.column_name) AS protected_pii_columns,
    COUNT(pr.column_name)::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0) AS value
FROM pii_columns pc
LEFT JOIN protected pr
    ON pc.table_name = pr.table_name AND pc.column_name = pr.column_name;
```

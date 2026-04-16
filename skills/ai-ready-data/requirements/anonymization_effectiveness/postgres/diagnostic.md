# Diagnostic: anonymization_effectiveness

Per-column breakdown of PII candidates and their protection status.

## Context

Shows every column flagged as a PII candidate (by name pattern heuristic) along with its current protection: `COLUMN_RESTRICTED` if column-level SELECT has been restricted, `SECURITY_LABEL` if a security label is present (e.g. from `postgresql_anonymizer`), or `UNPROTECTED` if neither exists.

Security labels indicate awareness and potential masking but enforcement depends on the label provider configuration. Column-level restrictions are the strongest built-in protection.

Use this to identify which specific columns need protection and to verify the heuristic PII detection is matching the right columns. Columns flagged incorrectly can be noted as false positives.

## SQL

```sql
WITH pii_columns AS (
    SELECT c.table_name, c.column_name, c.data_type
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
    SELECT DISTINCT table_name, column_name, 'COLUMN_RESTRICTED' AS protection
    FROM information_schema.column_privileges
    WHERE table_schema = '{{ schema }}'
      AND privilege_type = 'SELECT'
      AND grantee <> 'PUBLIC'
),
col_labeled AS (
    SELECT DISTINCT
        c.relname  AS table_name,
        a.attname  AS column_name,
        'SECURITY_LABEL:' || sl.label AS protection
    FROM pg_seclabel sl
    JOIN pg_class c ON c.oid = sl.objoid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = sl.objsubid
    WHERE n.nspname = '{{ schema }}'
      AND sl.objsubid > 0
)
SELECT
    pc.table_name,
    pc.column_name,
    pc.data_type,
    COALESCE(r.protection, l.protection, 'UNPROTECTED') AS protection_status
FROM pii_columns pc
LEFT JOIN col_restricted r ON pc.table_name = r.table_name AND pc.column_name = r.column_name
LEFT JOIN col_labeled l    ON pc.table_name = l.table_name AND pc.column_name = l.column_name
ORDER BY protection_status, pc.table_name, pc.column_name;
```

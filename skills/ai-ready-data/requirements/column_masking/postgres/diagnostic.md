# Diagnostic: column_masking

Identification of unmasked PII columns and column-level privilege inventory.

## Context

Two diagnostic views:

1. **Unmasked PII columns** — PII-candidate columns (by name-pattern heuristic) that have no column-level access restriction. Use this as a remediation worklist.
2. **Column privilege inventory** — all column-level grants in the schema. Use this to understand existing column-level access control before adding restrictions.

PostgreSQL has no native masking policies. Column-level `REVOKE` / `GRANT` is the primary mechanism for restricting access to sensitive columns.

## SQL

### Unmasked PII columns

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
          OR LOWER(c.column_name) LIKE '%password%'
          OR LOWER(c.column_name) LIKE '%credit_card%'
          OR LOWER(c.column_name) LIKE '%address%'
      )
),
restricted AS (
    SELECT DISTINCT table_name, column_name
    FROM information_schema.column_privileges
    WHERE table_schema = '{{ schema }}'
      AND privilege_type = 'SELECT'
      AND grantee <> 'PUBLIC'
)
SELECT p.table_name, p.column_name, p.data_type, 'NEEDS MASKING' AS status
FROM pii_columns p
LEFT JOIN restricted r
    ON p.table_name = r.table_name AND p.column_name = r.column_name
WHERE r.column_name IS NULL
ORDER BY p.table_name, p.column_name;
```

### Column privilege inventory

```sql
SELECT
    table_name,
    column_name,
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.column_privileges
WHERE table_schema = '{{ schema }}'
ORDER BY table_name, column_name, grantee;
```

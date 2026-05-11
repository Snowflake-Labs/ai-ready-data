# Fix: uniqueness

Deduplication strategies for removing duplicate records by key columns.

## Context

PostgreSQL does not support `QUALIFY` or `CREATE OR REPLACE TABLE ... AS SELECT`. Instead, deduplication uses a CTE with `ROW_NUMBER()` and a `DELETE` targeting rows that are not the "kept" row per key combination. This approach is in-place and preserves grants, policies, and triggers.

- **Keep first**: `ORDER BY {{ tiebreaker_column }} ASC` — retains the earliest row per key.
- **Keep last**: `ORDER BY {{ tiebreaker_column }} DESC` — retains the most recent row per key.

After deduplication, consider adding a `UNIQUE` constraint or `PRIMARY KEY` on the key columns to prevent future duplicates. PostgreSQL enforces these constraints, unlike Snowflake.

## Remediation: deduplicate-keep-first

Keeps the earliest record per key combination based on the tiebreaker column.

```sql
DELETE FROM {{ schema }}.{{ asset }}
WHERE ctid NOT IN (
    SELECT DISTINCT ON ({{ key_columns }}) ctid
    FROM {{ schema }}.{{ asset }}
    ORDER BY {{ key_columns }}, {{ tiebreaker_column }} ASC
)
```

## Remediation: deduplicate-keep-last

Keeps the most recent record per key combination based on the tiebreaker column.

```sql
DELETE FROM {{ schema }}.{{ asset }}
WHERE ctid NOT IN (
    SELECT DISTINCT ON ({{ key_columns }}) ctid
    FROM {{ schema }}.{{ asset }}
    ORDER BY {{ key_columns }}, {{ tiebreaker_column }} DESC
)
```

## Remediation: add-unique-constraint

After deduplication, add a UNIQUE constraint to prevent future duplicates. PostgreSQL enforces this constraint on every INSERT and UPDATE.

```sql
ALTER TABLE {{ schema }}.{{ asset }}
ADD CONSTRAINT {{ asset }}_unique_{{ key_columns }} UNIQUE ({{ key_columns }})
```

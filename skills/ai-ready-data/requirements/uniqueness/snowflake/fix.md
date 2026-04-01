# Fix: uniqueness

Deduplication strategies for removing duplicate records by key columns.

## Context

Both remediation options use `CREATE OR REPLACE TABLE` with `QUALIFY ROW_NUMBER()` to keep exactly one row per key combination. The difference is the sort direction on the tiebreaker column:

- **Keep first**: `ORDER BY {{ tiebreaker_column }} ASC` — retains the earliest row per key.
- **Keep last**: `ORDER BY {{ tiebreaker_column }} DESC` — retains the most recent row per key.

## Constraints

- `CREATE OR REPLACE TABLE` drops grants, policies, streams, and change tracking. Re-apply these after running the fix.
- `key_columns` should be the logical primary key.

## Fix: deduplicate-keep-first

Keeps the earliest record per key combination based on the tiebreaker column.

```sql
CREATE OR REPLACE TABLE {{ database }}.{{ schema }}.{{ asset }} AS
SELECT *
FROM {{ database }}.{{ schema }}.{{ asset }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY {{ key_columns }} ORDER BY {{ tiebreaker_column }} ASC) = 1
```

## Fix: deduplicate-keep-last

Keeps the most recent record per key combination based on the tiebreaker column.

```sql
CREATE OR REPLACE TABLE {{ database }}.{{ schema }}.{{ asset }} AS
SELECT *
FROM {{ database }}.{{ schema }}.{{ asset }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY {{ key_columns }} ORDER BY {{ tiebreaker_column }} DESC) = 1
```
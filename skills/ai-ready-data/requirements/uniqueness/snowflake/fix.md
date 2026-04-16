# Fix: uniqueness

Deduplication strategies for removing duplicate records by key columns.

## Context

Three remediation options are provided, ordered from safest to most destructive:

1. **Delete duplicates in place (preferred)** — issues a `DELETE` that keeps the row selected by `ROW_NUMBER() = 1` and removes the rest. This preserves all table-level metadata (grants, row access policies, masking policies, column masking, tags, streams, change tracking setting, clustering key, search optimization, table and column comments). Recommended whenever possible.
2. **CREATE OR REPLACE TABLE (fallback)** — produces the same final rows but **drops** grants, policies, streams, change tracking, clustering key, search optimization, and all tags. Use only when the DELETE-based approach is not viable (e.g. no DELETE privilege, or the duplicate volume is so large that a full rewrite is cheaper than the DELETE).

The sort direction on the tiebreaker column chooses which duplicate survives:

- **Keep first**: `ORDER BY {{ tiebreaker_column }} ASC` — retains the earliest row per key.
- **Keep last**: `ORDER BY {{ tiebreaker_column }} DESC` — retains the most recent row per key.

`key_columns` should be the logical primary key of the table. After any deduplication, consider adding a `PRIMARY KEY` or `UNIQUE` constraint via the `constraint_declaration` fix to signal intent to downstream consumers (constraints are metadata-only in Snowflake but still useful).

## Fix: Delete duplicates in place — keep first (preferred)

Keeps the earliest record per key combination and deletes the rest. Preserves all table-level metadata.

```sql
DELETE FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE ({{ key_columns }}, {{ tiebreaker_column }}) IN (
    SELECT {{ key_columns }}, {{ tiebreaker_column }}
    FROM (
        SELECT
            {{ key_columns }},
            {{ tiebreaker_column }},
            ROW_NUMBER() OVER (
                PARTITION BY {{ key_columns }}
                ORDER BY {{ tiebreaker_column }} ASC
            ) AS rn
        FROM {{ database }}.{{ schema }}.{{ asset }}
    )
    WHERE rn > 1
)
```

## Fix: Delete duplicates in place — keep last (preferred)

Keeps the most recent record per key combination and deletes the rest. Preserves all table-level metadata.

```sql
DELETE FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE ({{ key_columns }}, {{ tiebreaker_column }}) IN (
    SELECT {{ key_columns }}, {{ tiebreaker_column }}
    FROM (
        SELECT
            {{ key_columns }},
            {{ tiebreaker_column }},
            ROW_NUMBER() OVER (
                PARTITION BY {{ key_columns }}
                ORDER BY {{ tiebreaker_column }} DESC
            ) AS rn
        FROM {{ database }}.{{ schema }}.{{ asset }}
    )
    WHERE rn > 1
)
```

## Fix: CREATE OR REPLACE TABLE — keep first (fallback)

**Warning:** `CREATE OR REPLACE TABLE` drops grants, row access policies, masking policies (table and column), tags, streams built on the table, change tracking state, clustering key, search optimization, and table/column comments. Re-apply these after running this fix. Prefer the DELETE-based variant unless full-table rewrite is explicitly desired.

```sql
CREATE OR REPLACE TABLE {{ database }}.{{ schema }}.{{ asset }} AS
SELECT *
FROM {{ database }}.{{ schema }}.{{ asset }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY {{ key_columns }} ORDER BY {{ tiebreaker_column }} ASC) = 1
```

## Fix: CREATE OR REPLACE TABLE — keep last (fallback)

Same warnings as the "keep first" variant above.

```sql
CREATE OR REPLACE TABLE {{ database }}.{{ schema }}.{{ asset }} AS
SELECT *
FROM {{ database }}.{{ schema }}.{{ asset }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY {{ key_columns }} ORDER BY {{ tiebreaker_column }} DESC) = 1
```

# Fix: referential_integrity

Fraction of foreign-key or cross-dataset reference values that successfully resolve to valid target records.

## Context

Deletion is irreversible — verify orphan records are truly invalid before removing.

Foreign key constraints in Snowflake are not enforced — they are metadata hints. Always run the diagnostic query first and review orphaned rows before applying any fix.

Placeholders match `check.md`: `{{ fk_column }}`, `{{ ref_namespace }}`, `{{ ref_asset }}`, `{{ ref_key }}`. `ref_namespace` may be `{{ database }}.{{ schema }}` or a different schema in the same database.

`NOT EXISTS` is used instead of `NOT IN (subquery)` because Snowflake's `NOT IN` returns UNKNOWN and deletes nothing if the reference table contains any NULL in `{{ ref_key }}`. The explicit `{{ fk_column }} IS NOT NULL` filter preserves rows whose FK is intentionally null (same semantics as `check.md`, which excludes null FKs from both numerator and denominator).

## Fix: Delete orphan references

Removes rows from the source table whose FK value does not exist in the reference table.

```sql
DELETE FROM {{ database }}.{{ schema }}.{{ asset }} src
WHERE src.{{ fk_column }} IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM {{ ref_namespace }}.{{ ref_asset }} ref
      WHERE ref.{{ ref_key }} = src.{{ fk_column }}
  )
```
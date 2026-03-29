# Fix: referential_integrity

Fraction of foreign-key or cross-dataset reference values that successfully resolve to valid target records.

## Context

Deletion is irreversible — verify orphan records are truly invalid before removing.

Foreign key constraints in Snowflake are not enforced — they are metadata hints. Always run the diagnostic query first and review orphaned rows before applying any fix.

### Delete orphan references

Removes rows from the source table whose FK value does not exist in the target table.

## SQL

```sql
DELETE FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ fk_column }} NOT IN (
    SELECT {{ target_key }}
    FROM {{ database }}.{{ target_namespace }}.{{ target_asset }}
)
```
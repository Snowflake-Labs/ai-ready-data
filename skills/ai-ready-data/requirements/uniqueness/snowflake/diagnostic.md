# Diagnostic: uniqueness

Per-key-combination breakdown of duplicate records.

## Context

Groups rows by `key_columns` and returns the top 50 duplicate groups ordered by frequency. Use this to identify which specific key combinations have the most duplicates and to decide on a deduplication strategy (keep first vs. keep last by tiebreaker column).

## SQL

```sql
SELECT
    {{ key_columns }},
    COUNT(*) AS duplicate_count
FROM {{ database }}.{{ schema }}.{{ asset }}
GROUP BY {{ key_columns }}
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 50
```
# Diagnostic: consent_coverage

Per-table breakdown of consent/legal-basis documentation status.

## Context

Shows each base table with its table comment and a status label: `HAS_CONSENT_BASIS` if the comment contains recognized consent keywords, `NO_CONSENT_BASIS` otherwise. Use this to identify which tables need a legal basis documented for AI processing.

Recognized keywords in comments: `consent`, `legal_basis`, `legitimate_interest`, `processing_basis`, `gdpr`.

## SQL

```sql
SELECT
    c.relname AS table_name,
    COALESCE(s.n_live_tup, 0) AS estimated_row_count,
    obj_description(c.oid) AS table_comment,
    CASE
        WHEN obj_description(c.oid) IS NOT NULL
            AND (
                LOWER(obj_description(c.oid)) LIKE '%consent%'
                OR LOWER(obj_description(c.oid)) LIKE '%legal_basis%'
                OR LOWER(obj_description(c.oid)) LIKE '%legitimate_interest%'
                OR LOWER(obj_description(c.oid)) LIKE '%processing_basis%'
                OR LOWER(obj_description(c.oid)) LIKE '%gdpr%'
            )
        THEN 'HAS_CONSENT_BASIS'
        ELSE 'NO_CONSENT_BASIS'
    END AS status
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_stat_user_tables s ON s.relid = c.oid
WHERE n.nspname = '{{ schema }}'
    AND c.relkind = 'r'
ORDER BY status DESC, c.relname
```

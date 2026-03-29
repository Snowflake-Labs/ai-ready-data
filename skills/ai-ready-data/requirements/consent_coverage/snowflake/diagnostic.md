# Diagnostic: consent_coverage

Per-table breakdown of consent/legal-basis tag status.

## Context

Shows each base table with its consent-related tag (if any) and a status label: `HAS_CONSENT_BASIS` or `NO_CONSENT_BASIS`. Use this to identify which tables need a legal basis documented for AI processing.

Recognized tags: `consent_basis`, `legal_basis`, `processing_basis`, `consent`.

`account_usage.tag_references` has approximately 2-hour latency.

## SQL

```sql
SELECT
    t.table_name,
    t.row_count,
    tr.tag_name AS consent_tag,
    tr.tag_value AS consent_value,
    CASE
        WHEN tr.tag_name IS NOT NULL THEN 'HAS_CONSENT_BASIS'
        ELSE 'NO_CONSENT_BASIS'
    END AS status
FROM {{ database }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON UPPER(tr.object_database) = UPPER('{{ database }}')
    AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
    AND UPPER(tr.object_name) = UPPER(t.table_name)
    AND tr.domain = 'TABLE'
    AND LOWER(tr.tag_name) IN ('consent_basis', 'legal_basis', 'processing_basis', 'consent')
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
```

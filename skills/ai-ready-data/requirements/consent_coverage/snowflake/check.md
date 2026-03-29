# Check: consent_coverage

Fraction of tables tagged with a documented legal basis for AI-specific processing.

## Context

Detects whether tables have been tagged with any recognized consent/legal-basis tags: `consent_basis`, `legal_basis`, `processing_basis`, `consent`. The tag records that a legal basis has been documented for AI processing of the data in this table — the check does not verify the substance of the consent.

This is a governance signal. Typical legal basis values include: `consent`, `legitimate_interest`, `contract`, `legal_obligation`, `public_interest`, `vital_interest` (aligned with GDPR Article 6).

`account_usage.tag_references` has approximately 2-hour latency for newly applied tags.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
consent_tagged AS (
    SELECT COUNT(DISTINCT tr.object_name) AS cnt
    FROM snowflake.account_usage.tag_references tr
    JOIN {{ database }}.information_schema.tables t
        ON UPPER(tr.object_name) = UPPER(t.table_name)
        AND t.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
    WHERE UPPER(tr.object_database) = UPPER('{{ database }}')
        AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
        AND tr.domain = 'TABLE'
        AND LOWER(tr.tag_name) IN ('consent_basis', 'legal_basis', 'processing_basis', 'consent')
)
SELECT
    consent_tagged.cnt AS tables_with_consent,
    table_count.cnt AS total_tables,
    consent_tagged.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, consent_tagged
```

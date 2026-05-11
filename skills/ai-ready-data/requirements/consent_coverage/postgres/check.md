# Check: consent_coverage

Fraction of tables with a documented legal basis for AI-specific processing.

## Context

PostgreSQL does not have a native tagging system like Snowflake's `account_usage.tag_references`. Instead, this check uses table comments (`obj_description`) as the documentation mechanism. A table is considered covered if its comment contains any of the recognized consent keywords: `consent`, `legal_basis`, `legitimate_interest`, `processing_basis`, `gdpr`.

This is a governance signal. The check detects whether a legal basis has been documented — it does not verify the substance of the consent. Typical legal basis values include: `consent`, `legitimate_interest`, `contract`, `legal_obligation`, `public_interest`, `vital_interest` (aligned with GDPR Article 6).

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
consent_documented AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND obj_description(c.oid) IS NOT NULL
        AND (
            LOWER(obj_description(c.oid)) LIKE '%consent%'
            OR LOWER(obj_description(c.oid)) LIKE '%legal_basis%'
            OR LOWER(obj_description(c.oid)) LIKE '%legitimate_interest%'
            OR LOWER(obj_description(c.oid)) LIKE '%processing_basis%'
            OR LOWER(obj_description(c.oid)) LIKE '%gdpr%'
        )
)
SELECT
    consent_documented.cnt AS tables_with_consent,
    table_count.cnt AS total_tables,
    consent_documented.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, consent_documented
```

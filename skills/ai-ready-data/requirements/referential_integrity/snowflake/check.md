# Check: referential_integrity

Fraction of non-null foreign-key values that resolve to a valid target record.

## Context

Performs a `LEFT JOIN` from the source table's FK column to the reference table's key column and counts how many non-null source FKs have no matching target (orphans). A score of 1.0 means every non-null FK resolves successfully.

NULL foreign keys are **excluded** from both the denominator and the numerator — a NULL FK is not considered an integrity violation here. If the column is expected to be NOT NULL, combine this check with `data_completeness` on the same column.

Foreign key constraints in Snowflake are not enforced — they are metadata hints. This check validates actual referential integrity by querying the data directly.

Placeholders: `database`, `schema`, `asset`, `fk_column`, `ref_namespace`, `ref_asset`, `ref_key`. `ref_namespace` may be `{database}.{schema}` or a different schema in the same database.

## SQL

```sql
WITH fk_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT_IF(target.{{ ref_key }} IS NULL) AS orphan_rows
    FROM {{ database }}.{{ schema }}.{{ asset }} source
    LEFT JOIN {{ ref_namespace }}.{{ ref_asset }} target
        ON source.{{ fk_column }} = target.{{ ref_key }}
    WHERE source.{{ fk_column }} IS NOT NULL
)
SELECT
    orphan_rows,
    total_rows,
    1.0 - (orphan_rows::FLOAT / NULLIF(total_rows::FLOAT, 0)) AS value
FROM fk_check
```

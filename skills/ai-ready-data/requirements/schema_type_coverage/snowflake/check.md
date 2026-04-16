# Check: schema_type_coverage

Fraction of columns across the schema that carry a recognizable semantic-role signal — either via a non-empty `COMMENT` or via a naming pattern that implies a well-known role (ID, date, amount, status, etc.).

## Context

In Snowflake every column has a declared physical type (`TEXT`, `NUMBER`, etc.), so "type declaration" coverage is trivially 100%. This check measures a stricter but more useful signal: whether a downstream consumer can **infer the semantic role** of a column from its metadata. A column counts as "typed" if it either has a non-empty comment or its name matches a known role suffix or substring.

Patterns are matched via `REGEXP_LIKE` with anchored underscores so `LIKE '%_id'` doesn't spuriously match `USERXID`.

Pattern families (case-insensitive):

- Identifier/key: `_id`, `_key` suffixes
- Temporal: `_date`, `_at`, `_time` suffixes or `time` substring
- Measurement: `amount`, `price`, `cost`, `count`, `quantity`, `total` substrings
- Descriptive: `name`, `description`, `status`, `type`, `category` substrings

## SQL

```sql
WITH columns_in_scope AS (
    SELECT
        c.table_name,
        c.column_name,
        c.comment
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE UPPER(c.table_schema) = UPPER('{{ schema }}')
        AND t.table_type = 'BASE TABLE'
),
columns_with_semantic_type AS (
    SELECT *
    FROM columns_in_scope
    WHERE (comment IS NOT NULL AND comment <> '')
       OR REGEXP_LIKE(
            LOWER(column_name),
            '.*(_id$|_key$|_date$|_at$|_time$|time|amount|price|cost|count|quantity|total|name|description|status|type|category).*'
          )
)
SELECT
    (SELECT COUNT(*) FROM columns_with_semantic_type) AS columns_with_semantic_type,
    (SELECT COUNT(*) FROM columns_in_scope) AS total_columns,
    (SELECT COUNT(*) FROM columns_with_semantic_type)::FLOAT
        / NULLIF((SELECT COUNT(*) FROM columns_in_scope)::FLOAT, 0) AS value
```

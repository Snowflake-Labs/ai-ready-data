# Diagnostic: schema_conformity

Columns with potential type mismatches, with a specific issue description for each.

## Context

Lists every column in the table whose declared type conflicts with its naming convention. Each row includes a human-readable issue string explaining the mismatch (e.g., "ID column stored as character varying - consider integer or uuid"). PostgreSQL reports lowercase type names in `information_schema` (e.g., `character varying`, `jsonb`, `double precision`).

Use this to identify exactly which columns need type changes and what the recommended target type is.

## SQL

```sql
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    CASE
        WHEN data_type = 'jsonb' AND column_name NOT LIKE '%json%' AND column_name NOT LIKE '%payload%'
            THEN 'JSONB may be too permissive - consider structured columns'
        WHEN data_type = 'character varying' AND column_name LIKE '%\_id' AND column_name NOT LIKE '%uuid%'
            THEN 'ID column stored as character varying - consider integer or uuid'
        WHEN data_type = 'character varying' AND (column_name LIKE '%\_date' OR column_name LIKE '%\_at' OR column_name LIKE '%\_time')
            THEN 'Date/time column stored as character varying - consider timestamp'
        WHEN data_type IN ('double precision', 'real') AND (column_name LIKE '%\_count' OR column_name LIKE '%\_qty' OR column_name LIKE '%\_quantity')
            THEN 'Count column stored as float - consider integer'
        ELSE 'Review type appropriateness'
    END AS issue
FROM information_schema.columns
WHERE table_schema = '{{ schema }}'
    AND table_name = '{{ asset }}'
    AND (
        (data_type = 'jsonb' AND column_name NOT LIKE '%json%' AND column_name NOT LIKE '%payload%')
        OR (data_type = 'character varying' AND column_name LIKE '%\_id' AND column_name NOT LIKE '%uuid%')
        OR (data_type = 'character varying' AND (column_name LIKE '%\_date' OR column_name LIKE '%\_at' OR column_name LIKE '%\_time'))
        OR (data_type IN ('double precision', 'real') AND (column_name LIKE '%\_count' OR column_name LIKE '%\_qty' OR column_name LIKE '%\_quantity'))
    )
ORDER BY table_name, column_name
```

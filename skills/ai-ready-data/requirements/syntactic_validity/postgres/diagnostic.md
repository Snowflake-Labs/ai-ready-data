# Diagnostic: syntactic_validity

Rows where JSON parsing fails, showing the invalid values and their lengths.

## Context

Returns up to 100 rows where the column value cannot be parsed as valid JSON. The `value_preview` column truncates to 200 characters for readability. Use the key columns to locate specific failing records for manual inspection or targeted remediation.

Requires the `pg_temp.is_valid_json` helper function from the check query. PostgreSQL does not have a native `TRY_PARSE_JSON` — the helper catches cast exceptions.

## SQL

### Prerequisite: create helper function (if not already created)

```sql
CREATE OR REPLACE FUNCTION pg_temp.is_valid_json(val text) RETURNS boolean AS $$
BEGIN
    IF val IS NULL THEN RETURN TRUE; END IF;
    PERFORM val::jsonb;
    RETURN TRUE;
EXCEPTION WHEN others THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### Diagnostic query

```sql
SELECT
    {{ key_columns }},
    {{ column }} AS invalid_value,
    LEFT({{ column }}::text, 200) AS value_preview,
    LENGTH({{ column }}::text) AS length
FROM {{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
    AND NOT pg_temp.is_valid_json({{ column }}::text)
LIMIT 100
```

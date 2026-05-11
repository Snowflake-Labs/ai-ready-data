# Check: syntactic_validity

Fraction of raw data records that parse without structural errors, including well-formed serialization and correct delimiters.

## Context

JSON validity uses a cast to `jsonb` — PostgreSQL will raise an error on invalid JSON, so we catch failures by attempting the cast in a `CASE` expression. NULL values in the source column are counted as valid (they represent missing data, not malformed data). Use for `jsonb` columns or `text`/`varchar` columns containing JSON.

PostgreSQL does not have a `TRY_PARSE_JSON` equivalent. Instead, we define a helper function that attempts the cast and returns `FALSE` on failure. Alternatively, for PG 16+, the expression `{{ column }}::jsonb` can be tested with exception handling in PL/pgSQL. The SQL below uses a safe-cast approach via a reusable function.

A score of 1.0 means every non-null value in the column parses as valid JSON.

## SQL

### Create helper function (run once per database)

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

### Check query

```sql
SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE
        WHEN pg_temp.is_valid_json({{ column }}::text) THEN 1 ELSE 0
    END) AS valid_rows,
    SUM(CASE
        WHEN pg_temp.is_valid_json({{ column }}::text) THEN 1 ELSE 0
    END)::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0) AS value
FROM {{ schema }}.{{ asset }}
```

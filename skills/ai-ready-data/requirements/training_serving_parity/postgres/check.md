# Check: training_serving_parity

Fraction of feature entities with consistent training (batch) and serving (real-time) computation paths.

## Context

Snowflake checks for dynamic tables as a parity signal — dynamic tables provide auto-refreshing materialization that can serve both training and real-time paths. PostgreSQL has no dynamic tables, but the equivalent pattern uses:

- **Materialized views** as the batch/training path (periodic `REFRESH MATERIALIZED VIEW`)
- **Functions** as the serving/real-time path (on-demand computation)

This check uses a heuristic: count tables with feature-like names (`%feature%` or `%feat_%`) that have *both* a corresponding materialized view and a function in the same schema with a matching name pattern. A table with both paths is considered parity-ready. A table with only a materialized view or only a function has a partial path.

This is inherently heuristic — true parity verification requires comparing the transformation logic inside the materialized view definition and the function body, which is beyond what metadata queries can achieve.

## SQL

```sql
WITH feature_tables AS (
    SELECT c.relname AS table_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND (LOWER(c.relname) LIKE '%feature%' OR LOWER(c.relname) LIKE '%feat_%')
),
matview_names AS (
    SELECT matviewname AS name
    FROM pg_matviews
    WHERE schemaname = '{{ schema }}'
),
function_names AS (
    SELECT routine_name AS name
    FROM information_schema.routines
    WHERE routine_schema = '{{ schema }}'
        AND routine_type = 'FUNCTION'
),
tables_with_both AS (
    SELECT ft.table_name
    FROM feature_tables ft
    WHERE EXISTS (
        SELECT 1 FROM matview_names mv
        WHERE mv.name LIKE '%' || ft.table_name || '%'
           OR ft.table_name LIKE '%' || mv.name || '%'
    )
    AND EXISTS (
        SELECT 1 FROM function_names fn
        WHERE fn.name LIKE '%' || ft.table_name || '%'
           OR ft.table_name LIKE '%' || fn.name || '%'
    )
)
SELECT
    (SELECT COUNT(*) FROM tables_with_both) AS parity_ready_tables,
    (SELECT COUNT(*) FROM feature_tables) AS total_feature_tables,
    (SELECT COUNT(*) FROM tables_with_both)::NUMERIC
        / NULLIF((SELECT COUNT(*) FROM feature_tables)::NUMERIC, 0) AS value
```

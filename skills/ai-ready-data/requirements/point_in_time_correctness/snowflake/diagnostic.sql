-- diagnostic-point-in-time-correctness.sql
-- Lists tables and their event timestamp columns for point-in-time join capability
-- Returns: tables with timestamp column details

WITH timestamp_columns AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name,
        c.data_type,
        c.is_nullable,
        c.comment
    FROM {{ database }}.information_schema.columns c
    INNER JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
        AND c.data_type IN ('DATE', 'DATETIME', 'TIMESTAMP_LTZ', 'TIMESTAMP_NTZ', 'TIMESTAMP_TZ')
),
tables_summary AS (
    SELECT
        table_name,
        COUNT(*) AS timestamp_column_count,
        LISTAGG(column_name, ', ') AS timestamp_columns
    FROM timestamp_columns
    GROUP BY table_name
)
SELECT
    t.table_catalog AS database_name,
    t.table_schema AS schema_name,
    t.table_name,
    COALESCE(ts.timestamp_column_count, 0) AS timestamp_column_count,
    COALESCE(ts.timestamp_columns, 'NONE') AS timestamp_columns,
    CASE
        WHEN ts.timestamp_column_count > 0 THEN 'HAS_TIMESTAMPS'
        ELSE 'NO_TIMESTAMPS'
    END AS pit_capability,
    CASE
        WHEN ts.timestamp_column_count > 0 THEN 'Can support point-in-time joins'
        ELSE 'Add event timestamp column for temporal queries'
    END AS recommendation
FROM {{ database }}.information_schema.tables t
LEFT JOIN tables_summary ts ON t.table_name = ts.table_name
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY pit_capability DESC, t.table_name

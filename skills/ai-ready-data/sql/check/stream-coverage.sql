WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
streamed_tables AS (
    SELECT COUNT(DISTINCT table_name) AS cnt
    FROM {{ database }}.information_schema.streams
    WHERE table_schema = '{{ schema }}'
)
SELECT
    streamed_tables.cnt AS tables_with_streams,
    table_count.cnt AS total_tables,
    streamed_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, streamed_tables

WITH column_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ container }}.information_schema.columns c
    JOIN {{ container }}.information_schema.tables t
        ON c.table_name = t.table_name AND c.table_schema = t.table_schema
    WHERE c.table_schema = '{{ namespace }}'
        AND t.table_type = 'BASE TABLE'
),
tagged_columns AS (
    SELECT COUNT(DISTINCT column_name) AS cnt
    FROM snowflake.account_usage.tag_references
    WHERE object_database = '{{ container }}'
        AND object_schema = '{{ namespace }}'
        AND domain = 'COLUMN'
)
SELECT
    tagged_columns.cnt AS tagged_columns,
    column_count.cnt AS total_columns,
    tagged_columns.cnt::FLOAT / NULLIF(column_count.cnt::FLOAT, 0) AS value
FROM column_count, tagged_columns

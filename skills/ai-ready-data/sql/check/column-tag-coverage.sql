WITH column_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_name = t.table_name AND c.table_schema = t.table_schema
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
),
tagged_columns AS (
    SELECT COUNT(DISTINCT UPPER(object_name) || '.' || UPPER(column_name)) AS cnt
    FROM snowflake.account_usage.tag_references tr
    JOIN {{ database }}.information_schema.columns c
        ON UPPER(tr.object_name) = UPPER(c.table_name)
        AND UPPER(tr.column_name) = UPPER(c.column_name)
        AND c.table_schema = '{{ schema }}'
    WHERE UPPER(tr.object_database) = UPPER('{{ database }}')
        AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
        AND tr.domain = 'COLUMN'
)
SELECT
    tagged_columns.cnt AS tagged_columns,
    column_count.cnt AS total_columns,
    tagged_columns.cnt::FLOAT / NULLIF(column_count.cnt::FLOAT, 0) AS value
FROM column_count, tagged_columns

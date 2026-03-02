WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
tables_with_downstream AS (
    SELECT COUNT(DISTINCT referencing_object_name) AS cnt
    FROM snowflake.account_usage.object_dependencies
    WHERE referenced_database = '{{ database }}'
        AND referenced_schema = '{{ schema }}'
        AND referenced_object_domain = 'TABLE'
)
SELECT
    tables_with_downstream.cnt AS tables_with_dependents,
    table_count.cnt AS total_tables,
    tables_with_downstream.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, tables_with_downstream

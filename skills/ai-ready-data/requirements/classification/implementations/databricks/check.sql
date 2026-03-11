WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
      AND table_type = 'BASE TABLE'
),
tagged_tables AS (
    SELECT COUNT(DISTINCT table_name) AS cnt
    FROM {{ database }}.information_schema.table_tags
    WHERE schema_name = '{{ schema }}'
)
SELECT
    tagged_tables.cnt AS tagged_tables,
    table_count.cnt AS total_tables,
    CAST(tagged_tables.cnt AS DOUBLE) / NULLIF(CAST(table_count.cnt AS DOUBLE), 0) AS value
FROM table_count, tagged_tables

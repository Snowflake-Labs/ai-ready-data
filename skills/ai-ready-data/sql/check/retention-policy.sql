WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'BASE TABLE'
),
tagged_retention AS (
    SELECT COUNT(DISTINCT object_name) AS cnt
    FROM snowflake.account_usage.tag_references
    WHERE object_database = '{{ container }}'
        AND object_schema = '{{ namespace }}'
        AND domain = 'TABLE'
        AND LOWER(tag_name) IN ('retention_days', 'retention_policy', 'data_retention', 'ttl')
)
SELECT
    tagged_retention.cnt AS tables_with_retention,
    table_count.cnt AS total_tables,
    tagged_retention.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, tagged_retention

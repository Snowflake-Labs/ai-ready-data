WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'BASE TABLE'
),
license_tagged AS (
    SELECT COUNT(DISTINCT object_name) AS cnt
    FROM snowflake.account_usage.tag_references
    WHERE object_database = '{{ container }}'
        AND object_schema = '{{ namespace }}'
        AND domain = 'TABLE'
        AND LOWER(tag_name) IN ('license', 'data_license', 'usage_license', 'license_type')
)
SELECT
    license_tagged.cnt AS tables_with_license,
    table_count.cnt AS total_tables,
    license_tagged.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, license_tagged

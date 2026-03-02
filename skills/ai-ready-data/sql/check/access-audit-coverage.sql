WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
audited_tables AS (
    SELECT COUNT(DISTINCT direct_objects_accessed[0]:objectName::STRING) AS cnt
    FROM snowflake.account_usage.access_history
    WHERE direct_objects_accessed[0]:objectDomain::STRING = 'Table'
        AND UPPER(direct_objects_accessed[0]:objectName::STRING) LIKE UPPER('{{ database }}.{{ schema }}.%')
        AND query_start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
)
SELECT
    audited_tables.cnt AS tables_with_audit,
    table_count.cnt AS total_tables,
    audited_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, audited_tables

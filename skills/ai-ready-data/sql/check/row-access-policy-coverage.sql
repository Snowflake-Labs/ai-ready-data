WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'BASE TABLE'
),
rap_tables AS (
    SELECT COUNT(DISTINCT ref_entity_name) AS cnt
    FROM snowflake.account_usage.policy_references
    WHERE ref_database_name = '{{ container }}'
        AND ref_schema_name = '{{ namespace }}'
        AND policy_kind = 'ROW_ACCESS_POLICY'
)
SELECT
    rap_tables.cnt AS tables_with_rap,
    table_count.cnt AS total_tables,
    rap_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, rap_tables

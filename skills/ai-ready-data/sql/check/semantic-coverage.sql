WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'BASE TABLE'
),
covered_tables AS (
    SELECT COUNT(DISTINCT st.base_table_name) AS cnt
    FROM {{ container }}.information_schema.semantic_tables st
    WHERE st.base_table_schema = '{{ namespace }}'
)
SELECT
    covered_tables.cnt AS tables_with_semantics,
    table_count.cnt AS total_tables,
    covered_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, covered_tables

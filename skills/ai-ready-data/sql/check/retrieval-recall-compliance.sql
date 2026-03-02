WITH vector_tables AS (
    SELECT COUNT(DISTINCT c.table_name) AS total_vector_tables
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_name = t.table_name AND c.table_schema = t.table_schema
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
        AND c.data_type = 'VECTOR'
),
indexed_vector_tables AS (
    SELECT COUNT(DISTINCT c.table_name) AS indexed_count
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_name = t.table_name AND c.table_schema = t.table_schema
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
        AND c.data_type = 'VECTOR'
        AND t.search_optimization = 'ON'
)
SELECT
    indexed_vector_tables.indexed_count AS indexed_tables,
    vector_tables.total_vector_tables AS total_vector_tables,
    indexed_vector_tables.indexed_count::FLOAT / NULLIF(vector_tables.total_vector_tables::FLOAT, 0) AS value
FROM vector_tables, indexed_vector_tables

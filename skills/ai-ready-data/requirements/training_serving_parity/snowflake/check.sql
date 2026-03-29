WITH dynamic_feature_tables AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'DYNAMIC TABLE'
        AND (
            LOWER(table_name) LIKE '%feature%'
            OR LOWER(table_name) LIKE '%feat_%'
        )
),
all_feature_tables AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type IN ('BASE TABLE', 'DYNAMIC TABLE')
        AND (
            LOWER(table_name) LIKE '%feature%'
            OR LOWER(table_name) LIKE '%feat_%'
        )
)
SELECT
    dynamic_feature_tables.cnt AS dynamic_feature_tables,
    all_feature_tables.cnt AS total_feature_tables,
    dynamic_feature_tables.cnt::FLOAT / NULLIF(all_feature_tables.cnt::FLOAT, 0) AS value
FROM dynamic_feature_tables, all_feature_tables

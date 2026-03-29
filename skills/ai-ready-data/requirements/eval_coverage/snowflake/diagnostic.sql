SELECT
    t.table_name,
    CASE
      WHEN EXISTS (
        SELECT 1 FROM {{ database }}.information_schema.tables e
        WHERE e.table_schema = '{{ schema }}'
          AND e.table_type = 'BASE TABLE'
          AND (
            LOWER(e.table_name) = LOWER(t.table_name || '_eval')
            OR LOWER(e.table_name) = LOWER('eval_' || t.table_name)
          )
      ) THEN 'HAS_EVAL'
      ELSE 'NO_EVAL'
    END AS eval_status
FROM {{ database }}.information_schema.tables t
WHERE t.table_schema = '{{ schema }}'
  AND t.table_type = 'BASE TABLE'
ORDER BY eval_status DESC, t.table_name

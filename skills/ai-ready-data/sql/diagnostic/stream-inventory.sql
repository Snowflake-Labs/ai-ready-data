SELECT
    stream_name,
    table_name,
    type AS stream_type,
    stale,
    stale_after
FROM {{ database }}.information_schema.streams
WHERE table_schema = '{{ schema }}'
ORDER BY table_name, stream_name

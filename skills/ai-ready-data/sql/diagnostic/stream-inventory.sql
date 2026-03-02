SELECT
    stream_name,
    table_name,
    type AS stream_type,
    stale,
    stale_after
FROM {{ container }}.information_schema.streams
WHERE table_schema = '{{ namespace }}'
ORDER BY table_name, stream_name

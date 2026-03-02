CREATE STREAM IF NOT EXISTS {{ container }}.{{ namespace }}.{{ stream_name }}
ON TABLE {{ container }}.{{ namespace }}.{{ asset }}

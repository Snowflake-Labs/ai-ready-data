CREATE STREAM IF NOT EXISTS {{ database }}.{{ schema }}.{{ stream_name }}
ON TABLE {{ database }}.{{ schema }}.{{ asset }}

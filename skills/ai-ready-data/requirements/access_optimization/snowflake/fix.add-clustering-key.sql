ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
CLUSTER BY ({{ clustering_columns }})

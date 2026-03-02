ALTER TABLE {{ container }}.{{ namespace }}.{{ asset }}
CLUSTER BY ({{ clustering_columns }})

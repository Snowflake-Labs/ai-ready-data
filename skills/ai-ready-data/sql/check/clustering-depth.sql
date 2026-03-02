SELECT
    '{{ asset }}' AS table_name,
    SYSTEM$CLUSTERING_DEPTH('{{ container }}.{{ namespace }}.{{ asset }}') AS clustering_depth,
    SYSTEM$CLUSTERING_INFORMATION('{{ container }}.{{ namespace }}.{{ asset }}') AS clustering_info

SELECT
    '{{ asset }}' AS table_name,
    SYSTEM$CLUSTERING_DEPTH('{{ database }}.{{ schema }}.{{ asset }}') AS clustering_depth,
    SYSTEM$CLUSTERING_INFORMATION('{{ database }}.{{ schema }}.{{ asset }}') AS clustering_info

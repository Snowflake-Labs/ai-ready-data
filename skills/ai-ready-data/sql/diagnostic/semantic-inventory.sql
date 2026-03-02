SELECT
    sv.name AS semantic_view_name,
    st.name AS logical_table_name,
    st.base_table_name,
    st.comment AS table_description
FROM {{ container }}.information_schema.semantic_views sv
JOIN {{ container }}.information_schema.semantic_tables st
    ON sv.catalog = st.semantic_view_catalog
    AND sv.schema = st.semantic_view_schema
    AND sv.name = st.semantic_view_name
WHERE sv.schema = '{{ namespace }}'
ORDER BY sv.name, st.base_table_name

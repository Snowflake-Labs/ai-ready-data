SELECT
    policy_kind,
    policy_name,
    ref_entity_name AS table_name,
    ref_column_name AS column_name
FROM snowflake.account_usage.policy_references
WHERE ref_database_name = '{{ database }}'
    AND ref_schema_name = '{{ schema }}'
ORDER BY policy_kind, ref_entity_name, ref_column_name

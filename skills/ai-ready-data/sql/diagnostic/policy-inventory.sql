SELECT
    policy_kind,
    policy_name,
    ref_entity_name AS table_name,
    ref_column_name AS column_name
FROM snowflake.account_usage.policy_references
WHERE UPPER(ref_database_name) = UPPER('{{ database }}')
    AND UPPER(ref_schema_name) = UPPER('{{ schema }}')
ORDER BY policy_kind, ref_entity_name, ref_column_name

CREATE MASKING POLICY IF NOT EXISTS {{ container }}.{{ namespace }}.{{ policy_name }}
AS (val {{ data_type }}) RETURNS {{ data_type }} ->
CASE
    WHEN IS_ROLE_IN_SESSION('{{ privileged_role }}') THEN val
    ELSE {{ redacted_value }}
END

ALTER TABLE {{ container }}.{{ namespace }}.{{ asset }}
MODIFY COLUMN {{ field }}
SET MASKING POLICY {{ policy_name }}

ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
MODIFY COLUMN {{ column }}
SET MASKING POLICY {{ policy_name }}

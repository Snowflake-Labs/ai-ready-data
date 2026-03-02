ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
MODIFY COLUMN {{ column }}
SET TAG {{ tag_name }} = '{{ tag_value }}'

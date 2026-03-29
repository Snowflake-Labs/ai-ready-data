ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
ADD CONSTRAINT {{ constraint_name }} {{ constraint_type }} ({{ column }})

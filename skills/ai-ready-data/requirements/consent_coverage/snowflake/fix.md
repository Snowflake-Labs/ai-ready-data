# Fix: consent_coverage

Create consent/legal-basis tags and apply them to tables.

## Context

This is a governance process — the tag should only be applied after the organisation has determined and documented the legal basis for AI processing of the data in each table. Applying a tag without a real legal basis determination creates a false compliance signal.

Before creating the tag, check if it already exists:

```sql
SHOW TAGS LIKE '{{ tag_name }}' IN SCHEMA {{ database }}.{{ schema }};
```

If rows are returned, skip tag creation.

Common legal basis values (GDPR Article 6): `consent`, `legitimate_interest`, `contract`, `legal_obligation`, `public_interest`, `vital_interest`.

## Fix: Create the consent tag

```sql
CREATE TAG IF NOT EXISTS {{ database }}.{{ schema }}.{{ tag_name }}
    ALLOWED_VALUES {{ allowed_values }}
    COMMENT = '{{ comment }}'
```

## Fix: Apply consent tag to a table

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
SET TAG {{ database }}.{{ schema }}.{{ tag_name }} = '{{ tag_value }}'
```

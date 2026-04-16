# Fix: business_glossary_linkage

Add glossary linkage to undocumented columns via comments or tags.

## Context

Two approaches, in order of preference:
1. **Tags** — create a glossary tag and apply it to columns with their business term. This is the structured approach and enables programmatic discovery.
2. **Comments** — add meaningful column comments (>20 characters) that define the business term. This is simpler but less structured.

For schemas with many undocumented columns, consider using the `semantic_documentation` requirement's semantic view builder workflow, which creates comprehensive machine-readable metadata in a single pass.

Before creating the tag, check whether it already exists:

```sql
SHOW TAGS LIKE '{{ tag_name }}' IN SCHEMA {{ database }}.{{ schema }};
```

If rows are returned, skip the CREATE and go straight to the apply step.

`account_usage.tag_references` has approximately 2-hour latency — recently applied tags may not appear in the check immediately.

## Fix: Add column comments

```sql
COMMENT ON COLUMN {{ database }}.{{ schema }}.{{ asset }}.{{ column }} IS '{{ comment }}';
```

## Fix: Create a glossary tag

```sql
CREATE TAG IF NOT EXISTS {{ database }}.{{ schema }}.{{ tag_name }}
    COMMENT = '{{ comment }}';
```

## Fix: Apply the glossary tag to a column

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
MODIFY COLUMN {{ column }}
SET TAG {{ database }}.{{ schema }}.{{ tag_name }} = '{{ tag_value }}';
```

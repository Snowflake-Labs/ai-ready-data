# Fix: business_glossary_linkage

Add glossary linkage to undocumented columns via comments or security labels.

## Context

Two approaches, in order of preference:

1. **Column comments** — add meaningful column comments (>20 characters) that define the business term. This is the simplest approach and requires no special configuration.
2. **Security labels** — if a label provider is configured (e.g., `sepgsql`), attach structured labels to columns. This is more formal but requires server-level configuration.

PostgreSQL has no native tagging system like Snowflake. For organizations needing structured glossary linkage beyond comments, consider external catalog tools (DataHub, OpenMetadata) that integrate with PostgreSQL.

## Remediation: Add column comments

```sql
COMMENT ON COLUMN {{ schema }}.{{ asset }}.{{ column }} IS '{{ comment }}';
```

## Remediation: Apply security label (requires label provider)

```sql
SECURITY LABEL FOR {{ provider }} ON COLUMN {{ schema }}.{{ asset }}.{{ column }}
    IS '{{ label_value }}';
```

The label provider must be loaded via `shared_preload_libraries` in `postgresql.conf` before security labels can be applied. The most common provider is `sepgsql` (SELinux integration).

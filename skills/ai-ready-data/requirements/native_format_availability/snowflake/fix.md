# Fix: native_format_availability

Remediation guidance for datasets not in consumption-ready native formats.

## Context

In Snowflake, "native format" means data stored in managed Snowflake tables (BASE TABLE) rather than external tables pointing to files in object storage. Native tables benefit from Snowflake's query optimizer, micro-partition pruning, caching, and clustering — external tables do not.

There is no single DDL fix — remediation depends on the data source and consumption pattern.

## Remediation: Convert external tables to native tables

If the external table data is stable enough to be materialized:

```sql
CREATE TABLE {{ database }}.{{ schema }}.{{ asset }}_native AS
SELECT * FROM {{ database }}.{{ schema }}.{{ asset }};
```

Then update downstream references and drop the external table.

## Remediation: Use materialized views over external tables

If the data must stay external but query performance matters:

```sql
CREATE MATERIALIZED VIEW {{ database }}.{{ schema }}.{{ asset }}_mv AS
SELECT * FROM {{ database }}.{{ schema }}.{{ asset }};
```

Note: materialized views on external tables have limitations — consult Snowflake documentation for supported operations.

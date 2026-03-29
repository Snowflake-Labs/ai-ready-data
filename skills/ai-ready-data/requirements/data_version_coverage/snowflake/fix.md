# Fix: data_version_coverage

Remediation guidance for enabling data version coverage.

## Context

There are two complementary approaches to improving version coverage:

1. **Enable Time Travel** — Set a non-zero `DATA_RETENTION_TIME_IN_DAYS` on tables that currently have `retention_time = 0`. This enables Snowflake's built-in point-in-time state reconstruction. The default for most editions is 1 day; Enterprise edition supports up to 90 days.

2. **Add explicit version columns** — For tables where pipeline-level versioning is needed (e.g., for reproducible training snapshots), add a column such as `data_version`, `version_id`, `snapshot_id`, or `batch_id` and populate it during ingestion.

Choose based on your use case: Time Travel is sufficient for short-term rollback and auditing; explicit version columns are better for long-lived, pipeline-managed dataset versions.

## SQL

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ table_name }}
SET DATA_RETENTION_TIME_IN_DAYS = 90;
```
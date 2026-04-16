# Fix: data_provenance

Remediation guidance for adding source provenance documentation to tables.

## Context

PostgreSQL tables support comments via `COMMENT ON TABLE` that are stored in `pg_description` and retrieved with `obj_description()`. The check and diagnostic queries look for provenance keywords (`source`, `origin`, `from`, `upstream`, `loaded`, `extracted`) in comments longer than 20 characters.

To pass the provenance check, each table's comment should describe:

- **Origin system** — where the data was collected or extracted from (e.g., `Salesforce CRM`, `PostgreSQL production DB`).
- **Collection method** — how the data arrives (e.g., `Fivetran sync`, `daily batch ETL`, `Kafka stream`).
- **Upstream lineage** — any transformations or staging tables the data passed through before landing here.

## Remediation: Add provenance comment

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS
  'Source: <origin_system> | Method: <collection_method> | Upstream: <lineage_description>';
```

For tables that already have a non-provenance comment, prepend or append provenance details rather than replacing the existing content. PostgreSQL's `COMMENT ON` replaces the entire comment, so retrieve the existing comment first with `obj_description()` and concatenate.

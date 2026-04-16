# Fix: change_detection

Add tables to logical replication publications for CDC.

## Context

Two levels of change detection, applied based on your CDC architecture:

1. **Publication membership** — add tables to a logical replication publication so downstream consumers (Debezium, pg_recvlogical, custom subscribers) can receive change events. This requires `wal_level = logical` in `postgresql.conf`.
2. **Trigger-based audit** — create audit triggers that write changes to a history table. This works without logical replication and is the fallback for environments where `wal_level` cannot be changed.

Before creating a publication, check if one already exists:

```sql
SELECT pubname FROM pg_publication WHERE pubname = '{{ publication_name }}';
```

If rows are returned, use `ALTER PUBLICATION` to add tables to the existing publication.

## Remediation: Create a publication

```sql
CREATE PUBLICATION {{ publication_name }}
FOR TABLE {{ schema }}.{{ asset }}
```

## Remediation: Add a table to an existing publication

```sql
ALTER PUBLICATION {{ publication_name }}
ADD TABLE {{ schema }}.{{ asset }}
```

## Remediation: Publish all tables in schema

```sql
CREATE PUBLICATION {{ publication_name }}
FOR TABLES IN SCHEMA {{ schema }}
```

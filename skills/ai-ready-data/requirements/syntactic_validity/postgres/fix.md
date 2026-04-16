# Fix: syntactic_validity

Remediation guidance for columns with invalid JSON values.

## Context

There is no automated fix for syntactically invalid JSON — the correct repair depends on the root cause. Common causes include:

1. **Truncated payloads.** Upstream producers may be writing partial JSON due to size limits or timeouts. Check producer logs and increase any payload size caps.
2. **Encoding issues.** Unescaped special characters (e.g. unescaped quotes, control characters) break the JSON parser. Clean at the ingestion layer or use a function to strip/escape invalid characters before loading.
3. **Wrong column type.** Data may have been loaded into a `text` column as a raw string representation that includes extra escaping. Consider re-ingesting into a `jsonb` column — PostgreSQL validates JSON on insert into `jsonb` columns, catching issues at ingestion time.
4. **Mixed formats.** The column may contain a mix of JSON and non-JSON values (e.g. plain text, CSV fragments). Standardize the format upstream or split into separate columns.

PostgreSQL's `jsonb` type enforces valid JSON on write — migrating the column to `jsonb` will prevent future invalid values from being inserted.

# Fix: syntactic_validity

Remediation guidance for columns with invalid JSON values.

## Context

There is no automated fix for syntactically invalid JSON — the correct repair depends on the root cause. Common causes include:

1. **Truncated payloads.** Upstream producers may be writing partial JSON due to size limits or timeouts. Check producer logs and increase any payload size caps.
2. **Encoding issues.** Unescaped special characters (e.g. unescaped quotes, control characters) break the JSON parser. Clean at the ingestion layer or use a UDF to strip/escape invalid characters before loading.
3. **Wrong column type.** Data may have been loaded into a VARCHAR column as a raw string representation that includes extra escaping. Consider re-ingesting into a VARIANT column.
4. **Mixed formats.** The column may contain a mix of JSON and non-JSON values (e.g. plain text, CSV fragments). Standardize the format upstream or split into separate columns.
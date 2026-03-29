# Fix: schema_type_coverage

Remediation guidance for columns without semantic type coverage.

## Context

There is no automatic fix for missing semantic types. Improving coverage requires adding column comments that describe the semantic role of each column. Use the diagnostic query to identify `UNKNOWN` / `UNDOCUMENTED` columns, then add comments manually or via a scripted `ALTER TABLE ... ALTER COLUMN ... SET COMMENT` batch.
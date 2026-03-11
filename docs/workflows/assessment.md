# Assessment Workflow

## Flow

1. User selects platform.
2. Discovery: agent asks about database, schema, tables (conversational).
3. User picks workload profile or selects requirements.
4. Optional overrides (skip/set/add).
5. Coverage summary: show runnable vs N/A, user confirms.
6. Execute checks, score, report.

## Coverage Summary

Before execution, intersect selected requirements with platform implementations. Present:

```
{Workload} Assessment — {platform} — {DATABASE}.{SCHEMA}

Selected: {N} requirements
Runnable: {R}
Not available: {N-R}

Proceed?
```

## Rules

- `N/A` is identified before execution, not at runtime.
- Stage names are exactly the six factor names.
- Thresholds come from the workload profile.

# Execution Contract

How the assessment engine invokes requirement operations in a platform-aware way.

## Inputs

- `requirement_key` (string)
- `platform` (string: `snowflake`, `databricks`, `aws`, `azure`)
- `operation` (`check` | `diagnostic` | `fix`)
- `variant` (optional string)
- `context` (scope: database, schema, asset, column as applicable)

## Resolution

```
if variant given and {platform}/{operation}.{variant}.* exists:
  use that file

elif {platform}/{operation}.* exists:
  use that file

else:
  N/A (no implementation for this platform)
```

## Check Output

Check SQL must return a `value` column: float in [0, 1] where 1.0 is perfect.

## Status

- `PASS` — requirement met (`value >= threshold`)
- `FAIL` — requirement not met (`value < threshold`)
- `N/A` — no implementation or capability for this platform

## Assessment Compilation

An assessment is ephemeral — assembled at runtime from:

```
workload profile + platform + scope = assessment
```

Before execution, produce a coverage summary showing runnable vs N/A requirements.

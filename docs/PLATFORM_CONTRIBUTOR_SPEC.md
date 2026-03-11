# Platform Contributor Spec

This guide defines how maintainers add or extend platform support.

## Scope

Applies to any platform implementation (Snowflake, Databricks, AWS, Azure, others).

## Required Platform Files

For each platform `{platform}`:

```text
skills/ai-ready-data/platforms/{platform}/
  capabilities.yaml
  gotchas.md
  README.md
```

## Required Requirement Implementation Files

For each supported requirement `{requirement_key}`:

```text
skills/ai-ready-data/requirements/{requirement_key}/implementations/{platform}/
  check.sql
```

Recommended:

- `diagnostic.sql`
- one or more `fix.{name}.sql` files when safe and practical

## Capability Declaration

`capabilities.yaml` must conform to:

- `docs/platforms/capability-schema.md`

Declare only capabilities that are verified and supportable.

## Support Semantics

- If a requirement operation is not supported, return `N/A`.
- `N/A` must include a clear reason.
- Unsupported operations must not be misreported as `PASS` or `FAIL`.

## Safety and Idempotency for Fixes

- Prefer idempotent operations.
- When idempotency is not guaranteed, add explicit pre-check guards.
- Never execute mutating fixes without user approval.

## Documentation Requirements

Platform `README.md` must include:

- supported services and assumptions
- required permissions
- known gotchas
- supported requirement coverage notes

## Suggested PR Checklist

- [ ] Added or updated `capabilities.yaml`
- [ ] Added or updated requirement implementation files
- [ ] Added or updated platform docs
- [ ] Validated with `python3 scripts/validate_phase0.py`
- [ ] Included rationale for any `N/A` behavior

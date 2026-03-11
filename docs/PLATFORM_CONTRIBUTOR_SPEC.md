# Platform Contributor Spec

How to add or extend platform support.

## Required Files

For each platform:

```
skills/ai-ready-data/platforms/{PLATFORM}.md
```

Include idempotency guards, skill delegation targets, and any other platform-specific operational details directly in the platform markdown file.

## Platform Reference

The platform markdown file must cover:

- What the platform supports (capabilities)
- What is NOT supported (and why)
- Dialect notes and behavioral quirks
- Metadata access patterns
- Required permissions
- Anything the agent needs to operate correctly on this platform

## Requirement Implementations

For each supported requirement `{requirement_key}`:

```
skills/ai-ready-data/requirements/{requirement_key}/{platform}/
  check.sql         ← required (returns `value` column, float 0-1)
```

Recommended:

- `diagnostic.sql`
- `fix.{name}.sql` files when safe and practical
- `constraints.md` for platform-specific operational constraints

## Support Semantics

- If a requirement operation is not supported, report `N/A`.
- Unsupported operations must not be misreported as `PASS` or `FAIL`.

## Safety

- Prefer idempotent operations for fixes.
- When idempotency is not guaranteed, document guard patterns in the platform reference.
- Never execute mutating fixes without user approval.

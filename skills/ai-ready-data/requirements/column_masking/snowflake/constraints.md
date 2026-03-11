# Snowflake Constraints

## column_masking

- Always use IS_ROLE_IN_SESSION() — never CURRENT_ROLE()
- account_usage.policy_references has ~2 hour latency

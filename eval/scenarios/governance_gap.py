"""Governance gap scenario — compliance-heavy failures.

Data is clean and consumable, but governance is missing: no masking
policies, no access auditing, no retention policies, no classification
tags. Tests the agent's ability to identify and remediate compliance gaps.
"""

from eval.mocks.mock_snowflake import (
    MockColumn,
    MockDatabase,
    MockSchema,
    MockTable,
    RequirementScore,
    SnowflakeScenario,
)


def _build_database() -> MockDatabase:
    return MockDatabase(
        name="CUSTOMER_DATA",
        schemas=[
            MockSchema(
                name="PII_SCHEMA",
                tables=[
                    MockTable(
                        name="CUSTOMERS",
                        row_count=100_000,
                        comment="Customer records with PII",
                        has_change_tracking=True,
                        has_tags=False,
                        columns=[
                            MockColumn(name="CUSTOMER_ID", data_type="NUMBER", nullable=False, comment="PK"),
                            MockColumn(name="FULL_NAME", data_type="VARCHAR", nullable=False),
                            MockColumn(name="EMAIL", data_type="VARCHAR", nullable=False),
                            MockColumn(name="SSN", data_type="VARCHAR", nullable=True),
                            MockColumn(name="PHONE", data_type="VARCHAR", nullable=True),
                            MockColumn(name="ADDRESS", data_type="VARCHAR", nullable=True),
                            MockColumn(name="DATE_OF_BIRTH", data_type="DATE", nullable=True),
                        ],
                    ),
                    MockTable(
                        name="TRANSACTIONS",
                        row_count=2_000_000,
                        comment="Financial transactions",
                        has_clustering_key=True,
                        has_change_tracking=True,
                        columns=[
                            MockColumn(name="TXN_ID", data_type="NUMBER", nullable=False),
                            MockColumn(name="CUSTOMER_ID", data_type="NUMBER", nullable=False),
                            MockColumn(name="AMOUNT", data_type="NUMBER", nullable=False),
                            MockColumn(name="CURRENCY", data_type="VARCHAR", nullable=False),
                            MockColumn(name="TXN_DATE", data_type="TIMESTAMP_NTZ", nullable=False),
                            MockColumn(name="MERCHANT", data_type="VARCHAR", nullable=True),
                        ],
                    ),
                    MockTable(
                        name="RISK_SCORES",
                        row_count=100_000,
                        columns=[
                            MockColumn(name="CUSTOMER_ID", data_type="NUMBER", nullable=False),
                            MockColumn(name="SCORE", data_type="FLOAT", nullable=False),
                            MockColumn(name="MODEL_VERSION", data_type="VARCHAR", nullable=False),
                            MockColumn(name="SCORED_AT", data_type="TIMESTAMP_NTZ", nullable=False),
                        ],
                    ),
                ],
            ),
        ],
    )


GOVERNANCE_SCORES = [
    # Clean — excellent
    RequirementScore("data_completeness", 0.98, "CUSTOMERS"),
    RequirementScore("uniqueness", 1.0),
    RequirementScore("schema_conformity", 1.0),
    RequirementScore("syntactic_validity", 1.0),
    RequirementScore("encoding_validity", 1.0),

    # Contextual — decent
    RequirementScore("semantic_documentation", 0.70),
    RequirementScore("schema_type_coverage", 0.90),
    RequirementScore("entity_identifier_declaration", 0.80),

    # Consumable — good
    RequirementScore("access_optimization", 0.85),
    RequirementScore("search_optimization", 0.80),

    # Current — good
    RequirementScore("change_detection", 1.0),
    RequirementScore("data_freshness", 1.0),

    # Correlated — moderate
    RequirementScore("data_provenance", 0.60),
    RequirementScore("lineage_completeness", 0.50),

    # Compliant — FAILURES across the board
    RequirementScore("classification", 0.0),               # FAIL: no tags
    RequirementScore("column_masking", 0.0),                # FAIL: SSN/email unmasked
    RequirementScore("anonymization_effectiveness", 0.0),   # FAIL: PII exposed
    RequirementScore("access_audit_coverage", 0.10),        # FAIL: minimal auditing
    RequirementScore("retention_policy", 0.0),              # FAIL: no retention
    RequirementScore("purpose_limitation", 0.0),            # FAIL: no purpose tags
    RequirementScore("row_access_policy", 0.0),             # FAIL: no row policies
    RequirementScore("bias_testing_coverage", 0.0),         # FAIL on RISK_SCORES
]


GOVERNANCE_GAP = SnowflakeScenario(
    name="governance_gap",
    database=_build_database(),
    requirement_scores=GOVERNANCE_SCORES,
)

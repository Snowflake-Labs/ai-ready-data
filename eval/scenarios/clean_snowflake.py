"""Clean Snowflake scenario — all checks pass.

A well-governed Snowflake database where every requirement scores
above typical thresholds. Used as a baseline to verify the agent
correctly reports passing status and doesn't suggest unnecessary fixes.
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
        name="ANALYTICS",
        schemas=[
            MockSchema(
                name="PRODUCT_METRICS",
                tables=[
                    MockTable(
                        name="USERS",
                        row_count=50_000,
                        comment="Core user dimension table",
                        has_change_tracking=True,
                        has_tags=True,
                        columns=[
                            MockColumn(name="USER_ID", data_type="NUMBER", nullable=False, comment="Primary key"),
                            MockColumn(name="EMAIL", data_type="VARCHAR", nullable=False, comment="User email address"),
                            MockColumn(name="NAME", data_type="VARCHAR", nullable=False, comment="Display name"),
                            MockColumn(name="CREATED_AT", data_type="TIMESTAMP_NTZ", nullable=False, comment="Account creation timestamp"),
                            MockColumn(name="STATUS", data_type="VARCHAR", nullable=False, comment="Account status: active|inactive|suspended"),
                        ],
                    ),
                    MockTable(
                        name="EVENTS",
                        row_count=5_000_000,
                        comment="User activity events",
                        has_change_tracking=True,
                        has_clustering_key=True,
                        columns=[
                            MockColumn(name="EVENT_ID", data_type="NUMBER", nullable=False, comment="Primary key"),
                            MockColumn(name="USER_ID", data_type="NUMBER", nullable=False, comment="FK to USERS"),
                            MockColumn(name="EVENT_TYPE", data_type="VARCHAR", nullable=False, comment="Event category"),
                            MockColumn(name="PAYLOAD", data_type="VARIANT", nullable=True, comment="Event payload JSON"),
                            MockColumn(name="CREATED_AT", data_type="TIMESTAMP_NTZ", nullable=False, comment="Event timestamp"),
                        ],
                    ),
                    MockTable(
                        name="PRODUCTS",
                        row_count=10_000,
                        comment="Product catalog",
                        has_tags=True,
                        columns=[
                            MockColumn(name="PRODUCT_ID", data_type="NUMBER", nullable=False, comment="Primary key"),
                            MockColumn(name="NAME", data_type="VARCHAR", nullable=False, comment="Product name"),
                            MockColumn(name="DESCRIPTION", data_type="VARCHAR", nullable=True, comment="Product description"),
                            MockColumn(name="PRICE", data_type="NUMBER", nullable=False, comment="Price in cents"),
                            MockColumn(name="CATEGORY", data_type="VARCHAR", nullable=False, comment="Product category"),
                        ],
                    ),
                ],
            ),
        ],
    )


CLEAN_SCORES = [
    RequirementScore("data_completeness", 0.99, "USERS", "EMAIL"),
    RequirementScore("data_completeness", 1.0, "USERS", "NAME"),
    RequirementScore("uniqueness", 1.0, "USERS"),
    RequirementScore("schema_conformity", 1.0),
    RequirementScore("syntactic_validity", 1.0),
    RequirementScore("encoding_validity", 1.0),
    RequirementScore("semantic_documentation", 1.0),
    RequirementScore("schema_type_coverage", 1.0),
    RequirementScore("entity_identifier_declaration", 1.0),
    RequirementScore("temporal_scope_declaration", 1.0),
    RequirementScore("chunk_readiness", 0.95),
    RequirementScore("embedding_coverage", 0.92),
    RequirementScore("embedding_dimension_consistency", 1.0),
    RequirementScore("vector_index_coverage", 0.95),
    RequirementScore("retrieval_recall_compliance", 0.90),
    RequirementScore("search_optimization", 0.88),
    RequirementScore("change_detection", 1.0),
    RequirementScore("data_freshness", 1.0),
    RequirementScore("data_provenance", 0.80),
    RequirementScore("lineage_completeness", 0.75),
    RequirementScore("record_level_traceability", 0.70),
    RequirementScore("classification", 0.90),
    RequirementScore("column_masking", 1.0),
    RequirementScore("access_audit_coverage", 0.95),
    RequirementScore("retention_policy", 0.80),
]


CLEAN_SNOWFLAKE = SnowflakeScenario(
    name="clean_snowflake",
    database=_build_database(),
    requirement_scores=CLEAN_SCORES,
)

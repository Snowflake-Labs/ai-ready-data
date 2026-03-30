"""Degraded RAG scenario — several RAG-critical requirements fail.

Simulates a Snowflake schema that has clean base data but is missing
the consumable and contextual features that RAG pipelines depend on:
no embeddings, no vector indexes, no search optimization, sparse comments.
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
        name="KNOWLEDGE_BASE",
        schemas=[
            MockSchema(
                name="DOCUMENTS",
                tables=[
                    MockTable(
                        name="ARTICLES",
                        row_count=200_000,
                        comment="Knowledge base articles",
                        has_change_tracking=False,
                        columns=[
                            MockColumn(name="ARTICLE_ID", data_type="NUMBER", nullable=False),
                            MockColumn(name="TITLE", data_type="VARCHAR", nullable=False),
                            MockColumn(name="BODY", data_type="VARCHAR", nullable=True),
                            MockColumn(name="AUTHOR_ID", data_type="NUMBER", nullable=True),
                            MockColumn(name="CREATED_AT", data_type="TIMESTAMP_NTZ", nullable=False),
                            MockColumn(name="UPDATED_AT", data_type="TIMESTAMP_NTZ", nullable=True),
                        ],
                    ),
                    MockTable(
                        name="CHUNKS",
                        row_count=800_000,
                        columns=[
                            MockColumn(name="CHUNK_ID", data_type="NUMBER", nullable=False),
                            MockColumn(name="ARTICLE_ID", data_type="NUMBER", nullable=False),
                            MockColumn(name="CHUNK_TEXT", data_type="VARCHAR", nullable=False),
                            MockColumn(name="CHUNK_INDEX", data_type="NUMBER", nullable=False),
                            # No embedding column — the gap
                        ],
                    ),
                    MockTable(
                        name="FEEDBACK",
                        row_count=50_000,
                        columns=[
                            MockColumn(name="FEEDBACK_ID", data_type="NUMBER", nullable=False),
                            MockColumn(name="ARTICLE_ID", data_type="NUMBER", nullable=True),
                            MockColumn(name="RATING", data_type="NUMBER", nullable=True),
                            MockColumn(name="COMMENT", data_type="VARCHAR", nullable=True),
                        ],
                    ),
                ],
            ),
        ],
    )


DEGRADED_RAG_SCORES = [
    # Clean — mostly fine
    RequirementScore("data_completeness", 0.97, "ARTICLES", "BODY"),
    RequirementScore("data_completeness", 0.85, "FEEDBACK", "RATING"),
    RequirementScore("uniqueness", 0.99),
    RequirementScore("schema_conformity", 1.0),
    RequirementScore("syntactic_validity", 1.0),
    RequirementScore("encoding_validity", 1.0),

    # Contextual — sparse documentation
    RequirementScore("semantic_documentation", 0.30),  # FAIL: most columns have no comments
    RequirementScore("schema_type_coverage", 0.60),    # FAIL: weak typing
    RequirementScore("entity_identifier_declaration", 0.50),
    RequirementScore("temporal_scope_declaration", 0.40),

    # Consumable — the big gaps
    RequirementScore("chunk_readiness", 0.80),
    RequirementScore("embedding_coverage", 0.0),       # FAIL: no embeddings at all
    RequirementScore("embedding_dimension_consistency", 0.0),
    RequirementScore("vector_index_coverage", 0.0),    # FAIL: no vector indexes
    RequirementScore("retrieval_recall_compliance", 0.0),
    RequirementScore("search_optimization", 0.10),     # FAIL: no clustering
    RequirementScore("eval_coverage", 0.0),

    # Current — no change tracking
    RequirementScore("change_detection", 0.0),         # FAIL: no streams
    RequirementScore("data_freshness", 0.70),
    RequirementScore("incremental_update_coverage", 0.0),

    # Correlated — minimal
    RequirementScore("data_provenance", 0.20),
    RequirementScore("lineage_completeness", 0.10),
    RequirementScore("record_level_traceability", 0.0),
    RequirementScore("agent_attribution", 0.0),

    # Compliant — basic
    RequirementScore("classification", 0.30),
    RequirementScore("column_masking", 1.0),
    RequirementScore("access_audit_coverage", 0.50),
    RequirementScore("retention_policy", 0.0),
    RequirementScore("purpose_limitation", 0.0),
]


DEGRADED_RAG = SnowflakeScenario(
    name="degraded_rag",
    database=_build_database(),
    requirement_scores=DEGRADED_RAG_SCORES,
)

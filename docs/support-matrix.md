# Support Matrix

- Total requirements: 61

## Coverage by Platform

| Platform | Implemented Requirements |
|---|---:|
| aws | 0 |
| azure | 0 |
| databricks | 3 |
| snowflake | 61 |

## Requirement Coverage

| Requirement | Factor | Workload | Implementations |
|---|---|---|---|
| access_audit_coverage | compliant | rag, feature-serving, training, agents | snowflake |
| access_optimization | consumable | feature-serving, training, agents | snowflake |
| agent_attribution | correlated | rag, feature-serving, training, agents | snowflake |
| anonymization_effectiveness | compliant | training | snowflake |
| batch_throughput_sufficiency | consumable | training | snowflake |
| bias_testing_coverage | compliant | training | snowflake |
| business_glossary_linkage | contextual | training, agents | snowflake |
| categorical_validity | clean | feature-serving, training, agents | snowflake |
| change_detection | current | rag, feature-serving, training, agents | snowflake |
| chunk_readiness | consumable | rag | snowflake |
| classification | compliant | rag, feature-serving, training, agents | databricks, snowflake |
| column_masking | compliant | rag, feature-serving, training, agents | snowflake |
| consent_coverage | compliant | feature-serving, training, agents | snowflake |
| constraint_declaration | contextual | feature-serving, training, agents | snowflake |
| cross_column_consistency | clean | feature-serving, training | snowflake |
| data_completeness | clean | rag, feature-serving, training, agents | snowflake |
| data_freshness | current | rag, feature-serving, agents | snowflake |
| data_provenance | correlated | rag, feature-serving, training, agents | snowflake |
| data_version_coverage | correlated | training | snowflake |
| demographic_representation | compliant | training | snowflake |
| dependency_graph_completeness | correlated | training | snowflake |
| distribution_conformity | clean | training | snowflake |
| embedding_coverage | consumable | rag | snowflake |
| embedding_dimension_consistency | consumable | rag | snowflake |
| encoding_validity | clean | rag, feature-serving, training, agents | snowflake |
| entity_identifier_declaration | contextual | rag, feature-serving, training, agents | snowflake |
| feature_materialization_coverage | consumable | feature-serving, training | snowflake |
| feature_refresh_compliance | current | feature-serving | snowflake |
| impact_analysis_capability | correlated | training | snowflake |
| incremental_update_coverage | current | rag, feature-serving, training, agents | snowflake |
| license_compliance | compliant | training | snowflake |
| lineage_completeness | correlated | rag, feature-serving, training, agents | databricks, snowflake |
| native_format_availability | consumable | feature-serving, training, agents | snowflake |
| outlier_prevalence | clean | training | snowflake |
| pipeline_execution_audit | correlated | feature-serving, training, agents | snowflake |
| point_in_time_correctness | current | training | snowflake |
| point_lookup_availability | consumable | feature-serving, agents | snowflake |
| propagation_latency_compliance | current | feature-serving, agents | snowflake |
| purpose_limitation | compliant | rag, feature-serving, training, agents | snowflake |
| record_level_traceability | correlated | rag, feature-serving, training, agents | snowflake |
| referential_accuracy | clean | training | snowflake |
| referential_integrity | clean | feature-serving, training, agents | snowflake |
| relationship_declaration | contextual | feature-serving, training, agents | snowflake |
| retention_policy | compliant | rag, feature-serving, training, agents | snowflake |
| retrieval_recall_compliance | consumable | rag | snowflake |
| row_access_policy | compliant | feature-serving, training, agents | snowflake |
| schema_conformity | clean | rag, feature-serving, training, agents | snowflake |
| schema_evolution_tracking | current | training | snowflake |
| schema_type_coverage | contextual | rag, feature-serving, training, agents | snowflake |
| search_optimization | consumable | rag, agents | snowflake |
| semantic_documentation | contextual | rag, feature-serving, training, agents | databricks, snowflake |
| serving_latency_compliance | consumable | feature-serving, agents | snowflake |
| syntactic_validity | clean | rag, feature-serving, training, agents | snowflake |
| temporal_referential_integrity | current | training | snowflake |
| temporal_scope_declaration | contextual | rag, feature-serving, training, agents | snowflake |
| training_serving_parity | current | feature-serving, training | snowflake |
| transformation_documentation | correlated | training | snowflake |
| uniqueness | clean | rag, feature-serving, training, agents | snowflake |
| unit_of_measure_declaration | contextual | feature-serving, training, agents | snowflake |
| value_range_validity | clean | feature-serving, training, agents | snowflake |
| vector_index_coverage | consumable | rag | snowflake |

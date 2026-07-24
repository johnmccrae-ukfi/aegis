# Aegis Delivery Plan

## Phase 1 — Repository and architecture foundation

- Create GitHub repository.
- Establish `main` and `dev` branches.
- Create project folder structure.
- Define project scope and architecture.
- Establish data-governance rules.
- Create SQL Server environment design.
- Create the first database project.

## Phase 2 — Synthetic source data

- Review available source structures locally.
- Define synthetic data specification.
- Generate patient, encounter and clinical datasets.
- Generate HL7 v2 messages.
- Generate FHIR JSON resources.
- Create deliberate data-quality defects for testing.

## Phase 3 — Source, staging and audit databases

- Build `Aegis_Source`.
- Build `Aegis_Staging`.
- Build `Aegis_Audit`.
- Create batch-control framework.
- Create raw ingestion tables.
- Create validation and quarantine structures.

## Phase 4 — SSIS data integration

- Build HL7 ingestion package.
- Build FHIR ingestion package.
- Build legacy PAS ingestion package.
- Implement validation and error routing.
- Implement dimension and fact loading.
- Implement orchestration and restartability.
- Deploy to SSISDB.

## Phase 5 — Reporting warehouse

- Build dimensional warehouse.
- Create conformed dimensions.
- Create encounter, admission, observation and migration facts.
- Create reporting views.
- Implement indexing and performance tuning.

## Phase 6 — SSAS and SSRS

- Create SSAS Tabular model.
- Add relationships, hierarchies and measures.
- Create migration reconciliation report.
- Create data-quality exception report.
- Create patient journey report.
- Create daily operational readiness report.
- Add optional Power BI executive summary.

## Phase 7 — High availability and disaster recovery

- Configure transactional replication.
- Validate reporting-subscriber latency.
- Configure log shipping.
- Perform DR recovery exercise.
- Create monitoring queries and runbooks.

## Phase 8 — Azure demonstration target

- Assess database compatibility.
- Deploy selected databases to Azure SQL.
- Configure demonstration access.
- Validate remote reporting or query access.
- Document differences between SQL Server and Azure SQL.

## Phase 9 — Release and interview preparation

- Complete README and architecture diagrams.
- Capture implementation screenshots.
- Complete technical documentation.
- Create release notes.
- Tag first release.
- Prepare five-minute interview demonstration.
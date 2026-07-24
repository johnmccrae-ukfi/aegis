# Aegis Project Scope

## Purpose

Aegis is a synthetic clinical data platform designed to demonstrate an end-to-end NHS-style PAS and EPR migration, reporting and operational assurance solution.

The platform will combine established Microsoft SQL Server technologies with modern source control, database development and deployment practices.

## Business scenario

A fictional NHS trust is replacing a legacy Patient Administration System and Electronic Patient Record platform.

Clinical and operational data must be:

1. Extracted from multiple legacy formats.
2. Profiled and validated.
3. Cleansed and transformed.
4. Mapped to a governed target model.
5. Reconciled between source and target.
6. Made available for operational and analytical reporting.
7. Protected through reporting replicas and disaster-recovery controls.

## In scope

### Data sources

- HL7 v2 ADT messages
- Optional HL7 ORU messages
- FHIR JSON resources
- Legacy PAS relational extracts
- Legacy EPR and clinical-trial-style datasets
- NHS-style reference data

### Data domains

- Patient demographics
- Encounters
- Admissions
- Discharges
- Transfers
- Outpatient attendances
- Emergency attendances
- Diagnoses
- Procedures
- Observations
- Laboratory results
- Medications
- Organisations and clinical locations

### Platform components

- SQL Server source simulation
- SQL Server staging layer
- SQL Server audit and control framework
- Dimensional reporting warehouse
- SSIS ETL pipelines
- SSAS semantic model
- SSRS operational reports
- Optional Power BI reporting
- Transactional replication
- Log shipping
- Azure SQL demonstration deployment
- GitHub source control and database projects

## Out of scope for the first release

- Real patient-identifiable data
- Production NHS system connectivity
- Full FHIR server implementation
- Full HL7 interface engine
- Real clinical decision support
- Production-grade identity matching
- Live Nervecentre or Dedalus iPM integration
- Enterprise-scale data volumes
- Production security accreditation

## Primary deliverables

- Synthetic clinical datasets
- Source-to-target mapping specification
- SQL database projects
- SSIS ingestion and transformation solution
- Data-quality and reconciliation framework
- Dimensional warehouse
- SSAS semantic model
- SSRS operational reporting suite
- Replication demonstration
- Log-shipping and DR runbook
- Azure SQL cloud demonstration target
- Architecture and operational documentation

## Success criteria

The first release will be considered successful when:

- Synthetic HL7, FHIR and PAS data can be ingested.
- Valid records reach the reporting warehouse.
- Invalid records are quarantined with clear reasons.
- Source and target record counts can be reconciled.
- SSRS reports expose migration and data-quality status.
- SSAS provides governed analytical measures.
- Transactional replication can be demonstrated.
- Log shipping can be demonstrated and documented.
- Database projects can deploy through a repeatable process.
- The solution can be explained in a concise interview demonstration.
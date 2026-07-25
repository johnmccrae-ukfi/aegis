# Aegis Master Context

## Project identity

**Name:** Aegis Clinical Data Platform  
**Repository:** Aegis  
**Purpose:** Synthetic NHS-style clinical data migration, reporting and operational assurance platform.

## Strategic purpose

Aegis is a portfolio project designed to demonstrate practical delivery across the traditional Microsoft SQL Server platform while applying modern engineering and DevOps practices.

It complements Atlas:

- **Atlas:** Microsoft Fabric, cloud data engineering, real-time analytics and AI.
- **Aegis:** SQL Server, SSIS, SSAS, SSRS, healthcare migration, reporting and operational resilience.

## Core scenario

A fictional NHS trust is migrating from legacy PAS and EPR platforms into a replacement clinical system and reporting warehouse.

The project will process:

- HL7 v2 messages
- FHIR JSON resources
- Legacy PAS extracts
- Legacy EPR and clinical datasets

## Core technologies

- SQL Server
- T-SQL
- SSIS
- SSAS Tabular
- SSRS
- Power BI
- SQL Server Database DevOps projects
- Visual Studio and SSDT
- GitHub
- PowerShell
- Python
- Azure SQL Database

## Planned databases

- `Aegis_Source`
- `Aegis_Staging`
- `Aegis_Audit`
- `Aegis_Warehouse`
- `Aegis_Reporting`
- `Aegis_Source_ReportingReplica`
- `Aegis_Warehouse_DR`

## Git workflow

```text
dev
  ↓
Pull request
  ↓
main
  ↓
Release tag
```

Feature branches may be used for larger isolated changes.

## Data-governance rule

Only fully synthetic data may be committed to the public GitHub repository.

Pseudonymised or real-derived source data must remain outside source control and may only be used locally as a structural reference for generating new synthetic data.

## Current status

- Repository created.
- `main` and `dev` branches created.
- Initial folder structure created.
- Initial governance and architecture documentation in progress.

## Immediate next steps

1. Commit this updated environment architecture.
2. Create the first SQL database project.
3. Create the `Aegis_Source` database schema.
4. Deploy the database project to the local default instance.
5. Define the synthetic legacy PAS source model.
6. Confirm source-data domains and initial table grain.
7. Add deployment validation scripts.

## Working conventions

- Use clear numbered SQL deployment scripts where standalone scripts are required.
- Prefer database projects for schema objects.
- Keep credentials and environment-specific values outside Git.
- Use repeatable test data and explicit reconciliation controls.
- Document architectural decisions that affect portability, security or operations.
- Capture diagrams and screenshots in `images`.

## Day 1 completion summary

Day 1 established the Aegis development platform, repository workflow and initial PAS source model.

### Platform and tooling completed

- GitHub repository `Aegis` created.
- Branches `main` and `dev` established.
- Repository and documentation structure created.
- SQL Server 2022 Developer Edition configured.
- SQL Server Agent configured.
- SQL Server Replication feature installed.
- SQL Server Integration Services installed and running.
- `SSISDB` configured with an `Aegis` folder.
- SQL Server Analysis Services installed in Tabular mode.
- SQL Server Reporting Services installed and configured.
- SSRS web service available through `/ReportServer`.
- SSRS web portal available through `/Reports`.
- Visual Studio 2022 BI extensions installed for SSIS, SSAS and SSRS.
- SSMS 22 Database DevOps project workflow validated.
- Local SQL Server connected to Azure through the Azure Extension.
- Azure resource group `rg-aegis-dev` created.

### Database DevOps workflow established

```text
SQL project source
        ↓
Build
        ↓
DACPAC
        ↓
Publish
        ↓
Database validation
        ↓
Git commit and push
```

The SQL database solution is:

```text
src/database/Aegis.Database.slnx
```

The source database project is:

```text
src/database/Aegis.Source/Aegis.Source.sqlproj
```

The project targets SQL Server 2022 and publishes to:

```text
DESKTOP-N58JDOH
└── Aegis_Source
```

### Source schemas implemented

- `pas`
- `epr`
- `ref`

### PAS tables implemented

- `pas.Patient`
- `pas.Admission`
- `pas.ConsultantEpisode`
- `pas.Diagnosis`
- `pas.Procedure`
- `pas.WardStay`

### Reference tables implemented

- `ref.Organisation`
- `ref.Site`
- `ref.Specialty`
- `ref.Consultant`
- `ref.Ward`

### Validation status

The deployment validation script is:

```text
sql/tests/validate_aegis_source_foundation.sql
```

It currently performs 33 checks covering:

- Schemas
- Source tables
- Key columns
- Reference tables
- PAS relationships
- Reference-data relationships

All 33 checks pass.

## Refined migration programme context

Aegis now explicitly models more than a historical PAS table migration.

The project will represent four connected migration workstreams:

```text
1. Historical data migration
2. Live interface transition
3. Reporting and statutory continuity
4. Cutover and post-go-live assurance
```

The fictional scenario is based on an NHS organisation replacing a legacy PAS and EPR landscape with a modern integrated EPR/PAS platform.

The design must account for:

- Patient and encounter migration
- Live ADT interfaces
- Patient identity merges
- Downstream clinical-system dependencies
- Data warehouse extracts
- SSRS and Power BI reporting
- HES, SUS and RTT reporting continuity
- Regional data consumers
- Parallel reconciliation
- Cutover readiness
- Post-go-live assurance

## Migration operating phases

Aegis will describe three operating phases.

### Phase 1 — Legacy operation

- The legacy PAS is the administrative system of record.
- Downstream systems consume legacy ADT and warehouse feeds.
- Existing reporting and statutory submissions depend on the legacy model.

### Phase 2 — Coexistence

- The legacy PAS remains the administrative master.
- The replacement EPR/PAS receives migrated history and live interface updates.
- Source and target data are reconciled in parallel.
- Downstream interfaces and reports are tested against the replacement source.

### Phase 3 — Cutover

- The replacement EPR/PAS becomes the administrative master.
- Interfaces and warehouse extracts switch to the new source.
- The legacy PAS becomes read-only or archived.
- Post-go-live validation confirms reporting and operational continuity.

## Expanded patient identity scope

Patient identity and merge history will be treated as first-class migration domains.

Planned source tables:

```text
pas.PatientIdentifier
pas.PatientMerge
```

### `pas.PatientIdentifier`

Planned grain:

One row per patient identifier assigned to a patient.

Planned concepts:

- Patient
- Identifier value
- Identifier type
- Assigning authority
- Effective dates
- Current-status flag

### `pas.PatientMerge`

Planned grain:

One row per recorded patient-identity merge.

Planned concepts:

- Surviving patient
- Superseded patient
- Surviving identifier
- Superseded identifier
- Merge date and time
- Merge reason
- Source message control identifier
- Audit timestamps

The migration process must preserve merge lineage and prevent duplicate counting of superseded patient records.

## Expanded HL7 scope

The initial HL7 implementation will include:

- `ADT^A01` — admit
- `ADT^A02` — transfer
- `ADT^A03` — discharge
- `ADT^A08` — patient-information update
- `ADT^A40` — patient-identifier merge

A later representative clinical-result interface may include:

- `ORU^R01` — observation or laboratory result

The HL7 implementation will remain a focused simulation rather than a complete interface-engine replacement.

## Interface and downstream dependency scope

Aegis will maintain an interface inventory describing representative dependencies.

Planned interfaces include:

| Interface | Source | Consumer | Format | Scope |
|---|---|---|---|---|
| Patient ADT | PAS | EPR | HL7 v2 | A01, A02, A03, A08, A40 |
| Laboratory orders | EPR | LIMS | HL7 ORM | Orders |
| Laboratory results | LIMS | EPR | HL7 ORU | Results |
| Imaging orders | EPR | RIS | HL7 ORM | Orders |
| Imaging results | RIS/PACS | EPR | HL7 ORU | Reports |
| Warehouse extract | PAS/EPR | Data warehouse | Relational/SSIS | Patient and activity |
| APC extract | Warehouse | Statutory reporting | Delimited file | Admitted patient episodes |
| Regional feed | Warehouse/EPR | Regional platform | Extract or API | Governed patient activity |

Aegis will not implement complete LIMS, RIS, PACS, pharmacy or interface-engine products.

Their boundaries will be represented through:

- Synthetic files
- SQL tables
- Interface metadata
- Audit records
- Reconciliation controls

## Regional downstream consumers

Regional consumers will be described broadly as:

```text
Regional data consumers
├── Shared care record and direct-care services
├── Population-health intelligence platform
└── Secure data environment and approved research
```

Aegis will avoid asserting unsupported details about specific local products or implementations.

## Planned interface audit model

The future `Aegis_Audit` database will include an interface-message audit structure.

Planned concepts include:

```text
audit.InterfaceMessage
├── InterfaceMessageId
├── InterfaceCode
├── MessageControlId
├── MessageType
├── TriggerEvent
├── SourceSystemCode
├── TargetSystemCode
├── ReceivedAt
├── ProcessedAt
├── ProcessingStatus
├── RetryCount
├── ErrorCode
└── ErrorDetail
```

This will support operational reporting for:

- Messages received
- Messages processed
- Messages rejected
- Messages awaiting replay
- Duplicate message-control identifiers
- Processing latency
- Trigger-event volumes
- Cutover readiness

## Expanded reconciliation scope

Reconciliation will compare:

```text
Legacy PAS source
        ↓
Migration staging and target
        ↓
Warehouse and reporting outputs
```

Planned controls include:

- Patient counts before and after merges
- Current and historic patient identifiers
- Open admissions
- Consultant episodes per spell
- Diagnosis counts
- Procedure counts
- Ward locations
- Daily admissions and discharges
- Statutory extract totals
- Source-to-target attribute comparisons
- Interface-message totals
- Processing failures
- Report totals before and after source transition

## Revised delivery plan

### Day 1 — Platform and PAS source foundation

Status: complete.

Delivered:

- Repository foundation
- SQL Server BI platform
- SQL database project
- PAS source model
- Reference-data model
- Build and publish workflow
- 33 deployment checks

### Day 2 — Synthetic PAS data and patient identity

Planned:

- Add `pas.PatientIdentifier`
- Add `pas.PatientMerge`
- Extend deployment validation
- Create interface inventory
- Define synthetic-data rules
- Generate reference data
- Generate valid synthetic patient journeys
- Generate deliberate source defects
- Validate source-data counts and relationships

### Day 3 — Staging, audit and SSIS

Planned:

- Create `Aegis_Staging`
- Create `Aegis_Audit`
- Build SSIS audit framework
- Load relational PAS extracts
- Parse representative ADT messages
- Route failures to quarantine
- Add interface audit and replay concepts

### Day 4 — Warehouse and reconciliation

Planned:

- Create `Aegis_Warehouse`
- Build conformed dimensions and facts
- Reconcile source, staging and warehouse
- Produce an APC-style episode extract
- Add batch and interface monitoring views

### Day 5 — SSAS and SSRS

Planned:

- Build SSAS Tabular model
- Migration Reconciliation Report
- Data Quality Exception Report
- Interface and Cutover Readiness Report
- Patient Journey Report
- Optional Power BI management summary

### Day 6 — SQL Server resilience

Planned:

- Transactional replication
- Log shipping
- Monitoring scripts
- Recovery exercise
- Operational runbooks

### Day 7 — Cloud demonstration and release

Planned if time permits:

- Azure SQL compatibility assessment
- Azure SQL demonstration target
- README diagrams
- Screenshots
- Release documentation
- Interview demonstration
- Interview questions and model answers

## Day 2 immediate next steps

1. Create `pas.PatientIdentifier`.
2. Create `pas.PatientMerge`.
3. Build and publish `Aegis.Source`.
4. Extend the validation suite.
5. Create `docs/04_ETL/Interface_Inventory.md`.
6. Define synthetic-data generation and safety rules.
7. Create the Aegis Python virtual environment.
8. Generate initial reference and patient data.
9. Generate representative valid patient journeys.
10. Add controlled invalid and duplicate records.
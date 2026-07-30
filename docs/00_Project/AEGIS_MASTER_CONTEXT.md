# Aegis Master Context

## Project identity

**Name:** Aegis Clinical Data Platform  
**Repository:** Aegis  
**Purpose:** Synthetic NHS-style clinical data migration, validation, semantic-modelling, reporting and operational-assurance platform.  
**Current branch:** `dev`  
**Current delivery position:** Day 5 complete; the audited Admissions migration pipeline, deployed SSAS Tabular semantic model and deployed SSRS operational report form a complete end-to-end Admissions demonstration.

---

## Strategic purpose

Aegis is a portfolio project designed to demonstrate practical delivery across the traditional Microsoft SQL Server business-intelligence platform while applying modern software-engineering, data-governance and DevOps practices.

It complements Atlas:

- **Atlas:** Microsoft Fabric, cloud data engineering, real-time analytics, semantic modelling and AI.
- **Aegis:** SQL Server, SSIS, SSAS Tabular, SSRS, healthcare migration, reporting, data quality, governance, database resilience and operational assurance.

Aegis demonstrates that the same disciplined engineering principles can be applied across both modern cloud platforms and established enterprise SQL Server estates.

The project is also intended to show the continuity between:

```text
SSAS Tabular
        ↓
Power BI and Fabric semantic models
```

and:

```text
SSRS paginated reporting
        ↓
Power BI paginated reporting
```

The underlying concepts remain transferable:

- dimensional modelling;
- tabular relationships;
- DAX measures;
- active and inactive relationships;
- semantic metadata;
- governed reporting;
- parameter-driven operational reports;
- lineage and reconciliation.

---

## Core scenario

A fictional NHS organisation is migrating from legacy Patient Administration System and Electronic Patient Record platforms into a replacement integrated EPR/PAS and reporting environment.

The programme must support:

1. Historical data migration
2. Live interface transition
3. Reporting and statutory continuity
4. Cutover and post-go-live assurance

The project will process representative:

- legacy PAS relational extracts;
- legacy EPR and clinical datasets;
- HL7 v2 messages;
- FHIR JSON resources;
- reference-data extracts;
- admitted-patient activity;
- patient-identity and merge history;
- controlled invalid source records.

Aegis is a focused migration and assurance simulation. It is not intended to reproduce a complete NHS PAS, EPR, interface engine or statutory-submission service.

The current interview-focused implementation deliberately concentrates on taking **Admissions** through a polished end-to-end flow:

```text
Synthetic legacy PAS
        ↓
Audited SSIS ingestion
        ↓
Landing and staging
        ↓
Validation and classification
        ↓
Accepted or quarantined
        ↓
Reporting view
        ↓
SSAS Tabular semantic model
        ↓
SSRS reporting
```

---

## Core technologies

- SQL Server 2022 Developer Edition
- T-SQL
- DAX
- SQL Server Database DevOps projects
- DACPAC build and publish
- SQL Server Integration Services
- SQL Server Analysis Services Tabular
- SQL Server Reporting Services
- Power BI
- SQL Server Agent
- SQL Server transactional replication
- SQL Server log shipping
- SQL Server Management Studio
- Visual Studio 2022 and SSDT
- Visual Studio Code
- Git and GitHub
- Python
- PowerShell
- Azure SQL Database
- Microsoft Purview concepts for later governance expansion

---

## Implemented databases and services

### Relational databases

```text
Aegis_Source
Aegis_Staging
Aegis_Audit
```

### Analysis Services database

```text
Aegis_Admissions_Analysis
```

### Deferred databases

```text
Aegis_Warehouse
Aegis_Reporting
Aegis_Source_ReportingReplica
Aegis_Warehouse_DR
```

### Current database and service status

| Database or service | Purpose | Status |
|---|---|---|
| `Aegis_Source` | Synthetic legacy PAS source and reference data | Implemented and populated |
| `Aegis_Staging` | Landing, staging, curated, quarantine and reporting layers | Implemented, published and populated |
| `Aegis_Audit` | Batch, package, row-outcome and data-quality audit | Implemented, published and populated |
| `Aegis_Admissions_Analysis` | SSAS Tabular Admissions semantic model | Implemented, deployed and validated |
| `Admissions Activity and Trends` | SSRS operational Admissions report | Implemented, deployed and validated |
| `Aegis_Warehouse` | Broader analytical warehouse | Deferred |
| `Aegis_Reporting` | Potential future relational reporting database | Deferred |
| `Aegis_Source_ReportingReplica` | Transactional-replication reporting target | Deferred |
| `Aegis_Warehouse_DR` | Log-shipping recovery target | Deferred |

The focused Admissions scenario currently uses:

```text
Aegis_Staging.reporting.AdmissionAnalysis
        ↓
Aegis_Admissions_Analysis
```

A separate relational `Aegis_Reporting` database is not required for the current SSAS and SSRS demonstration.

---

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

### Active branch

```text
dev
```

### Released versions

```text
v0.1.0 — Platform and SQL database foundation
v0.2.0 — Deterministic synthetic PAS data and patient identity
v0.3.0 — Audited SSIS Admissions pipeline
v0.4.0 — SSAS Admissions analytical model
```

Day 5 SSRS changes are complete on `dev` and are ready for release as `v0.5.0`.

---

## Tool responsibilities

Use **SSMS Database DevOps** for:

- SQL database projects;
- schema-object authoring;
- database-project build;
- DACPAC creation;
- DACPAC publication;
- SQL parser and deployment validation.

Use **Visual Studio 2022** for:

- SSIS package development;
- SSAS Tabular development;
- SSRS report development;
- Analysis Services build and deployment;
- Reporting Services build and deployment.

Use **VS Code** for:

- Git operations;
- Markdown documentation;
- Python;
- PowerShell;
- repository-wide review;
- generated-file inspection;
- general development work.

Standalone SQL validation and reconciliation scripts may be created and executed in SSMS, provided they are saved within the repository under:

```text
sql/
```

Standalone deployed-model DAX validation scripts may be retained with the SSAS solution under:

```text
src/ssas/Aegis.Analysis/validation/
```

---

## Database DevOps workflow

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

The implemented database projects are:

```text
src/database/Aegis.Source/Aegis.Source.sqlproj
src/database/Aegis.Staging/Aegis.Staging.sqlproj
src/database/Aegis.Audit/Aegis.Audit.sqlproj
```

The projects target SQL Server 2022 and publish locally to:

```text
DESKTOP-N58JDOH
├── Aegis_Source
├── Aegis_Staging
└── Aegis_Audit
```

All three database projects currently build and publish successfully.

---

## SSAS development workflow

```text
SSAS Tabular project source
        ↓
Workspace-model processing
        ↓
Project build
        ↓
Deployment to Analysis Services
        ↓
Deployed-model DAX validation
        ↓
Git commit and push
```

The SSAS solution is:

```text
src/ssas/Aegis.Analysis/Aegis.Analysis.sln
```

The SSAS Tabular project is:

```text
src/ssas/Aegis.Analysis/Aegis.Admissions.Analysis
```

The project targets:

```text
SQL Server 2022
Compatibility level 1600
```

The deployed model is:

```text
Server:    DESKTOP-N58JDOH
Database:  Aegis_Admissions_Analysis
Model:     Model
```

The project builds and deploys successfully.

Visual Studio creates a separate temporary workspace database while the model is being authored. This is distinct from the deployed production-style model database.

---

## SSRS development workflow

```text
SSRS project source
        ↓
Project build
        ↓
Deployment to Reporting Services
        ↓
Portal validation
        ↓
Screenshot and documentation
        ↓
Git commit and push
```

The SSRS solution is:

```text
src/ssrs/Aegis.Reporting/Aegis.Reporting.sln
```

The SSRS project is:

```text
src/ssrs/Aegis.Reporting/Aegis.Admissions.Reporting
```

The implemented report is:

```text
Reports/Admissions Activity and Trends.rdl
```

The shared data source is:

```text
Shared Data Sources/DS_Aegis_Admissions_Analysis.rds
```

Deployment target:

```text
http://localhost/reportserver
```

Deployment folder:

```text
Aegis/Admissions
```

The report builds, deploys and renders successfully in the SSRS web portal.

---

## Build-artifact rule

Generated build outputs must not be committed to normal Git history.

Excluded artefacts include:

```text
**/bin/
**/obj/
*.dacpac
.venv/
```

DACPAC files and Analysis Services build outputs are reproducible artefacts.

A future CI/CD workflow may publish them as pipeline or release artefacts, but locally generated outputs do not belong in the repository source tree.

---

## Data-governance rule

Only fully synthetic data may be committed to the public GitHub repository.

The following must never enter public source control:

- real patient data;
- pseudonymised patient data;
- anonymised records derived from real individuals;
- copied production extracts;
- copied production HL7 messages;
- copied production FHIR resources;
- real NHS numbers;
- real staff identifiers;
- production screenshots containing identifiable information;
- passwords, secrets or private connection strings;
- SQL login passwords;
- stored credentials exported from local development tools.

Private structural reference material must remain under:

```text
data/private
```

The directory is excluded through `.gitignore`.

### Synthetic NHS-number rule

Aegis must not generate mathematically valid random NHS numbers that might correspond to real people.

All generated NHS-number-like values:

- use a controlled synthetic pattern;
- contain ten digits for structural testing;
- are independently generated;
- deliberately fail NHS checksum validation;
- are validated before files are written or data is loaded.

### Synthetic-data documentation

The authoritative synthetic-data governance document is:

```text
docs/10_Governance/Synthetic_Data_Generation_and_Safety_Rules.md
```

---

## Working conventions

- Proceed step by step.
- Pause after each significant build, publish, generation, load, deployment or validation operation.
- Wait for the observed result before continuing.
- Provide complete file contents when creating or replacing scripts and Markdown documents.
- Put a whole Markdown document inside one outer four-backtick block when it contains inner fenced blocks.
- Use deterministic synthetic generation with explicit random seeds.
- Validate generated records before writing files.
- Validate generated files before database loading.
- Use explicit `--load` switches for Python database loaders.
- Use one SQL transaction for each controlled load stage.
- Roll back the complete transaction on failure.
- Preserve deterministic identity values using `IDENTITY_INSERT` where appropriate.
- Keep credentials and environment-specific values outside Git.
- Use repeatable test data and explicit reconciliation controls.
- Document architectural decisions affecting portability, security or operations.
- Capture diagrams and screenshots under technology-specific folders within `images`.
- Keep generated `bin`, `obj`, DACPAC and virtual-environment artefacts outside Git.
- Prefer polished, explainable end-to-end delivery over unnecessary breadth.
- Keep the current interview-focused implementation limited to Admissions until SSRS is complete.

---

# Current repository structure

The repository includes the following principal areas:

```text
aegis/
├── data/
│   ├── generated/
│   ├── generators/
│   └── private/
├── docs/
│   ├── 00_Project/
│   ├── 01_Architecture/
│   ├── 02_Data_Contracts/
│   ├── 03_Data_Model/
│   ├── 04_ETL/
│   ├── 05_Migration/
│   ├── 06_Reporting/
│   ├── 07_HA_DR/
│   ├── 08_Testing/
│   ├── 09_Operations/
│   └── 10_Governance/
├── images/
│   ├── architecture/
│   ├── database/
│   ├── log_shipping/
│   ├── replication/
│   ├── ssas/
│   ├── ssis/
│   └── ssrs/
├── sql/
│   ├── administration/
│   ├── deployment/
│   ├── monitoring/
│   └── tests/
├── src/
│   ├── database/
│   ├── ssas/
│   │   └── Aegis.Analysis/
│   │       ├── Aegis.Admissions.Analysis/
│   │       └── validation/
│   ├── ssis/
│   ├── ssrs/
│   │   └── Aegis.Reporting/
│   └── synthetic_data/
├── .gitignore
└── requirements.txt
```

Generated data under `data/generated` is currently excluded from Git while the generators and schemas remain under development.

Reviewed deterministic synthetic samples may later be copied into an explicitly governed public sample-data location.

---

# Environment and platform status

## SQL Server platform

The local development platform contains:

- SQL Server 2022 Developer Edition
- SQL Server Agent
- SQL Server Replication feature
- SQL Server Integration Services
- SSIS Catalog database `SSISDB`
- SSIS Catalog folder `Aegis`
- SQL Server Analysis Services in Tabular mode
- SQL Server Reporting Services
- SSRS web service
- SSRS web portal

SSRS endpoints are available through:

```text
/ReportServer
/Reports
```

The Analysis Services default instance is:

```text
DESKTOP-N58JDOH
```

The Analysis Services service:

- uses the default `MSSQLSERVER` instance;
- is configured for Tabular mode;
- is running;
- starts automatically.

Visual Studio 2022 contains the required BI extensions for:

- SSIS;
- SSAS;
- SSRS.

Installed Analysis Services project extension:

```text
Microsoft Analysis Services Projects 4.0.0
```

The local SQL Server has also been connected to Azure through the SQL Server Azure Extension.

The Azure resource group is:

```text
rg-aegis-dev
```

---

# Migration programme context

## Migration workstreams

Aegis models four connected migration workstreams:

```text
1. Historical data migration
2. Live interface transition
3. Reporting and statutory continuity
4. Cutover and post-go-live assurance
```

The design accounts for:

- patient and encounter migration;
- live ADT interfaces;
- patient identity and merges;
- downstream clinical-system dependencies;
- warehouse extracts;
- SSRS and Power BI reporting;
- HES-, SUS- and RTT-style reporting continuity;
- regional data consumers;
- parallel reconciliation;
- cutover readiness;
- post-go-live assurance.

Aegis avoids unsupported claims about the exact private products or implementation details used by real NHS organisations.

---

## Migration operating phases

### Phase 1 — Legacy operation

- The legacy PAS is the administrative system of record.
- Downstream systems consume legacy ADT and warehouse feeds.
- Existing reporting and statutory processes depend on the legacy model.
- Aegis receives relational extracts and messages for profiling and migration preparation.

### Phase 2 — Coexistence

- The legacy PAS remains the administrative master.
- The replacement EPR/PAS receives migrated history and live interface updates.
- Source and target data are reconciled in parallel.
- Downstream interfaces and reports are tested against the replacement source.
- Failures are audited, quarantined and replayed where appropriate.

### Phase 3 — Cutover

- The replacement EPR/PAS becomes the administrative master.
- Interfaces and warehouse extracts switch to the new source.
- The legacy PAS becomes read-only or archived.
- Interface volumes, reporting outputs and patient counts are monitored.
- Post-go-live validation confirms operational and reporting continuity.

---

# Interface and dependency scope

The interface inventory is documented in:

```text
docs/04_ETL/Interface_Inventory.md
```

Representative interfaces include:

| Interface | Source | Consumer | Format | Scope |
|---|---|---|---|---|
| Patient ADT | PAS | EPR | HL7 v2 | A01, A02, A03, A08, A40 |
| Laboratory orders | EPR | LIMS | HL7 ORM | Orders |
| Laboratory results | LIMS | EPR | HL7 ORU | Results |
| Imaging orders | EPR | RIS | HL7 ORM | Orders |
| Imaging results | RIS/PACS | EPR | HL7 ORU | Reports |
| PAS relational extract | PAS | Aegis staging | SQL or CSV | Patient identity and activity |
| Warehouse extract | PAS/EPR | Warehouse | SQL Server and SSIS | Patient and clinical activity |
| APC-style extract | Warehouse | Statutory consumer | Delimited file | Admitted-patient episodes |
| Regional feed | Warehouse/EPR | Regional consumer | Extract or API | Governed patient activity |
| Reconciliation results | Staging/reporting | Audit | SQL Server | Batch and attribute controls |
| Semantic reporting | SSAS | SSRS | Tabular model | Admissions activity and assurance |

Aegis will not implement complete:

- LIMS;
- RIS;
- PACS;
- pharmacy systems;
- production interface-engine products;
- national statutory-submission services;
- regional shared-care platforms.

Their boundaries will be represented through:

- synthetic files;
- SQL tables;
- interface metadata;
- audit records;
- reconciliation controls.

---

## HL7 scope

The initial HL7 implementation may later include:

- `ADT^A01` — admit;
- `ADT^A02` — transfer;
- `ADT^A03` — discharge;
- `ADT^A08` — patient-information update;
- `ADT^A40` — patient-identifier merge.

A later representative clinical-result interface may include:

- `ORU^R01` — observation or laboratory result.

The future implementation may demonstrate:

- receipt;
- parsing;
- validation;
- audit;
- rejection;
- duplicate detection;
- replay.

It will remain a focused simulation rather than a complete production interface engine.

HL7 and FHIR work is deferred until after the interview-focused Admissions SSIS, SSAS and SSRS demonstration.

---

## Regional downstream consumers

Regional consumers are represented broadly as:

```text
Regional data consumers
├── Shared-care and direct-care services
├── Population-health intelligence platform
└── Secure data environment and approved research
```

Aegis does not assert unsupported details about specific regional implementations.

---

# Source database design

## Source database purpose

`Aegis_Source` represents a permissive synthetic legacy PAS source.

It is not:

- the migration staging layer;
- the reconciled warehouse;
- the replacement EPR;
- a FHIR-validation service;
- a mastered patient index.

The source is expected to preserve:

- local identifiers;
- historic identifiers;
- patient merge lineage;
- superseded patient records;
- duplicate identifiers;
- incomplete values;
- source defects;
- inconsistent legacy values where deliberately generated.

Business validation and quarantine occur downstream in staging, SSIS and audit processing.

---

## Source schemas

The implemented schemas are:

- `pas`
- `epr`
- `ref`

---

## PAS tables

The implemented PAS tables are:

- `pas.Patient`
- `pas.PatientIdentifier`
- `pas.PatientMerge`
- `pas.Admission`
- `pas.ConsultantEpisode`
- `pas.Diagnosis`
- `pas.Procedure`
- `pas.WardStay`

### PAS dependency structure

```text
pas.Patient
├── pas.PatientIdentifier
├── pas.PatientMerge
│   ├── surviving patient
│   └── superseded patient
└── pas.Admission
    ├── pas.ConsultantEpisode
    │   ├── pas.Diagnosis
    │   └── pas.Procedure
    └── pas.WardStay
```

---

## Reference tables

The implemented reference tables are:

- `ref.Organisation`
- `ref.Site`
- `ref.Specialty`
- `ref.Consultant`
- `ref.Ward`

### Reference dependency structure

```text
ref.Organisation
├── ref.Site
│   └── ref.Ward
└── ref.Consultant

ref.Specialty
├── ref.Consultant
└── ref.Ward
```

---

# Patient identity and merge design

Patient identity is a first-class migration domain.

## `pas.PatientIdentifier`

Grain:

> One row per patient identifier assigned to a patient.

Implemented concepts include:

- patient;
- identifier value;
- identifier type;
- assigning authority;
- effective dates;
- current-status flag;
- created and updated timestamps.

The dataset contains:

- current local hospital identifiers;
- current deliberately invalid NHS-number-like identifiers;
- historic hospital identifiers;
- deliberately duplicated current hospital identifiers.

## `pas.PatientMerge`

Grain:

> One row per recorded patient-identity merge.

Implemented concepts include:

- surviving patient;
- superseded patient;
- surviving identifier;
- superseded identifier;
- merge date and time;
- merge reason;
- source message-control identifier;
- source-system code;
- audit timestamps.

The merge baseline models representative `ADT^A40` events.

### Merge processing principles

- The superseded patient remains in the permissive source.
- Source history is not silently deleted.
- Both sides of the merge remain traceable.
- Surviving and superseded identifiers are preserved.
- Merge message-control identifiers remain auditable.
- Downstream processing must avoid double-counting superseded patients.

### Current merge reconciliation

```text
Physical patient rows:         1,000
Superseded merged patients:       25
Logical patients after merges:   975
```

Downstream patient-merge resolution is deferred while the Admissions-only end-to-end reporting scenario is completed.

---

# Synthetic-data generation environment

## Python version

The Aegis virtual environment uses:

```text
Python 3.13.5
```

The environment is located at:

```text
.venv
```

and is excluded from Git.

## Installed dependencies

The committed `requirements.txt` currently contains:

```text
Faker==37.4.0
pyodbc==5.2.0
```

## SQL connectivity

Python connects successfully to:

```text
Driver:   ODBC Driver 18 for SQL Server
Server:   DESKTOP-N58JDOH
Database: Aegis_Source
Auth:     Windows integrated authentication
```

## Python package structure

```text
src/synthetic_data/
├── __init__.py
├── config.py
├── generate.py
├── generate_patients.py
├── generate_patient_identity_stage2.py
├── generate_patient_merges.py
├── generate_patient_journeys.py
├── generate_patient_journey_defects.py
├── load_reference_data.py
├── load_patient_data.py
├── load_patient_identity_stage2.py
├── load_patient_merges.py
├── load_patient_journeys.py
├── generators/
│   ├── __init__.py
│   ├── reference_data.py
│   ├── patient_data.py
│   ├── patient_identity_stage2.py
│   ├── patient_merge_data.py
│   ├── patient_journey_data.py
│   └── patient_journey_defects.py
├── models/
│   └── __init__.py
├── utilities/
│   ├── __init__.py
│   └── output_writer.py
└── validation/
    ├── __init__.py
    └── generation_validation.py
```

---

# Deterministic generation configuration

The primary generator configuration is:

```text
Random seed:            20260725
Organisations:                   3
Sites:                           5
Specialties:                    12
Consultants:                    36
Wards:                          24
Patients:                    1,000
Target patient merges:          25
Target controlled defects:      40
```

Separate deterministic seed offsets are used for later generation stages.

| Generation stage | Seed |
|---|---:|
| Reference and patient baseline | 20260725 |
| Stage 2 identity complexity | 20260727 |
| Valid patient journeys | 20260728 |

Changing a seed must be treated as a deliberate project change because it affects:

- record values;
- reconciliation totals;
- defect identities;
- repeatability;
- Git review;
- demonstrations.

---

# Generated source-data baseline

## Reference data

| Table | Rows |
|---|---:|
| `ref.Organisation` | 3 |
| `ref.Site` | 5 |
| `ref.Specialty` | 12 |
| `ref.Consultant` | 36 |
| `ref.Ward` | 24 |
| **Total reference rows** | **80** |

## Patient identity

| Table or category | Rows |
|---|---:|
| `pas.Patient` | 1,000 |
| Baseline current identifiers | 2,000 |
| Historic hospital identifiers | 150 |
| Duplicate current identifier rows | 20 |
| `pas.PatientIdentifier` total | 2,170 |
| `pas.PatientMerge` | 25 |

### Identifier profile

Each baseline patient has:

- one current `HOSPITAL_NUMBER`;
- one current `NHS_NUMBER`.

The Stage 2 identity pack adds:

- 150 closed historic `OLD` hospital identifiers;
- 10 deliberate duplicate identifier scenarios;
- 20 duplicate current identifier rows;
- 25 merge-ready patient pairs;
- 25 loaded patient-merge events.

All NHS-number-like values are unique and deliberately checksum-invalid.

---

## Valid admitted-patient activity

The valid patient-journey baseline is:

| Table | Rows |
|---|---:|
| `pas.Admission` | 1,600 |
| `pas.ConsultantEpisode` | 3,125 |
| `pas.Diagnosis` | 7,797 |
| `pas.Procedure` | 2,150 |
| `pas.WardStay` | 3,211 |
| **Total valid journey rows** | **17,883** |

### Admission state

| Admission state | Rows |
|---|---:|
| Open | 192 |
| Discharged | 1,408 |
| Total | 1,600 |

Open Admissions represent exactly 12% of the Admission baseline.

### Approximate activity ratios

```text
Consultant episodes per admission:    1.95
Diagnoses per episode:                2.50
Procedures per episode:               0.69
Ward stays per admission:             2.01
```

### Valid journey rules

The generated valid baseline enforces:

- discharge not before admission;
- open Admissions without discharge details;
- discharged Admissions with discharge details;
- episodes within Admission boundaries;
- continuous episode sequences;
- diagnosis dates within episode boundaries;
- one primary diagnosis per episode;
- continuous diagnosis sequences;
- procedure times within episode boundaries;
- one primary procedure where procedures exist;
- continuous procedure sequences;
- ward stays within Admission boundaries;
- continuous ward-stay sequences;
- one admission ward;
- one discharge ward for discharged Admissions;
- final open episode for open Admissions;
- final open ward stay for open Admissions;
- no activity against superseded merged patients;
- no activity against deceased patients in the valid baseline.

---

# Clinical terminology approach

The valid source currently uses controlled local codes such as:

```text
AEG-D001
AEG-D002
AEG-P001
AEG-P002
```

with descriptions such as:

```text
Synthetic chronic condition
Synthetic respiratory condition
Synthetic diagnostic procedure
Synthetic therapeutic procedure
```

These represent a local legacy clinical vocabulary.

A later staging or warehouse mapping design may demonstrate:

```text
AEGIS local diagnosis
        ↓
SNOMED CT concept mapping
        ↓
ICD-10 reporting classification
```

and:

```text
AEGIS local procedure
        ↓
SNOMED CT or local clinical concept
        ↓
OPCS-style reporting classification
```

The source PAS remains permissive and stores the local source values.

Terminology mapping, unmapped-code handling, mapping-version control and derived reporting codes belong downstream.

Aegis will not claim that its synthetic local codes are clinically complete or production coding standards.

---

# Controlled defect datasets

## Defect storage policy

Controlled journey defects are generated as inbound SSIS test extracts under:

```text
data/generated/defects
```

They are not loaded directly into `Aegis_Source`.

This models a realistic migration pattern:

```text
Legacy extract with defects
        ↓
SSIS ingestion
        ↓
Validation and lookup
        ↓
Accept / reject / quarantine
        ↓
Audit and reconciliation
```

## Identity defects

The identity dataset contains:

- 150 historic closed identifiers;
- 10 duplicate current hospital-identifier scenarios;
- 20 duplicate identifier rows;
- merge lineage;
- surviving and superseded identities.

The duplicate identifier cases are intentionally present in the permissive source so that downstream SSIS validation can identify and quarantine them.

## Journey defects

The journey defect pack contains:

| File | Rows | Scenarios |
|---|---:|---:|
| `admission_defects.csv` | 5 | 5 |
| `consultant_episode_defects.csv` | 4 | 4 |
| `diagnosis_defects.csv` | 4 | 3 |
| `procedure_defects.csv` | 2 | 2 |
| `ward_stay_defects.csv` | 2 | 1 |
| **Total** | **17** | **15** |

### Journey defect scenarios

#### Admission

- `DQ-ADM-001` — discharge before admission;
- `DQ-ADM-002` — open Admission containing discharge details;
- `DQ-ADM-003` — discharged Admission without discharge details;
- `DQ-ADM-004` — unknown patient;
- `DQ-ADM-005` — unknown site and organisation.

#### Consultant episode

- `DQ-EPI-001` — episode begins before Admission;
- `DQ-EPI-002` — episode ends after discharge;
- `DQ-EPI-003` — unknown Admission;
- `DQ-EPI-004` — non-contiguous episode sequence.

#### Diagnosis

- `DQ-DIA-001` — unknown consultant episode;
- `DQ-DIA-002` — diagnosis outside episode;
- `DQ-DIA-003` — duplicate primary diagnosis.

#### Procedure

- `DQ-PRO-001` — procedure outside episode;
- `DQ-PRO-002` — unknown consultant.

#### Ward stay

- `DQ-WARD-001` — overlapping ward stays.

### Expected processing outcome

All current journey defect scenarios are expected to be:

```text
QUARANTINE
```

Later SSIS packages may introduce distinctions between:

- rejection;
- quarantine;
- warning;
- accepted legacy condition;
- replay pending;
- corrected and replayed.

---

# Python generation and loading pattern

Each generation stage follows:

```text
Configuration
      ↓
Deterministic generation
      ↓
In-memory validation
      ↓
CSV and JSON output
      ↓
Validation-only loader execution
      ↓
Explicit database load
      ↓
SQL transaction
      ↓
Post-load reconciliation
```

Database loaders:

- default to validation-only mode;
- require `--load` to modify SQL Server;
- use Windows-integrated authentication;
- verify the target server and database;
- verify expected baseline counts;
- validate source files;
- validate foreign-key references;
- preserve deterministic identity values;
- commit only after all post-load controls pass;
- roll back the transaction on failure.

The rollback behaviour was proven during the initial reference-data load when an ODBC datatype-conversion issue caused the complete transaction to be rolled back before a corrected load was run.

---

# Validation status

## Foundation validation

The schema and deployment validation script is:

```text
sql/tests/validate_aegis_source_foundation.sql
```

It performs:

```text
56 checks
```

covering:

- schemas;
- source tables;
- key columns;
- reference tables;
- PAS relationships;
- reference-data relationships;
- `pas.PatientIdentifier`;
- `pas.PatientMerge`;
- keys;
- foreign keys;
- indexes;
- default constraints.

Result:

```text
56 passed
0 failed
```

---

## Day 2 source-data reconciliation

The complete data reconciliation script is:

```text
sql/tests/validate_aegis_source_day2_reconciliation.sql
```

It performs:

```text
63 checks
```

covering:

- reference-data counts;
- patient counts;
- current and historic identifiers;
- duplicate identifier scenarios;
- patient merges;
- logical patient counts after merges;
- activity row counts;
- referential integrity;
- merged-patient exclusion;
- deceased-patient exclusion;
- Admission rules;
- episode chronology;
- diagnosis chronology;
- procedure chronology;
- ward-stay chronology;
- episode and ward continuity;
- episode, diagnosis, procedure and ward sequences;
- primary diagnosis rules;
- primary procedure rules;
- open journey end states;
- admission and discharge ward flags;
- controlled-defect isolation.

Result:

```text
63 passed
0 failed
```

---

## Day 3 control-plane validation

The repeatable Day 3 validation script is:

```text
sql/tests/validate_aegis_day3_control_plane.sql
```

It performs:

```text
78 checks
```

covering:

- `Aegis_Audit` and `Aegis_Staging` deployment;
- audit, data-quality and replay schemas;
- landing, staging, quarantine and curated Admissions structures;
- batch and package-execution audit;
- validation-rule catalogue;
- record outcomes and data-quality exceptions;
- failed-execution history and absence of orphaned active runs;
- the valid 1,600-row baseline;
- the controlled five-row defect batch;
- the realistic 1,605-row mixed batch;
- one exception for each rule `DQ-ADM-001` through `DQ-ADM-005`;
- split source provenance;
- accepted and quarantined physical materialisation;
- complete mixed-batch reconciliation.

Result:

```text
78 passed
0 failed
```

### Latest validated mixed-batch result

```text
Source rows:                 1,605
Landing rows:                1,605
Staging rows:                1,605
Record outcomes:             1,605
Curated accepted rows:       1,600
Quarantined rows:                5
Data-quality exceptions:         5
Unexplained rows:                0
Batch status:                COMPLETED_WITH_EXCEPTIONS
Package status:              SUCCEEDED_WITH_EXCEPTIONS
```

The five quarantined Admissions comprise exactly one occurrence of each implemented rule:

- `DQ-ADM-001` — discharge before admission;
- `DQ-ADM-002` — open Admission contains discharge details;
- `DQ-ADM-003` — discharged Admission missing discharge details;
- `DQ-ADM-004` — unknown patient;
- `DQ-ADM-005` — unknown site or organisation.

---

## Day 4 reporting-layer validation

The Day 4 SQL reporting validation script is:

```text
sql/tests/validate_aegis_day4_admissions_reporting.sql
```

It performs:

```text
22 checks
```

covering:

- reporting schema deployment;
- `reporting.AdmissionAnalysis` deployment;
- reporting row count;
- distinct Admission count;
- distinct patient count;
- open Admission count;
- discharged Admission count;
- reporting-to-curated reconciliation;
- additive status-flag reconciliation;
- open Admission discharge-date rules;
- discharged Admission discharge-date rules;
- admission-date range;
- discharge-date range;
- minimum completed length of stay;
- maximum completed length of stay;
- average completed length of stay;
- lineage completeness;
- organisation references;
- site references;
- site-to-organisation consistency.

Result:

```text
22 passed
0 failed
```

Validated length-of-stay profile:

```text
Minimum completed length of stay:  0.33 days
Maximum completed length of stay: 14.00 days
Average completed length of stay:  7.43 days
```

Completed length of stay is calculated using elapsed minutes rather than calendar-day boundaries.

---

## Combined executed SQL validation

```text
Foundation validation:          56 / 56
Day 2 reconciliation:           63 / 63
Day 3 control plane:             78 / 78
Day 4 reporting layer:           22 / 22
                                -------
Combined SQL checks:            219 / 219
```

The Day 2 script also reports the external defect-pack control:

```text
Expected defect rows:       17
Expected scenarios:         15
Expected outcome:           QUARANTINE
```

The validation scripts raise SQL error `51000` when a control fails, making them suitable for later automated deployment or CI validation.

---

## Deployed-model DAX validation

The deployed SSAS model is independently validated using:

```text
src/ssas/Aegis.Analysis/validation/validate_aegis_admissions_model.dax
```

The DAX validation covers:

- core measure reconciliation;
- organisation and site filtering;
- organisation-to-site-to-Admission filter propagation;
- active Admission Date behaviour;
- inactive Discharge Date behaviour;
- yearly Admission and discharge trends.

Validated core model results:

```text
Admissions:                         1,600
Open Admissions:                      192
Discharged Admissions:              1,408
Distinct Patients:                    708
Average Completed Length of Stay:    7.43 days
Open Admission Percentage:          12.00%
```

Validated yearly activity:

| Year | Admissions | Discharges |
|---:|---:|---:|
| 2023 | 378 | 373 |
| 2024 | 411 | 403 |
| 2025 | 391 | 396 |
| 2026 | 420 | 236 |
| **Total** | **1,600** | **1,408** |

The lower 2026 discharge count is expected because the synthetic activity extends only to July 2026 and 192 Admissions remain open.

---

# Current loaded `Aegis_Source` baseline

| Domain | Object | Rows |
|---|---|---:|
| Reference | `ref.Organisation` | 3 |
| Reference | `ref.Site` | 5 |
| Reference | `ref.Specialty` | 12 |
| Reference | `ref.Consultant` | 36 |
| Reference | `ref.Ward` | 24 |
| Patient | `pas.Patient` | 1,000 |
| Identity | `pas.PatientIdentifier` | 2,170 |
| Identity | `pas.PatientMerge` | 25 |
| Activity | `pas.Admission` | 1,600 |
| Activity | `pas.ConsultantEpisode` | 3,125 |
| Activity | `pas.Diagnosis` | 7,797 |
| Activity | `pas.Procedure` | 2,150 |
| Activity | `pas.WardStay` | 3,211 |

### Loaded row total

```text
Reference rows:              80
Patient rows:             1,000
Identifier rows:          2,170
Merge rows:                  25
Valid journey rows:      17,883
                         ------
Total loaded rows:       21,158
```

Controlled defect extracts are excluded from this loaded total.

---

# Implemented audit and migration-control model

`Aegis_Audit` provides the operational control plane for the Admissions pipeline.

## Implemented schemas

```text
audit
dq
replay
```

## Implemented audit objects

```text
audit.Interface
audit.Batch
audit.PackageExecution
audit.RecordOutcome
dq.ValidationRule
dq.DataQualityException
replay.ReplayRequest
replay.ReplayAttempt
```

The replay structures are present as an architectural foundation, but controlled replay implementation is intentionally deferred until after the interview-focused Admissions scenario is complete.

## Implemented staging objects

```text
landing.Admission
stg.Admission
quarantine.Admission
curated.Admission
reporting.AdmissionAnalysis
```

The physical and analytical processing pattern is:

```text
Legacy PAS SQL source + controlled defect CSV
                    ↓
           landing.Admission
                    ↓
             stg.Admission
                    ↓
        validate and classify
             ├───────────────┐
             ↓               ↓
   curated.Admission   quarantine.Admission
             ↓
 reporting.AdmissionAnalysis
             ↓
 Aegis_Admissions_Analysis
```

---

## Batch and package audit

Each execution records:

- interface;
- batch reference;
- package execution;
- source, landed, accepted and quarantined counts;
- start and completion timestamps;
- execution and batch statuses;
- runtime error code and error detail;
- row-level outcomes;
- data-quality exceptions.

Package-level `OnError` handlers automatically close failed batches and package executions using:

```text
AEGIS-SSIS-RUNTIME
```

Controlled failure tests proved that failed runs do not leave batches in `PROCESSING` or package executions in `STARTED`.

## Processing statuses

Implemented operational outcomes include:

- `RECEIVED`;
- `PROCESSING`;
- `COMPLETED`;
- `COMPLETED_WITH_EXCEPTIONS`;
- `FAILED`;
- `SUCCEEDED`;
- `SUCCEEDED_WITH_EXCEPTIONS`;
- `ACCEPTED`;
- `QUARANTINED`.

---

# Reconciliation scope

Reconciliation compares:

```text
Legacy PAS source
        ↓
Migration staging and curated layer
        ↓
Reporting view
        ↓
SSAS semantic model
        ↓
SSRS reporting
```

Current implemented controls include:

- source, landing and staging counts;
- accepted and quarantined counts;
- record-outcome totals;
- data-quality exception totals;
- open Admissions;
- discharged Admissions;
- distinct patients represented in Admissions;
- daily and yearly Admission activity;
- daily and yearly discharge activity;
- completed length of stay;
- organisation and site activity;
- source-to-curated lineage;
- batch and package lineage;
- no unexplained migration rows.

Later controls may include:

- physical patient counts;
- logical patient counts after merges;
- current and historic identifiers;
- duplicate identifier exceptions;
- consultant episodes per spell;
- primary diagnoses;
- procedure counts;
- ward movements;
- statutory-style extract totals;
- interface-message totals;
- replay outcomes;
- report totals before and after source transition.

All reconciliation must be repeatable and attributable to a batch, file, message, interface execution or semantic-model deployment.

---

# SSIS delivery status

The SSIS solution is:

```text
src/ssis/Aegis.Integration/Aegis.Integration.sln
```

The SSIS project is:

```text
src/ssis/Aegis.Integration/Aegis.SSIS
```

## Project connection managers

```text
CM_Aegis_Source
CM_Aegis_Staging
CM_Aegis_Audit
```

## Implemented packages

```text
PKG_Load_Admissions.dtsx
PKG_Load_Admission_Defects.dtsx
PKG_Load_Admission_Mixed.dtsx
```

### `PKG_Load_Admissions.dtsx`

Processes the 1,600-row valid SQL-source baseline and proves the all-valid acceptance path.

### `PKG_Load_Admission_Defects.dtsx`

Processes five controlled defect rows and proves each data-quality and quarantine path independently.

### `PKG_Load_Admission_Mixed.dtsx`

Combines:

```text
1,600 valid SQL-source Admissions
+    5 controlled defect Admissions
-----------------------------------
1,605 Admissions in one audited batch
```

The package then:

1. registers the batch;
2. registers package execution;
3. lands both source branches;
4. writes landing audit counts;
5. populates staging;
6. performs lookup and business-rule classification;
7. writes record outcomes;
8. writes data-quality exceptions;
9. materialises accepted rows into `curated.Admission`;
10. materialises invalid rows into `quarantine.Admission`;
11. finalises batch and package reconciliation;
12. records unexpected runtime failures through a package-level `OnError` handler.

## Mixed Data Flow pattern

```text
Controlled defect CSV
        ↓
timestamp presence split
        ↓
normalisation and conversion
        ↓
defect triage and recombination
        ↓
row provenance
        ┐
        ├── Union All → row count → landing.Admission
        │
Valid PAS SQL source
        ↓
row provenance
        ┘
```

## Core migration principle

> Preserve the imperfect legacy source, detect and classify defects in staging, process what is valid, quarantine what is unsafe, and reconcile every outcome.

The current interview-focused implementation intentionally concentrates on Admissions.

Consultant episodes, diagnoses, procedures and ward stays remain available as deterministic source data and controlled defect extracts for later expansion using the proven Admissions template.

---

# Reporting-layer delivery status

## Reporting schema

The implemented reporting schema is:

```text
Aegis_Staging.reporting
```

## Reporting view

The implemented reporting view is:

```text
Aegis_Staging.reporting.AdmissionAnalysis
```

The view reads only active accepted records from:

```text
Aegis_Staging.curated.Admission
```

It provides:

- accepted Admission grain;
- admission and discharge dates;
- admission and discharge timestamps;
- organisation and site keys;
- Admission classifications;
- open and discharged flags;
- completed length of stay;
- length-of-stay bands;
- additive analytical flags;
- source-system lineage;
- source-record lineage;
- landing and staging lineage;
- batch and package-execution lineage;
- accepted and curated timestamps.

Validated reporting population:

```text
Admissions:                         1,600
Distinct Admissions:                1,600
Distinct Patients:                    708
Open Admissions:                      192
Discharged Admissions:              1,408
Average completed length of stay:    7.43 days
Incomplete lineage rows:                0
```

---

# SSAS Tabular delivery status

## Project

The SSAS solution is:

```text
src/ssas/Aegis.Analysis/Aegis.Analysis.sln
```

The SSAS project is:

```text
src/ssas/Aegis.Analysis/Aegis.Admissions.Analysis
```

## Configuration

```text
Platform:             SQL Server Analysis Services Tabular
Compatibility level:  1600
Target version:       SQL Server 2022
Deployment server:    DESKTOP-N58JDOH
Deployment database:  Aegis_Admissions_Analysis
Model name:           Model
```

The project:

- builds successfully;
- deploys successfully;
- processes successfully;
- is queryable through SSMS;
- passes deployed-model DAX validation.

---

## Model structure

The focused Admissions model contains:

```text
Fact Admission
Dim Organisation
Dim Site
Dim Date
```

The model uses a compact snowflake design:

```text
Dim Organisation
        ↓
Dim Site
        ↓
Fact Admission
```

with a role-playing date dimension:

```text
Dim Date
   ├── active → Fact Admission[AdmissionDate]
   └── inactive → Fact Admission[DischargeDate]
```

No direct relationship is created between `Dim Organisation` and `Fact Admission`, avoiding an unnecessary alternate filter path.

---

## Model relationships

| From | To | Cardinality | Active |
|---|---|---:|---|
| `Dim Organisation[OrganisationId]` | `Dim Site[OrganisationId]` | One-to-many | Yes |
| `Dim Site[SiteId]` | `Fact Admission[SiteId]` | One-to-many | Yes |
| `Dim Date[Date]` | `Fact Admission[AdmissionDate]` | One-to-many | Yes |
| `Dim Date[Date]` | `Fact Admission[DischargeDate]` | One-to-many | No |

All filter directions are single-direction from dimension to fact.

The inactive discharge-date relationship is activated through DAX using:

```text
USERELATIONSHIP
```

---

## Date dimension

`Dim Date` is implemented as a calculated DAX table.

Date range:

```text
2023-01-01 to 2026-12-31
```

Validated population:

```text
1,461 dates
```

Implemented attributes include:

- date;
- date key;
- year;
- quarter;
- quarter number;
- year-quarter;
- month;
- month short name;
- month number;
- year-month;
- year-month sort;
- day;
- day of week;
- abbreviated day of week;
- day-of-week number;
- weekend flag.

### Date hierarchies

```text
Calendar
├── Year
├── Quarter
├── Month
└── Date
```

```text
Calendar Month
├── Year
├── Year Month
└── Date
```

Chronological sort metadata is configured for:

- quarter;
- month;
- abbreviated month;
- year-month;
- length-of-stay bands.

---

## Measures

Implemented measures:

```text
Admissions
Open Admissions
Discharged Admissions
Distinct Patients
Average Completed Length of Stay
Open Admission Percentage
```

### Admissions

```DAX
Admissions :=
SUM('Fact Admission'[AdmissionCount])
```

### Open Admissions

```DAX
Open Admissions :=
SUM('Fact Admission'[OpenAdmissionCount])
```

### Discharged Admissions

```DAX
Discharged Admissions :=
CALCULATE(
    SUM('Fact Admission'[DischargedAdmissionCount]),
    USERELATIONSHIP(
        'Dim Date'[Date],
        'Fact Admission'[DischargeDate]
    )
)
```

### Distinct Patients

```DAX
Distinct Patients :=
DISTINCTCOUNT('Fact Admission'[PatientId])
```

### Average Completed Length of Stay

```DAX
Average Completed Length of Stay :=
AVERAGE('Fact Admission'[CompletedLengthOfStayDays])
```

### Open Admission Percentage

```DAX
Open Admission Percentage :=
DIVIDE(
    [Open Admissions],
    [Admissions]
)
```

Each measure includes a reporting-friendly description.

---

## Client-tool visibility

Technical relationship keys, internal migration identifiers, helper columns, additive count columns and sort columns are hidden from client tools where they are not required for report authoring.

Visible analytical and lineage fields include:

- Admission number;
- patient pathway identifier;
- admission and discharge dates;
- Admission classifications;
- discharge classifications;
- open and discharged flags;
- completed length of stay;
- length-of-stay band;
- source-system code;
- source-record identifier;
- accepted timestamp;
- curated timestamp;
- record-created timestamp;
- record-updated timestamp.

Hidden columns continue to support:

- relationships;
- sorting;
- measures;
- deployed-model behaviour.

---

## SSAS processing security

A dedicated SQL login was created for SSAS data-source processing:

```text
aegis_ssas_reader
```

It has read-only access through:

```text
db_datareader
```

on:

```text
Aegis_Staging
Aegis_Source
```

It does not have:

- server-administrator rights;
- database-owner rights;
- schema-modification rights;
- data-write rights.

The password is not stored in Git or documentation.

The local development connection uses SQL authentication because the user normally signs into Windows with a Windows Hello PIN and the existing Windows account password was not required for the portfolio implementation.

---

## SSAS documentation and visual evidence

Detailed model documentation:

```text
docs/06_Reporting/SSAS_Admissions_Tabular_Model.md
```

Model diagram:

```text
images/ssas/aegis_ssas_admissions_model.png
```

The README contains an SSAS Admissions analytical-model section showing:

- the model diagram;
- model structure;
- role-playing date relationships;
- validated analytical measures;
- reporting-validation results.

---

# Day 1 completion summary

Day 1 established the Aegis development platform, repository workflow and initial PAS source model.

## Platform and tooling completed

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
- SSRS web service configured.
- SSRS web portal configured.
- Visual Studio 2022 BI extensions installed.
- SSMS 22 Database DevOps workflow validated.
- Local SQL Server connected to Azure.
- Azure resource group `rg-aegis-dev` created.

## Database foundation completed

- `Aegis.Database.slnx` created.
- `Aegis.Source.sqlproj` created.
- SQL Server 2022 target configured.
- `pas`, `epr` and `ref` schemas created.
- Initial PAS and reference tables created.
- Project build and publish validated.
- Initial deployment suite completed.

Day 1 final validation at the time was:

```text
33 passed
0 failed
```

The foundation suite was extended to 56 checks during Day 2.

---

# Day 2 completion summary

Day 2 established the complete synthetic PAS source-data and patient-identity foundation.

## Database schema completed

- `pas.PatientIdentifier` created.
- `pas.PatientMerge` created.
- Supporting keys, foreign keys and indexes created.
- `Aegis.Source` built successfully.
- `Aegis.Source` published successfully.
- Foundation validation extended from 33 to 56 checks.
- Foundation result: 56 of 56 passed.

## Documentation completed

- Interface inventory created:

```text
docs/04_ETL/Interface_Inventory.md
```

- Synthetic-data governance rules created:

```text
docs/10_Governance/Synthetic_Data_Generation_and_Safety_Rules.md
```

## Python environment completed

- Project-specific `.venv` created.
- Python 3.13.5 selected.
- Faker installed.
- pyodbc installed.
- SQL Server ODBC connectivity validated.
- `.venv`, build outputs, secrets and generated temporary data excluded through `.gitignore`.

## Synthetic reference data completed

- Three organisations generated and loaded.
- Five sites generated and loaded.
- Twelve specialties generated and loaded.
- Thirty-six consultants generated and loaded.
- Twenty-four wards generated and loaded.
- Reference total: 80 rows.

## Patient identity completed

- 1,000 valid synthetic patients generated and loaded.
- 2,000 baseline current identifiers generated and loaded.
- All NHS-number-like values deliberately fail checksum validation.
- 150 historic identifiers generated and loaded.
- 10 duplicate identifier scenarios generated.
- 20 duplicate current identifier rows loaded.
- 25 merge-ready patient pairs generated.
- 25 ADT-A40-style patient merge events generated and loaded.
- Logical patient count after merge resolution: 975.

## Valid patient journeys completed

- 1,600 Admissions generated and loaded.
- 3,125 consultant episodes generated and loaded.
- 7,797 diagnoses generated and loaded.
- 2,150 procedures generated and loaded.
- 3,211 ward stays generated and loaded.
- 17,883 valid journey rows loaded.
- 192 open Admissions validated.
- 1,408 discharged Admissions validated.

## Controlled defects completed

- 15 controlled journey defect scenarios created.
- 17 deliberately invalid journey rows created.
- Defect extracts retained outside `Aegis_Source`.
- All current defect outcomes defined as `QUARANTINE`.
- Identity defects retained in the permissive source where appropriate.
- Journey referential and chronology defects retained as inbound SSIS files.

## Final Day 2 validation completed

- Foundation suite: 56 of 56 passed.
- Source-data reconciliation suite: 63 of 63 passed.
- Combined executed validation: 119 of 119 passed.
- No controlled journey defect rows were loaded into `Aegis_Source`.
- Final Day 2 source state was ready for SSIS staging, audit and quarantine development.

---

# Day 3 completion summary

Day 3 established the complete audited Admissions migration-control plane.

## Database delivery completed

- `Aegis.Audit` database project created, built and published.
- `Aegis.Staging` database project created, built and published.
- Audit, data-quality and replay schemas implemented.
- Landing, staging, quarantine and curated schemas implemented.
- Admissions landing, staging, quarantine and curated tables implemented.
- Validation-rule catalogue seeded with `DQ-ADM-001` through `DQ-ADM-005`.
- Replay request and replay-attempt structures created for future controlled remediation.

## SSIS delivery completed

- SSIS solution and project created.
- Project-level source, staging and audit connections configured.
- Valid Admissions package implemented.
- Controlled defect Admissions package implemented.
- Realistic mixed Admissions package implemented.
- SQL-source and flat-file ingestion demonstrated.
- Nullable timestamp processing and conversion implemented.
- Derived-column provenance implemented.
- Conditional Split and Union All transformations implemented.
- Row-count capture implemented.
- Batch and package audit implemented.
- Row-level outcome and data-quality exception audit implemented.
- Physical accepted and quarantine layers implemented.
- Package-level automatic `OnError` audit closure implemented and tested.

## Final Day 3 processing evidence

```text
Latest mixed BatchId:        17
Source rows:              1,605
Landed rows:              1,605
Staged rows:              1,605
Accepted/curated rows:    1,600
Quarantined rows:             5
DQ exceptions:                5
Unexplained rows:             0
```

The latest mixed batch completed as:

```text
BatchStatus:      COMPLETED_WITH_EXCEPTIONS
ExecutionStatus:  SUCCEEDED_WITH_EXCEPTIONS
```

## Final Day 3 validation

```text
78 passed
0 failed
```

Day 3 established the repeatable, fully reconciled Admissions pipeline required for downstream semantic modelling and reporting.

---

# Day 4 completion summary

Day 4 established the focused Admissions analytical and semantic-model layer.

## Reporting database layer completed

The reporting schema was added to:

```text
Aegis_Staging
```

Implemented object:

```text
reporting.AdmissionAnalysis
```

The view exposes only active accepted Admissions from:

```text
curated.Admission
```

It provides:

- reporting-friendly Admission and discharge dates;
- open and discharged Admission flags;
- completed length of stay;
- length-of-stay bands and sort order;
- additive analytical count columns;
- complete source-to-curated lineage;
- batch and package-execution lineage.

Validated reporting population:

```text
Admissions:                         1,600
Distinct Admissions:                1,600
Distinct Patients:                    708
Open Admissions:                      192
Discharged Admissions:              1,408
Average completed length of stay:    7.43 days
Incomplete lineage rows:                0
```

## SSAS Tabular project completed

The SSAS solution is:

```text
src/ssas/Aegis.Analysis/Aegis.Analysis.sln
```

The SSAS Tabular project is:

```text
src/ssas/Aegis.Analysis/Aegis.Admissions.Analysis
```

Model configuration:

```text
Platform:             SQL Server Analysis Services Tabular
Compatibility level:  1600
Target version:       SQL Server 2022
Deployment server:    DESKTOP-N58JDOH
Deployment database:  Aegis_Admissions_Analysis
Model name:           Model
```

The project builds and deploys successfully.

## Model structure completed

The focused Admissions model contains:

```text
Fact Admission
Dim Organisation
Dim Site
Dim Date
```

The model uses the following filter path:

```text
Dim Organisation
        ↓
Dim Site
        ↓
Fact Admission
```

Implemented relationships:

| From | To | Cardinality | Active |
|---|---|---:|---|
| `Dim Organisation[OrganisationId]` | `Dim Site[OrganisationId]` | One-to-many | Yes |
| `Dim Site[SiteId]` | `Fact Admission[SiteId]` | One-to-many | Yes |
| `Dim Date[Date]` | `Fact Admission[AdmissionDate]` | One-to-many | Yes |
| `Dim Date[Date]` | `Fact Admission[DischargeDate]` | One-to-many | No |

The inactive discharge-date relationship is activated through DAX with:

```text
USERELATIONSHIP
```

## Date model completed

`Dim Date` is a calculated DAX table covering:

```text
2023-01-01 to 2026-12-31
```

Validated population:

```text
1,461 dates
```

Implemented hierarchies:

```text
Calendar
├── Year
├── Quarter
├── Month
└── Date
```

```text
Calendar Month
├── Year
├── Year Month
└── Date
```

Chronological sort metadata was configured for:

- quarters;
- months;
- abbreviated months;
- year-month values;
- length-of-stay bands.

## Measures completed

Implemented measures:

```text
Admissions
Open Admissions
Discharged Admissions
Distinct Patients
Average Completed Length of Stay
Open Admission Percentage
```

Validated deployed-model results:

```text
Admissions:                         1,600
Open Admissions:                      192
Discharged Admissions:              1,408
Distinct Patients:                    708
Average Completed Length of Stay:    7.43 days
Open Admission Percentage:          12.00%
```

## Client-tool model completed

Technical relationship keys, internal migration identifiers, additive helper columns and sort columns were hidden from client tools.

Reporting classifications, business attributes and selected lineage fields remain visible.

Each measure includes a reporting-friendly description.

## Data access completed

A dedicated least-privilege SQL login was created for SSAS processing:

```text
aegis_ssas_reader
```

The login has read-only `db_datareader` access to:

```text
Aegis_Staging
Aegis_Source
```

It does not have database-owner, administrative, write or schema-modification rights.

No password or secret is stored in Git or project documentation.

## Day 4 validation completed

The SQL reporting-layer validation script is:

```text
sql/tests/validate_aegis_day4_admissions_reporting.sql
```

Result:

```text
22 passed
0 failed
```

The deployed SSAS model validation file is:

```text
src/ssas/Aegis.Analysis/validation/validate_aegis_admissions_model.dax
```

The DAX validation proves:

- core measure reconciliation;
- organisation and site filtering;
- active Admission Date behaviour;
- inactive Discharge Date behaviour;
- yearly Admission and discharge trends.

## Documentation and visual evidence completed

Detailed SSAS model documentation:

```text
docs/06_Reporting/SSAS_Admissions_Tabular_Model.md
```

Model diagram:

```text
images/ssas/aegis_ssas_admissions_model.png
```

The README now includes an SSAS Admissions analytical-model section between the audited SSIS pipeline and implemented architecture sections.

## Day 4 final status

```text
Aegis_Source build:                  SUCCEEDED
Aegis_Staging build:                 SUCCEEDED
Aegis_Staging publish:               SUCCEEDED
SSAS Tabular build:                  SUCCEEDED
SSAS Tabular deployment:             SUCCEEDED
SQL reporting validation:            22 / 22
Deployed-model DAX validation:       PASSED
Combined SQL validation:             219 / 219
```

The focused Admissions semantic model is ready to support Day 5 SSRS reporting.

---

# Revised delivery plan

## Day 1 — Platform and PAS source foundation

**Status:** Complete.

Delivered:

- repository foundation;
- SQL Server BI platform;
- SQL database project;
- PAS source model;
- reference-data model;
- build and publish workflow;
- initial deployment validation.

## Day 2 — Synthetic PAS data and patient identity

**Status:** Complete.

Delivered:

- patient identifiers and merge history;
- deterministic reference and patient data;
- admitted-patient journeys;
- controlled defect extracts;
- source reconciliation;
- 119 of 119 combined checks passed.

## Day 3 — Staging, audit and SSIS

**Status:** Complete.

Delivered:

- staging and audit databases;
- audited valid, defect-only and mixed Admissions packages;
- accepted and quarantine materialisation;
- package-level failure handling;
- 78 of 78 control-plane checks passed.

## Day 4 — SSAS Tabular Admissions model

**Status:** Complete.

Delivered:

- Admissions reporting view;
- organisation, site and date dimensions;
- focused Admissions fact;
- role-playing Admission and Discharge dates;
- date hierarchies;
- DAX measures;
- least-privilege SSAS processing account;
- deployed SSAS model;
- SQL and DAX validation;
- 22 of 22 SQL reporting checks passed;
- 219 of 219 combined SQL checks passed;
- model documentation and README visual.

## Day 5 — SSRS Admissions reporting

**Status:** Complete.

Delivered:

- Visual Studio Report Server solution and project;
- shared SSAS data source;
- `Admissions Activity and Trends` paginated report;
- six governed KPI measures;
- monthly Admission and discharge trend;
- organisation parameter with `All Organisations` default;
- parameter-aware KPI and monthly datasets;
- organisation-aware site activity table;
- single-page A4 landscape rendering;
- successful project build and deployment;
- deployed SSRS portal validation;
- report screenshot;
- detailed report documentation;
- README visual and status updates.

The release deliberately contains one polished report rather than three partially completed reports.

Deferred SSRS enhancements include:

- Open Admissions and Length of Stay;
- Migration Reconciliation and Data Quality;
- quarantined Admission detail;
- source-to-curated lineage detail;
- cascading site parameters;
- scheduled subscriptions;
- role-based report security.

## Later roadmap

Deferred until after the interview-focused end-to-end demonstration:

- consultant episodes;
- diagnoses;
- procedures;
- ward stays;
- downstream patient-merge processing;
- controlled replay;
- HL7 and FHIR;
- broader warehouse and statutory-style extracts;
- transactional replication;
- log shipping;
- Azure SQL demonstration;
- Power BI management summary.

### Microsoft Purview placeholder

After Day 5 SSRS is complete, review a focused Microsoft Purview governance demonstration covering appropriate concepts such as:

```text
Aegis clinical-data assets
        ↓
Microsoft Purview Data Map
        ↓
Scanning and metadata discovery
        ↓
Classification and ownership
        ↓
Unified Catalog discovery
        ↓
Technical and business lineage
```

Potential Purview scope may include:

- registering representative Aegis SQL data assets;
- Data Map concepts;
- Unified Catalog concepts;
- clinical-data discovery;
- business-domain ownership;
- data-product concepts;
- classification of patient-identifying and clinical fields;
- glossary terms;
- source-to-curated-to-report lineage;
- data-quality and stewardship context;
- documenting what can be demonstrated safely in a public synthetic portfolio.

The detailed Purview approach should be discussed only after the Day 5 SSRS implementation, so that it does not disrupt the current end-to-end Admissions delivery.

---

# Day 5 completion summary

Day 5 completed the focused Admissions reporting path through SQL Server Reporting Services.

## SSRS solution and project

```text
Solution:
src/ssrs/Aegis.Reporting/Aegis.Reporting.sln
```

```text
Project:
src/ssrs/Aegis.Reporting/Aegis.Admissions.Reporting
```

## Implemented report

```text
Admissions Activity and Trends
```

Source file:

```text
src/ssrs/Aegis.Reporting/Aegis.Admissions.Reporting/Reports/Admissions Activity and Trends.rdl
```

Shared data source:

```text
DS_Aegis_Admissions_Analysis
```

Data source target:

```text
Server:   DESKTOP-N58JDOH
Database: Aegis_Admissions_Analysis
Type:     Microsoft SQL Server Analysis Services
Auth:     Windows integrated authentication
```

## Embedded datasets

```text
DS_KPI_Summary
DS_Monthly_Activity
DS_Organisation_Site_Activity
DS_Organisation_Parameter
```

## Report content

The report contains:

- Admissions;
- Open Admissions;
- Discharged Admissions;
- Distinct Patients;
- Average Completed Length of Stay;
- Open Admission Percentage;
- monthly Admission and discharge trend;
- organisation parameter;
- site activity table;
- synthetic cut-off explanation.

## Organisation parameter

The report parameter is:

```text
Organisation
```

Available values:

```text
All Organisations
Aegis Integrated Care Services
Aegis University Hospitals NHS Trust
North Aegis Community Health Partnership
```

The default value is:

```text
All Organisations
```

The parameter controls:

- KPI cards;
- monthly chart;
- site activity table.

## Validated unfiltered report

```text
Admissions:                         1,600
Open Admissions:                      192
Discharged Admissions:              1,408
Distinct Patients:                    708
Average Completed Length of Stay:    7.43 days
Open Admission Percentage:          12.00%
Site rows:                               5
```

## Validated filtered report

For:

```text
Aegis University Hospitals NHS Trust
```

the report returns:

```text
Admissions:                         655
Open Admissions:                     75
Discharged Admissions:              580
Distinct Patients:                  447
Average Completed Length of Stay:   7.38 days
Open Admission Percentage:         11.45%
Site rows:                            2
```

The two filtered sites are:

```text
Aegis Community Hospital
Aegis General Hospital
```

Their totals reconcile exactly to the filtered KPI values.

## Monthly trend validation

The July 2026 spike is intentional and reflects the synthetic reporting cut-off.

Validated July 2026 values:

```text
Admissions:              203
Open Admissions:         192
Discharged Admissions:    18
```

The report uses a parameter-safe explanatory note:

```text
The July 2026 increase reflects the synthetic reporting cut-off, with a substantial proportion of recently recorded Admissions remaining open.
```

## Layout

```text
Page:        A4 landscape
Page width:  29.7 cm
Page height: 21.0 cm
Margins:      1.0 cm
Body width:  27.5 cm
Pages:        1
```

## Build and deployment

```text
Build:   1 succeeded or up-to-date
Failed:  0
Skipped: 0
```

```text
Deploy:  1 succeeded
Failed:  0
Skipped: 0
```

Deployment target:

```text
http://localhost/reportserver
```

Portal path:

```text
Aegis
└── Admissions
    └── Admissions Activity and Trends
```

Portal validation completed with:

- no credential prompt;
- no data-source error;
- correct default parameter state;
- correct filtered parameter state;
- correct KPI reconciliation;
- correct site reconciliation;
- correct chart filtering;
- single-page rendering.

## Documentation and visual evidence

Detailed SSRS documentation:

```text
docs/06_Reporting/SSRS_Admissions_Operational_Report.md
```

Screenshot:

```text
images/ssrs/aegis_ssrs_admissions_activity_and_trends.png
```

## Final Day 5 status

```text
SSRS project build:                  SUCCEEDED
SSRS project deployment:             SUCCEEDED
Deployed portal validation:          PASSED
All-organisation reconciliation:     PASSED
Organisation filtering:              PASSED
Site-level reconciliation:           PASSED
Single-page rendering:                PASSED
```

The focused Admissions delivery path is now complete:

```text
Synthetic PAS
        ↓
Audited SSIS
        ↓
Accepted or quarantined
        ↓
Governed reporting view
        ↓
SSAS Tabular model
        ↓
SSRS operational report
```

---

# Next recommended phase

Before implementing Microsoft Purview, review the smallest credible governance demonstration and confirm:

- tenant and licensing prerequisites;
- available Microsoft Purview capabilities;
- safe connectivity to synthetic Aegis assets;
- portfolio value relative to implementation effort;
- whether documentation-only architecture or live implementation is the better next step.

The current Admissions release should remain stable while that scope is assessed.

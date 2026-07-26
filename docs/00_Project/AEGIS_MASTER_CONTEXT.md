# Aegis Master Context

## Project identity

**Name:** Aegis Clinical Data Platform  
**Repository:** Aegis  
**Purpose:** Synthetic NHS-style clinical data migration, reporting and operational-assurance platform.  
**Current branch:** `dev`  
**Current delivery position:** Day 2 complete; ready to begin Day 3 staging, audit and SSIS development.

---

## Strategic purpose

Aegis is a portfolio project designed to demonstrate practical delivery across the traditional Microsoft SQL Server business-intelligence platform while applying modern software-engineering, data-governance and DevOps practices.

It complements Atlas:

- **Atlas:** Microsoft Fabric, cloud data engineering, real-time analytics and AI.
- **Aegis:** SQL Server, SSIS, SSAS Tabular, SSRS, healthcare migration, reporting, database resilience and operational assurance.

Aegis is intended to demonstrate that the same disciplined engineering principles can be applied across both modern cloud platforms and established enterprise SQL Server estates.

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

---

## Core technologies

- SQL Server 2022 Developer Edition
- T-SQL
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

---

## Planned databases

- `Aegis_Source`
- `Aegis_Staging`
- `Aegis_Audit`
- `Aegis_Warehouse`
- `Aegis_Reporting`
- `Aegis_Source_ReportingReplica`
- `Aegis_Warehouse_DR`

### Current database status

| Database | Status |
|---|---|
| `Aegis_Source` | Implemented and populated |
| `Aegis_Staging` | Planned for Day 3 |
| `Aegis_Audit` | Planned for Day 3 |
| `Aegis_Warehouse` | Planned for Day 4 |
| `Aegis_Reporting` | Planned |
| `Aegis_Source_ReportingReplica` | Planned for replication demonstration |
| `Aegis_Warehouse_DR` | Planned for log-shipping demonstration |

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

### Tool responsibilities

Use **SSMS Database DevOps** for:

- SQL database projects;
- schema-object authoring;
- database-project build;
- DACPAC creation;
- DACPAC publication;
- SQL parser and deployment validation.

Use **VS Code** for:

- Git operations;
- Markdown documentation;
- Python;
- PowerShell;
- repository-wide review;
- generated-file inspection;
- general development work.

Standalone SQL validation and reconciliation scripts may be created and executed in SSMS, provided they are saved within the repository under `sql/`.

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

The source database project is:

```text
src/database/Aegis.Source/Aegis.Source.sqlproj
```

The project targets SQL Server 2022 and publishes to:

```text
DESKTOP-N58JDOH
└── Aegis_Source
```

The `Aegis.Source` project currently builds and publishes successfully.

### Build-artifact rule

Generated build outputs must not be committed to normal Git history.

Excluded artefacts include:

```text
**/bin/
**/obj/
*.dacpac
```

DACPAC files are reproducible build outputs. A future CI/CD workflow may publish them as pipeline or release artefacts, but locally generated DACPACs do not belong in the repository source tree.

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
- passwords, secrets or private connection strings.

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
- Pause after each significant build, publish, generation, load or validation operation.
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
- Capture diagrams and screenshots under `images`.
- Keep generated `bin`, `obj`, DACPAC and virtual-environment artefacts outside Git.

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
├── sql/
│   ├── administration/
│   ├── deployment/
│   ├── monitoring/
│   └── tests/
├── src/
│   ├── database/
│   └── synthetic_data/
├── .gitignore
└── requirements.txt
```

Generated data under `data/generated` is currently excluded from Git while the generator and schemas are still evolving.

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

Visual Studio 2022 contains the required BI extensions for:

- SSIS;
- SSAS;
- SSRS.

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

Aegis will avoid unsupported claims about the exact private products or implementation details used by real NHS organisations.

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
| Reconciliation results | Staging/Warehouse | Audit | SQL Server | Batch and attribute controls |

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

The initial HL7 implementation will include:

- `ADT^A01` — admit;
- `ADT^A02` — transfer;
- `ADT^A03` — discharge;
- `ADT^A08` — patient-information update;
- `ADT^A40` — patient-identifier merge.

A later representative clinical-result interface may include:

- `ORU^R01` — observation or laboratory result.

The implementation will demonstrate:

- receipt;
- parsing;
- validation;
- audit;
- rejection;
- duplicate detection;
- replay.

It will remain a focused simulation rather than a complete production interface engine.

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

Business validation and quarantine will occur downstream in staging, SSIS and audit processing.

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

Open admissions represent exactly 12% of the admission baseline.

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
- open admissions without discharge details;
- discharged admissions with discharge details;
- episodes within admission boundaries;
- continuous episode sequences;
- diagnosis dates within episode boundaries;
- one primary diagnosis per episode;
- continuous diagnosis sequences;
- procedure times within episode boundaries;
- one primary procedure where procedures exist;
- continuous procedure sequences;
- ward stays within admission boundaries;
- continuous ward-stay sequences;
- one admission ward;
- one discharge ward for discharged admissions;
- final open episode for open admissions;
- final open ward stay for open admissions;
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
- `DQ-ADM-002` — open admission containing discharge details;
- `DQ-ADM-003` — discharged admission without discharge details;
- `DQ-ADM-004` — unknown patient;
- `DQ-ADM-005` — unknown site and organisation.

#### Consultant episode

- `DQ-EPI-001` — episode begins before admission;
- `DQ-EPI-002` — episode ends after discharge;
- `DQ-EPI-003` — unknown admission;
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

It currently performs:

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
- admission rules;
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

## Combined executed validation

```text
Foundation validation:       56 / 56
Day 2 reconciliation:        63 / 63
                             -------
Combined checks:            119 / 119
```

The Day 2 script also reports the external defect-pack control:

```text
Expected defect rows:       17
Expected scenarios:         15
Expected outcome:           QUARANTINE
```

The script raises SQL error `51000` if any loaded-source control fails, making it suitable for later automated deployment or CI validation.

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

# Planned audit model

The future `Aegis_Audit` database will include batch, interface, validation, quarantine and replay structures.

## Interface-message audit

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

## Batch audit

Planned concepts include:

```text
audit.Batch
├── BatchId
├── InterfaceCode
├── SourceFileName
├── StartedAt
├── CompletedAt
├── BatchStatus
├── SourceRowCount
├── AcceptedRowCount
├── RejectedRowCount
├── QuarantinedRowCount
├── WarningRowCount
└── ReplayedRowCount
```

## Record-level exception audit

Planned concepts include:

```text
audit.DataQualityException
├── DataQualityExceptionId
├── BatchId
├── ScenarioCode
├── SourceObject
├── SourceRecordIdentifier
├── ValidationRuleCode
├── ExpectedOutcome
├── ErrorCode
├── ErrorDetail
├── QuarantinedAt
├── ResolutionStatus
└── ResolvedAt
```

## Processing statuses

The conceptual processing states are:

- `RECEIVED`
- `PROCESSING`
- `PROCESSED`
- `REJECTED`
- `QUARANTINED`
- `REPLAY_PENDING`
- `REPLAYED`
- `DUPLICATE`
- `CANCELLED`

Exact values and constraints will be finalised during Day 3.

---

# Reconciliation scope

Reconciliation compares:

```text
Legacy PAS source
        ↓
Migration staging and target
        ↓
Warehouse and reporting outputs
```

Planned controls include:

- physical patient counts;
- logical patient counts after merges;
- current and historic identifiers;
- duplicate identifier exceptions;
- open admissions;
- discharged admissions;
- consultant episodes per spell;
- primary diagnoses;
- procedure counts;
- ward movements;
- daily admissions;
- daily discharges;
- source-to-target attribute comparisons;
- statutory-style extract totals;
- interface-message totals;
- processing failures;
- quarantine totals;
- replay outcomes;
- report totals before and after source transition.

All reconciliation must be repeatable and attributable to a batch, file, message or interface run.

---

# SSIS delivery direction

The current synthetic source is rich enough to support meaningful SSIS packages resembling a real PAS/EPR migration and assurance workload.

The expected high-level flow is:

```text
Extract from legacy PAS
        ↓
Land in staging
        ↓
Validate and classify
        ↓
Load accepted rows
        ↓
Redirect rejected rows
        ↓
Write audit counts
        ↓
Reconcile source, staging and target
```

Representative future packages include:

```text
01_Load_Reference_Data
02_Load_Patient_Identity
03_Load_Admissions
04_Load_Consultant_Episodes
05_Load_Diagnoses_Procedures
06_Load_Ward_Stays
07_Process_Patient_Merges
08_Reconcile_Migration_Batch
09_Replay_Quarantined_Records
```

Planned SSIS capabilities include:

- source-file ingestion;
- SQL source extraction;
- lookup transformations;
- conditional splits;
- derived validation flags;
- duplicate detection;
- error outputs;
- quarantine tables;
- row-count variables;
- package audit logging;
- batch audit logging;
- source-to-target reconciliation;
- restartability;
- replay;
- package-level and record-level error handling.

The core migration principle is:

> Preserve the imperfect legacy source, detect and classify defects in staging, migrate what is valid, quarantine what is unsafe, and reconcile every outcome.

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

- 1,600 admissions generated and loaded.
- 3,125 consultant episodes generated and loaded.
- 7,797 diagnoses generated and loaded.
- 2,150 procedures generated and loaded.
- 3,211 ward stays generated and loaded.
- 17,883 valid journey rows loaded.
- 192 open admissions validated.
- 1,408 discharged admissions validated.

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
- Final Day 2 source state is ready for SSIS staging, audit and quarantine development.

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

- `pas.PatientIdentifier`;
- `pas.PatientMerge`;
- extended schema validation;
- interface inventory;
- synthetic-data safety rules;
- Python environment;
- deterministic reference data;
- deterministic patient data;
- deliberately invalid NHS-number-like values;
- historic identifiers;
- duplicate identifiers;
- merge-ready patient pairs;
- loaded patient merges;
- valid admitted-patient journeys;
- controlled invalid journey extracts;
- final source-data reconciliation;
- 119 of 119 combined checks passed.

## Day 3 — Staging, audit and SSIS

**Status:** Next.

Planned:

- create `Aegis_Staging`;
- create `Aegis_Audit`;
- create database projects for staging and audit;
- define staging schemas and table grains;
- define batch-audit structures;
- define record-level quarantine structures;
- define validation-rule catalogue;
- define replay status model;
- establish SSIS solution and project;
- build the first package framework;
- load relational PAS extracts;
- process valid and invalid records;
- route failures into quarantine;
- reconcile accepted, rejected and quarantined counts;
- begin representative ADT processing.

## Day 4 — Warehouse and reconciliation

Planned:

- create `Aegis_Warehouse`;
- build conformed dimensions and facts;
- resolve patient merges into logical patient identity;
- map local source codes;
- reconcile source, staging and warehouse;
- produce an APC-style episode extract;
- add batch and interface monitoring views.

## Day 5 — SSAS and SSRS

Planned:

- build SSAS Tabular model;
- Migration Reconciliation Report;
- Data Quality Exception Report;
- Interface and Cutover Readiness Report;
- Patient Journey Report;
- optional Power BI management summary.

## Day 6 — SQL Server resilience

Planned:

- transactional replication;
- reporting replica;
- log shipping;
- monitoring scripts;
- recovery exercise;
- operational runbooks.

## Day 7 — Cloud demonstration and release

Planned if time permits:

- Azure SQL compatibility assessment;
- Azure SQL demonstration target;
- README diagrams;
- screenshots;
- release documentation;
- interview demonstration;
- interview questions and model answers.

---

# Day 3 starting position

Day 3 begins with a stable and fully reconciled legacy-source baseline.

## Available source domains

```text
Reference
├── Organisation
├── Site
├── Specialty
├── Consultant
└── Ward

Patient identity
├── Patient
├── PatientIdentifier
└── PatientMerge

Admitted-patient activity
├── Admission
├── ConsultantEpisode
├── Diagnosis
├── Procedure
└── WardStay
```

## Available controlled defect inputs

```text
data/generated/defects/
├── admission_defects.csv
├── consultant_episode_defects.csv
├── diagnosis_defects.csv
├── procedure_defects.csv
├── ward_stay_defects.csv
├── patient_identity_defect_manifest.csv
└── patient_journey_defect_manifest.csv
```

## Day 3 architectural objective

Create a repeatable migration-control plane that can:

```text
Receive a batch
      ↓
Audit the batch
      ↓
Land raw records
      ↓
Validate structure and business rules
      ↓
Resolve reference and identity keys
      ↓
Accept valid records
      ↓
Quarantine invalid records
      ↓
Record every outcome
      ↓
Reconcile all counts
      ↓
Support controlled replay
```

## Recommended Day 3 sequence

1. Review the current solution and repository state.
2. Define the responsibilities of `Aegis_Staging`.
3. Define the responsibilities of `Aegis_Audit`.
4. Create the staging and audit SQL database projects.
5. Define `stg`, `audit` and quarantine schemas.
6. Create batch and package audit tables.
7. Create validation-rule and exception tables.
8. Create staging tables for reference and PAS domains.
9. Build and publish both databases.
10. Extend automated deployment validation.
11. Create the SSIS solution and initial project.
12. Build the first audited ingestion package.
13. Process a valid source extract.
14. Process a controlled defect extract.
15. Reconcile source, accepted and quarantined counts.

---

# Immediate next steps

1. Save this updated `AEGIS_MASTER_CONTEXT.md`.
2. Review `git status`.
3. Confirm no generated data, `.venv`, DACPAC, `bin` or `obj` artefacts are staged.
4. Review the complete Day 2 change set.
5. Commit the Day 2 database, documentation, Python and validation work to `dev`.
6. Create and merge the Day 2 pull request when ready.
7. Begin Day 3 in a new chat using this file as the authoritative context.
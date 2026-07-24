# Aegis PAS Source Model

## Purpose

This document defines the synthetic Patient Administration System source model used by Aegis.

The model represents the operational structure of a fictional NHS hospital PAS rather than reproducing the proprietary physical schema of Dedalus iPM, Nervecentre, Cerner, Epic or another commercial platform.

Its purpose is to provide a realistic relational source for:

- PAS and EPR migration exercises
- SSIS extraction and transformation
- Data profiling and cleansing
- Source-to-target mapping
- Migration validation and reconciliation
- HES-style secondary-use extracts
- SSRS operational reporting
- SSAS analytical modelling

## Design principles

The PAS source model follows these principles:

- Model operational hospital activity rather than a flattened reporting extract.
- Preserve realistic legacy identifiers and local codes.
- Use permissive source tables so that poor-quality records can exist.
- Apply strict validation in downstream staging and migration layers.
- Separate patient, admission, episode, diagnosis, procedure and ward-stay grain.
- Preserve source-system timestamps for incremental extraction.
- Support both valid and deliberately defective synthetic test data.
- Avoid reproducing proprietary vendor schemas or terminology unnecessarily.
- Use fully synthetic patient and clinical records only.

## Relationship to national reporting datasets

A local PAS is an operational system used to manage patient administration and hospital activity.

National secondary-use datasets such as admitted patient care extracts are derived from local PAS and clinical systems but do not necessarily match their physical source schemas.

The simplified Aegis flow is:

```text
Local PAS operational tables
        │
        ▼
SSIS extraction and validation
        │
        ▼
Migration and staging structures
        │
        ▼
HES/APC-style reporting extract
        │
        ▼
Warehouse, SSRS and SSAS
```

Aegis therefore models normalised operational PAS entities first and derives flattened reporting structures later.

## Initial scope

The first PAS release focuses on admitted patient care.

The initial operational domains are:

- Patient demographics
- Hospital admissions
- Consultant episodes
- Diagnoses
- Procedures
- Ward stays
- Organisations
- Hospital sites
- Wards
- Consultants
- Specialties
- Local and national reference codes

Outpatient and emergency-care domains will be added after the admitted patient model is operational.

## Planned source schemas

### `pas`

Contains synthetic operational PAS transaction and master data.

### `ref`

Contains source-system reference and lookup data.

### `epr`

Reserved for later clinical EPR domains such as observations, laboratory results, medications and allergies.

## Core entity model

```text
pas.Patient
    │
    └── pas.Admission
            │
            ├── pas.ConsultantEpisode
            │       │
            │       ├── pas.Diagnosis
            │       └── pas.Procedure
            │
            └── pas.WardStay
```

Reference relationships include:

```text
ref.Organisation
    └── ref.Site
            └── ref.Ward

ref.Specialty
ref.Consultant
ref.CodeValue
```

## Table grain

### `pas.Patient`

One row per local hospital patient record.

The patient record represents the identity held by the simulated PAS and is identified primarily by a local hospital number.

A patient may have zero, one or many admissions.

### `pas.Admission`

One row per hospital admission or provider spell.

An admission represents a continuous period of admitted care from admission to discharge.

A patient may have multiple admissions over time.

### `pas.ConsultantEpisode`

One row per period of care under a consultant within an admission.

One admission may contain multiple consultant episodes.

Episode sequence determines the order in which consultant responsibility changed during the admission.

### `pas.Diagnosis`

One row per diagnosis recorded against a consultant episode.

An episode may have:

- One primary diagnosis
- Zero or more secondary diagnoses
- Local or national code values
- Incomplete or invalid source coding for migration testing

### `pas.Procedure`

One row per procedure recorded against a consultant episode.

An episode may contain:

- A primary procedure
- Additional procedures
- Procedure dates
- Local or national procedure codes
- Incomplete or invalid source coding for migration testing

### `pas.WardStay`

One row per continuous ward occupancy interval during an admission.

A patient may move between several wards during one admission.

Ward stays support:

- Patient-flow analysis
- Transfer validation
- Length-of-stay calculations
- Bed occupancy reporting
- Chronological consistency checks

## Patient identity

The principal PAS patient identifier is:

```text
HospitalNumber
```

This represents the local medical-record or hospital number assigned by the fictional provider.

The source model may also contain:

- NHS number
- NHS number status
- Previous hospital numbers
- Source-system internal keys
- Demographic matching attributes

### Synthetic NHS numbers

Aegis must not generate random modulus-11-valid NHS numbers that could theoretically correspond to real individuals.

For public synthetic data:

- `HospitalNumber` will use an Aegis-specific format such as `AEG0000001`.
- `NhsNumber` may be `NULL`.
- Deliberately invalid NHS-like values may be used for validation tests.
- Invalid test values must be clearly marked through a status field.
- Aegis must never describe its generated identifiers as real NHS numbers.

NHS-number validation will be implemented in the staging or validation layer rather than through strict source-table constraints.

## Local and national clinical codes

Legacy PAS and EPR systems frequently contain a mixture of:

- National codes
- Local provider codes
- Vendor-specific codes
- Historic codes
- Free-text descriptions
- Incomplete or unmapped values

Aegis will preserve this pattern.

The source model may therefore store:

```text
LocalCode
NationalCode
CodeSystem
CodeDescription
MappingStatus
```

The staging and conformance layers will map these to governed reference values where possible.

## SNOMED CT considerations

SNOMED CT adoption does not eliminate all local coding.

Local codes may remain in operational systems because:

- Historic records predate current standards.
- Local workflows require provider-specific values.
- Interface feeds use different terminologies.
- Administrative PAS data is not entirely clinical terminology.
- ICD-10, OPCS and other national classifications remain relevant for reporting.
- Some values require local-to-national mapping.
- Legacy migrations expose obsolete or unsupported codes.

Aegis will therefore demonstrate:

- Preservation of original source codes
- Mapping from local to national codes
- Identification of unmapped values
- Recording of mapping status and provenance
- Separation between source values and conformed values

## Initial table catalogue

| Schema | Table | Grain | Purpose |
|---|---|---|---|
| `pas` | `Patient` | One row per local patient | Patient demographics and local identifiers |
| `pas` | `Admission` | One row per admitted spell | Admission and discharge information |
| `pas` | `ConsultantEpisode` | One row per consultant period | Episode chronology and specialty responsibility |
| `pas` | `Diagnosis` | One row per episode diagnosis | Primary and secondary diagnosis coding |
| `pas` | `Procedure` | One row per episode procedure | Procedure coding and dates |
| `pas` | `WardStay` | One row per ward interval | Ward movement and occupancy |
| `ref` | `Organisation` | One row per organisation | Provider, commissioner and practice references |
| `ref` | `Site` | One row per hospital site | Physical treatment sites |
| `ref` | `Ward` | One row per ward | Hospital ward reference data |
| `ref` | `Specialty` | One row per specialty code | Main and treatment specialties |
| `ref` | `Consultant` | One row per consultant | Consultant reference data |
| `ref` | `CodeValue` | One row per source code | Local and national reference mappings |

## Proposed keys

### Surrogate source keys

Each source table will normally contain an integer identity key for internal relationships.

Examples:

```text
PatientId
AdmissionId
ConsultantEpisodeId
DiagnosisId
ProcedureId
WardStayId
```

### Business identifiers

Operational business identifiers will also be preserved.

Examples:

```text
HospitalNumber
AdmissionNumber
EpisodeNumber
PatientPathwayId
SourceDiagnosisId
SourceProcedureId
```

The migration process must not rely exclusively on generated identity values where a meaningful source identifier exists.

## Source audit columns

Most PAS source tables will include:

```text
RecordCreatedAt
RecordUpdatedAt
IsDeleted
```

These support:

- Incremental extraction
- Soft deletion
- Change detection
- Data lineage
- Migration replay
- Reconciliation

Additional source metadata may include:

```text
SourceSystemCode
SourceRecordId
ExtractedAt
MigrationBatchId
```

These fields may be introduced in staging rather than the operational source where appropriate.

## Source permissiveness

Aegis intentionally allows some invalid or incomplete data into the simulated PAS.

Examples include:

- Missing NHS number
- Invalid NHS-number checksum
- Missing date of birth
- Unknown sex code
- Invalid local specialty code
- Discharge before admission
- Episode outside the admission period
- Overlapping consultant episodes
- Ward stay outside the admission period
- Duplicate hospital numbers
- Missing primary diagnosis
- Invalid diagnosis or procedure code
- Unknown consultant
- Inconsistent organisation or site

Not every defect will be allowed through a physical database constraint.

The source database represents a legacy operational environment. Validation and quarantine logic belongs primarily in:

- `Aegis_Staging`
- `Aegis_Audit`
- SSIS validation packages
- Migration reconciliation processes

## Initial relationships

The expected cardinalities are:

```text
pas.Patient
    1 ──── 0..n pas.Admission

pas.Admission
    1 ──── 1..n pas.ConsultantEpisode

pas.Admission
    1 ──── 0..n pas.WardStay

pas.ConsultantEpisode
    1 ──── 0..n pas.Diagnosis

pas.ConsultantEpisode
    1 ──── 0..n pas.Procedure
```

Reference relationships will link admissions, episodes and ward stays to organisation, site, ward, consultant and specialty records.

## Admitted patient chronology

A valid admitted patient journey should normally satisfy:

```text
AdmissionDateTime
    <= EpisodeStartDateTime
    <= EpisodeEndDateTime
    <= DischargeDateTime
```

For multiple episodes:

```text
Episode 1 end
    <= Episode 2 start
    <= Episode 2 end
```

Ward stays should normally fall inside the admission period and should not overlap for the same admission.

These rules will be validated downstream rather than relying solely on source constraints.

## HES/APC-style derivation

The relational PAS model will later produce an admitted-patient extract containing concepts such as:

| Reporting concept | Aegis source |
|---|---|
| Admission date | `pas.Admission.AdmissionDateTime` |
| Discharge date | `pas.Admission.DischargeDateTime` |
| Episode start | `pas.ConsultantEpisode.EpisodeStartDateTime` |
| Episode end | `pas.ConsultantEpisode.EpisodeEndDateTime` |
| Episode order | `pas.ConsultantEpisode.EpisodeSequence` |
| Main specialty | Consultant or episode specialty |
| Treatment specialty | Episode treatment specialty |
| Primary diagnosis | Diagnosis sequence 1 or primary flag |
| Secondary diagnoses | Additional diagnosis rows |
| Primary procedure | Procedure sequence 1 or primary flag |
| Additional procedures | Additional procedure rows |
| Provider code | `ref.Organisation` |
| Treatment site | `ref.Site` |
| Patient pathway | Admission or pathway identifier |

Repeated diagnosis and procedure rows may be pivoted into a reporting extract when required.

## Outpatient and emergency-care extensions

Later PAS phases may introduce:

```text
pas.Referral
pas.PatientPathway
pas.OutpatientAppointment
pas.OutpatientAttendance
pas.EmergencyAttendance
pas.EmergencyDiagnosis
pas.EmergencyTreatment
```

These will be designed after the admitted patient model, SSIS foundation and reconciliation process are operational.

## Future EPR domains

The `epr` schema is reserved for later clinical domains such as:

```text
epr.Observation
epr.LaboratoryResult
epr.ImagingResult
epr.Medication
epr.Allergy
epr.Condition
epr.ClinicalDocument
```

EPR tables will preserve both local and national coding where appropriate.

They may be populated through:

- FHIR JSON
- HL7 v2 ORU messages
- Synthetic relational extracts
- Clinical-result files

## Immediate implementation order

The planned PAS implementation order is:

1. `pas.Patient`
2. `ref.Organisation`
3. `ref.Site`
4. `ref.Specialty`
5. `ref.Consultant`
6. `ref.Ward`
7. `pas.Admission`
8. `pas.ConsultantEpisode`
9. `pas.Diagnosis`
10. `pas.Procedure`
11. `pas.WardStay`
12. `ref.CodeValue`

This order establishes reference data and parent entities before dependent transaction tables.

## Current implementation status

Implemented:

- Schemas `pas`, `epr` and `ref`
- `pas.Patient`
- SQL database project
- DACPAC build
- Local deployment
- Foundation validation script

Planned next:

- Reference tables
- Admission and consultant-episode tables
- Diagnosis, procedure and ward-stay tables
- Synthetic patient-journey generator
- Admitted-patient validation rules
- HES/APC-style extract
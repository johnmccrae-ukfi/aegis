# Synthetic Data Generation and Safety Rules

## Document purpose

This document defines the mandatory rules for generating, storing, validating and publishing synthetic data within the Aegis Clinical Data Platform.

Aegis models an NHS-style PAS and EPR migration scenario. The project therefore requires realistic healthcare structures and data-quality behaviours while ensuring that no real, pseudonymised or re-identifiable patient information enters the repository.

These rules apply to:

- SQL seed scripts;
- Python data generators;
- CSV and JSON files;
- HL7 v2 messages;
- FHIR resources;
- screenshots;
- test outputs;
- reconciliation extracts;
- SSIS package test data;
- SSRS and Power BI demonstration datasets.

---

## Core data-governance principle

Only fully synthetic data may be committed to the public Aegis GitHub repository.

The following data must never be committed:

- real patient data;
- pseudonymised patient data;
- anonymised records derived from real individuals;
- copied production extracts;
- copied HL7 messages;
- copied FHIR resources;
- copied NHS numbers;
- real staff identifiers;
- credentials or connection strings;
- screenshots containing identifiable information.

Private reference material may be retained locally only under:

```text
data/private
```

The `data/private` directory must remain excluded through `.gitignore`.

---

## Synthetic-data definition

For Aegis, fully synthetic data means data that:

- is generated independently of real patient records;
- does not preserve a real individual’s combination of attributes;
- does not reproduce a real patient journey;
- does not derive dates, diagnoses, addresses or identifiers from production data;
- is created solely for software development, testing and demonstration;
- is clearly identifiable as synthetic through naming, identifiers or documentation.

Replacing names in a real record is not sufficient.

Changing only a small number of fields in a real record is not sufficient.

Aggregating or pseudonymising real records is not sufficient for inclusion in the public repository.

---

## Generation objectives

Synthetic data should be realistic enough to test:

- patient identity;
- multiple patient identifiers;
- admitted-patient journeys;
- consultant episodes;
- diagnoses;
- procedures;
- ward transfers;
- patient merges;
- duplicate identifiers;
- incomplete historic values;
- invalid event sequences;
- referential failures;
- source-to-target reconciliation;
- SSIS validation and quarantine;
- HL7 ADT processing;
- statutory-style extract generation.

Realism must not compromise safety.

---

## Deterministic generation

The Python generator must use an explicit random seed.

The seed should be stored in configuration or source code and documented.

Example:

```python
RANDOM_SEED = 20260725
```

Using a fixed seed ensures that:

- generated records are repeatable;
- validation counts remain stable;
- reconciliation results can be reproduced;
- defects can be investigated consistently;
- Git changes are reviewable;
- interview demonstrations produce known results.

Changing the random seed must be treated as a deliberate project change.

---

## Synthetic patient identifiers

### Hospital numbers

Hospital numbers must use an obviously synthetic Aegis pattern.

Recommended format:

```text
AEG0000001
AEG0000002
AEG0000003
```

Historic or alternate hospital numbers may use patterns such as:

```text
OLD0000001
ALT0000001
MIG0000001
```

Hospital numbers must not be copied from real systems.

### NHS-number-like values

Aegis must not generate mathematically valid random NHS numbers that might correspond to real people.

Synthetic NHS-number-like values must deliberately fail the NHS number modulus validation or use a clearly non-production pattern.

Recommended storage values include:

```text
9990000001
9990000002
9990000003
```

The generator must verify that any ten-digit NHS-number-like value used in public data fails the NHS number checksum.

The generator must not:

- download NHS numbers;
- copy values from screenshots or documents;
- generate random valid checksum numbers;
- use known test patients from real organisations;
- infer values from public datasets.

The `NhsNumberStatusCode` field should clearly describe the synthetic or invalid status where appropriate.

Example values:

```text
SYNTHETIC
INVALID
NOT_PRESENT
NOT_VERIFIED
```

### Other identifiers

Other patient identifiers may include:

- local hospital number;
- historic hospital number;
- migration identifier;
- source-system identifier;
- external-system identifier.

Each identifier must have:

- a synthetic value;
- an identifier type;
- an assigning authority where appropriate;
- effective dates where available;
- a current-status indicator where available.

---

## Synthetic names

Names must be generated independently.

The generator may use:

- a controlled list of fictional forenames;
- a controlled list of fictional surnames;
- generated combinations;
- clearly artificial naming patterns.

Names must not be copied from:

- production databases;
- private extracts;
- clinical messages;
- staff directories;
- real patient lists.

The generator should avoid producing a large number of recognisable public figures or repeated famous names.

Test-specific patients may use explicit synthetic names such as:

```text
Aegis Valid Patient
Aegis Duplicate Patient
Aegis Merge Survivor
Aegis Merge Superseded
```

These names are useful for controlled defect scenarios but should not replace the broader generated population.

---

## Dates of birth and death

Dates of birth must be generated within plausible age ranges.

The generator should include representative groups such as:

- children;
- working-age adults;
- older adults;
- very elderly patients.

Dates of death may be present for a controlled subset of patients.

For valid records:

```text
DateOfDeath >= DateOfBirth
```

Deliberately invalid date relationships may be created only in the controlled defect dataset.

Dates must not be copied from real records.

---

## Addresses and postcodes

Addresses must be fictional.

Recommended patterns include:

```text
1 Aegis Street
2 Migration Avenue
3 Validation Close
```

Postcodes should use clearly synthetic or reserved-style patterns where possible.

They must not be copied from real patient records.

The generator may create structurally plausible postcode-like values for testing field lengths and transformations, but documentation must make clear that they are synthetic.

---

## General-practice and organisation codes

Registered GP and practice codes must be synthetic unless an explicitly safe fictional reference list is used.

Recommended patterns include:

```text
GP0001
GP0002
PRAC001
PRAC002
```

Organisation and site names should be fictional.

Example values:

```text
Aegis University Hospitals NHS Trust
Aegis General Hospital
North Aegis Community Hospital
```

The project should avoid implying that a real NHS organisation uses the Aegis architecture or data.

---

## Clinician and consultant data

Consultant names and identifiers must be synthetic.

Recommended identifier patterns include:

```text
CONS0001
CONS0002
```

Do not use real GMC numbers.

Do not copy staff names from NHS websites, directories or private reference material.

---

## Clinical and activity codes

Clinical codes may be structurally representative where necessary for testing.

The generator may use:

- synthetic diagnosis codes;
- synthetic procedure codes;
- a small documented set of publicly defined classification examples;
- fictional local codes.

Where real coding classifications are referenced, Aegis must not claim clinical completeness or coding validity beyond the intended demonstration.

Clinical descriptions must remain generic and synthetic.

---

## Valid patient journeys

The core valid dataset should contain internally consistent journeys.

A valid admitted-patient journey should generally follow:

```text
Patient
    ↓
Patient identifiers
    ↓
Admission
    ↓
One or more consultant episodes
    ↓
Diagnoses and procedures
    ↓
One or more ward stays
    ↓
Discharge or open admission
```

For valid journeys:

- every admission must reference an existing patient;
- every consultant episode must reference an existing admission;
- every diagnosis must reference an existing consultant episode;
- every procedure must reference an existing consultant episode;
- every ward stay must reference an existing admission;
- event dates must follow a valid chronological order;
- discharge must not precede admission;
- ward transfers must occur during the admission;
- episode dates must fall within the admission;
- procedure dates must be clinically and temporally plausible;
- current identifiers must be distinguishable from historic identifiers.

---

## Open admissions

A controlled portion of admissions should remain open.

For open admissions:

- discharge date and time should be null;
- the current ward stay should remain open;
- the final consultant episode may remain open;
- downstream reconciliation must distinguish open and discharged spells.

---

## Patient merge scenarios

The generator must create controlled patient-merge cases.

Each valid merge must identify:

- surviving patient;
- superseded patient;
- surviving identifier;
- superseded identifier;
- merge date and time;
- merge reason;
- source message-control identifier where applicable;
- source-system code.

The superseded patient record must remain present in the permissive source.

The merge must not silently delete or overwrite source history.

Downstream processing must be able to:

- preserve merge lineage;
- identify the active patient;
- avoid double-counting;
- retain historic identifiers;
- reconcile pre-merge and post-merge patient totals.

---

## Deliberate source defects

Aegis must include a clearly controlled defect dataset for later validation and quarantine testing.

Permitted defect scenarios include:

- duplicate patient identifiers;
- missing identifier values;
- multiple current identifiers of the same type;
- inactive identifier marked as current;
- identifier with invalid effective dates;
- merge where surviving and superseded patients are the same;
- circular merge lineage;
- repeated merge message-control identifier;
- admission with missing discharge details;
- discharge before admission;
- consultant episode outside the admission period;
- diagnosis referencing an unknown episode;
- procedure referencing an unknown episode;
- ward stay outside the admission period;
- overlapping ward stays;
- unknown specialty;
- unknown consultant;
- unknown ward;
- date of death before date of birth;
- missing mandatory patient name;
- invalid or truncated code values.

Defects must be:

- intentional;
- documented;
- counted;
- deterministic;
- traceable to a named scenario;
- separated logically from valid generated records.

---

## Defect-labelling convention

Each controlled defect should have a stable scenario code.

Recommended format:

```text
DQ-PAT-001
DQ-ID-001
DQ-MERGE-001
DQ-ADM-001
DQ-EPISODE-001
DQ-WARD-001
```

A supporting manifest should record:

| Attribute | Purpose |
|---|---|
| ScenarioCode | Stable defect identifier |
| Domain | Patient, identifier, merge, admission or activity |
| Description | Expected defect |
| ExpectedOutcome | Reject, quarantine, warning or accepted legacy condition |
| ExpectedCount | Number of generated occurrences |
| SourceObject | Source table or file |
| ValidationRule | Future staging or SSIS rule |

This manifest may later be stored as CSV, JSON or a SQL reference table.

---

## Permissive source behaviour

`Aegis_Source` represents a synthetic legacy PAS source.

It is not:

- the migration staging layer;
- the reconciled warehouse;
- the replacement EPR;
- a FHIR validation service;
- a mastered patient index.

The source database should therefore preserve:

- local identifiers;
- historic identifiers;
- duplicate identifiers;
- superseded patient records;
- patient merge history;
- incomplete values;
- source-system defects;
- inconsistent status values where deliberately generated.

Business validation and rejection should occur downstream in staging, SSIS or audit processing.

The source schema may enforce essential structural integrity where already designed, but it must not be made unrealistically clean.

---

## Data-volume rules

Initial data volumes should be large enough to demonstrate realistic processing without making local development slow.

Suggested initial baseline:

| Data domain | Suggested volume |
|---|---:|
| Organisations | 3–5 |
| Sites | 4–8 |
| Specialties | 10–20 |
| Consultants | 30–60 |
| Wards | 20–40 |
| Patients | 1,000–5,000 |
| Patient identifiers | 1,500–8,000 |
| Admissions | 2,000–10,000 |
| Consultant episodes | 3,000–20,000 |
| Diagnoses | 5,000–40,000 |
| Procedures | 2,000–20,000 |
| Ward stays | 3,000–20,000 |
| Patient merges | 20–100 |
| Controlled defects | 25–100 |

The first implementation may use smaller volumes while the generator is validated.

Volumes should be configurable rather than hard-coded throughout the generator.

---

## Output locations

Generated public data should be written under controlled repository paths such as:

```text
data/synthetic/reference
data/synthetic/pas
data/synthetic/hl7
data/synthetic/fhir
data/synthetic/defects
```

Temporary generator outputs should be written under:

```text
data/generated
```

Temporary or high-volume outputs may be excluded from Git where appropriate.

Private reference material must remain under:

```text
data/private
```

---

## File encoding and formats

Generated text files should use:

- UTF-8 encoding;
- consistent delimiters;
- explicit headers;
- ISO 8601 date formats;
- stable column ordering;
- documented null representations.

Recommended datetime format:

```text
YYYY-MM-DDTHH:MM:SS
```

Recommended date format:

```text
YYYY-MM-DD
```

CSV generation should quote values safely and avoid locale-dependent date formatting.

---

## Validation before publication

Before generated data is committed, the generator or validation process must confirm:

- the configured random seed is recorded;
- expected files have been generated;
- record counts match configuration;
- required identifiers use synthetic patterns;
- NHS-number-like values fail checksum validation;
- no private input path has been copied into public output;
- valid journeys pass structural checks;
- controlled defects match their manifest;
- referential integrity is understood;
- no credentials or environment-specific secrets are present;
- output encoding is UTF-8;
- generated files contain no obvious real identifiers.

A generation summary should be produced after each run.

---

## Generation summary

Each generator run should report:

- random seed;
- generation timestamp;
- configuration used;
- output location;
- row count by table or file;
- valid journey count;
- open admission count;
- merge count;
- defect count by scenario;
- validation pass or failure;
- files written.

This summary may initially be printed to the console and later written to JSON.

---

## Repository review rules

Before committing generated data:

1. Review `git status`.
2. Confirm no file from `data/private` is staged.
3. Inspect a sample from each generated file.
4. Search for credentials and connection strings.
5. Confirm identifiers follow Aegis synthetic patterns.
6. Confirm NHS-number-like values are deliberately invalid.
7. Confirm defect counts match the manifest.
8. Confirm generated `bin`, `obj`, DACPAC and virtual-environment files are not staged.
9. Commit only reviewed synthetic artefacts.

---

## Python environment rules

The Aegis Python environment must:

- use a project-specific virtual environment;
- be excluded from Git;
- use a committed `requirements.txt`;
- use reproducible dependencies;
- avoid downloading real patient datasets;
- avoid calling external services with generated patient details unless explicitly approved;
- use configuration rather than embedded secrets;
- produce deterministic results.

Recommended virtual-environment location:

```text
.venv
```

The `.venv` directory must be excluded through `.gitignore`.

---

## Safety review checklist

The following checklist must be completed before a synthetic-data release:

- [ ] All data is independently generated.
- [ ] No real or pseudonymised patient data is present.
- [ ] No private reference files are staged.
- [ ] Hospital numbers follow synthetic Aegis patterns.
- [ ] NHS-number-like values deliberately fail checksum validation.
- [ ] Staff and consultant identifiers are synthetic.
- [ ] Names and addresses are fictional.
- [ ] Dates are generated independently.
- [ ] Valid journeys pass chronological checks.
- [ ] Patient merges preserve lineage.
- [ ] Controlled defects are documented.
- [ ] Generator outputs are deterministic.
- [ ] Expected record counts are documented.
- [ ] Credentials and connection strings are absent.
- [ ] Git exclusions have been reviewed.
- [ ] Generated artefacts are safe for public publication.

---

## Implementation priority

The initial generator should be developed in this order:

1. Define generator configuration and fixed random seed.
2. Generate organisation and site reference data.
3. Generate specialties, consultants and wards.
4. Generate patients.
5. Generate patient identifiers.
6. Generate valid admissions.
7. Generate consultant episodes.
8. Generate diagnoses and procedures.
9. Generate ward stays.
10. Generate patient merges.
11. Add controlled defects.
12. Validate all generated outputs.
13. Produce a generation summary.
14. Load data into `Aegis_Source`.

---

## Document status

| Attribute | Value |
|---|---|
| Project | Aegis Clinical Data Platform |
| Document | Synthetic Data Generation and Safety Rules |
| Status | Initial Day 2 baseline |
| Repository branch | dev |
| Data classification | Public synthetic project documentation |
| Authoritative rule | Fully synthetic data only |
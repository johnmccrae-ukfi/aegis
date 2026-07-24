# Reconciliation Strategy

## Purpose

Reconciliation verifies that data has moved completely and accurately from source systems through staging and into target structures.

## Reconciliation levels

### File-level reconciliation

- Files expected
- Files received
- Files processed
- Files rejected
- File checksum where applicable

### Record-level reconciliation

- Source row count
- Staged row count
- Accepted row count
- Rejected row count
- Target row count

### Control-total reconciliation

Depending on the data domain:

- Encounter counts
- Admission counts
- Discharge counts
- Observation counts
- Distinct patient counts
- Minimum and maximum event dates
- Numeric result totals where appropriate

### Attribute-level validation

Selected fields will be compared between source and target, including:

- Patient identifier
- Encounter identifier
- Admission and discharge dates
- Encounter type
- Organisation
- Specialty
- Clinical code
- Observation value

## Reconciliation equations

For each batch:

```text
Source records = Accepted records + Rejected records
```

For accepted records:

```text
Accepted records = Target inserted + Target updated + Valid duplicates ignored
```

Any variance must be explained and recorded.

## Reconciliation status

Each control will produce one of:

- Passed
- Passed with warning
- Failed
- Not applicable

## Reporting

Reconciliation results will feed the SSRS Migration Reconciliation Report and the SSAS migration assurance subject area.
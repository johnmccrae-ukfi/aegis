# Source-to-Target Mapping

## Purpose

This document records how source fields from HL7, FHIR and legacy PAS/EPR datasets map to Aegis staging and warehouse structures.

## Mapping principles

- Preserve raw source values in staging.
- Apply transformations only through documented rules.
- Record source system and batch lineage.
- Do not silently discard invalid records.
- Route rejected records to quarantine with a reason.
- Maintain code mappings separately from transaction data.
- Make reconciliation possible at source, staging and target levels.

## Initial mapping template

| Domain | Source format | Source field | Staging field | Target field | Transformation | Validation rule |
|---|---|---|---|---|---|---|
| Patient | HL7 PID | PID-3 | PatientIdentifier | DimPatient.SourcePatientIdentifier | Trim and standardise | Required |
| Patient | HL7 PID | PID-5 | PatientNameRaw | Not persisted publicly | Synthetic data only | Required |
| Patient | FHIR Patient | identifier.value | PatientIdentifier | DimPatient.SourcePatientIdentifier | Trim and standardise | Required |
| Encounter | HL7 PV1 | PV1-2 | PatientClass | DimEncounterType.EncounterTypeCode | Reference lookup | Must exist |
| Encounter | FHIR Encounter | period.start | EncounterStartDateTime | FactEncounter.StartDateTime | ISO datetime conversion | Valid datetime |
| Admission | Legacy PAS | AdmissionDateTime | AdmissionDateTime | FactAdmission.AdmissionDateTime | Direct | Required |
| Discharge | Legacy PAS | DischargeDateTime | DischargeDateTime | FactAdmission.DischargeDateTime | Direct | Must follow admission |

## Status

Detailed mappings will be added after the synthetic source structures have been selected and profiled.
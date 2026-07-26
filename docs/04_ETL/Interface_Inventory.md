# Aegis Interface Inventory

## Document purpose

This document defines the representative system interfaces and downstream dependencies modelled by the Aegis Clinical Data Platform.

The inventory supports the fictional NHS-style PAS and EPR migration scenario by identifying:

- source and target systems;
- message or extract formats;
- business purpose;
- migration and cutover relevance;
- operational assurance requirements;
- reconciliation controls;
- implementation scope within Aegis.

Aegis does not attempt to reproduce a complete NHS interface-engine estate. It models a focused set of representative interfaces that demonstrate migration, validation, operational monitoring and cutover assurance.

---

## Scope

The interface inventory covers four connected migration workstreams:

1. Historical data migration
2. Live interface transition
3. Reporting and statutory continuity
4. Cutover and post-go-live assurance

The initial implementation prioritises:

- PAS patient identity;
- admissions, transfers and discharges;
- patient-information updates;
- patient merges;
- relational PAS extracts;
- downstream warehouse feeds;
- statutory-style reporting extracts;
- interface monitoring and reconciliation.

Clinical orders and results interfaces are included in the inventory to represent wider EPR dependencies, but only a limited representative implementation is planned.

---

## System landscape

| System code | System name | Role in Aegis |
|---|---|---|
| LEGACY_PAS | Legacy Patient Administration System | Administrative system of record during legacy operation and coexistence |
| LEGACY_EPR | Legacy Electronic Patient Record | Source or consumer of selected clinical and patient-administration data |
| TARGET_EPR | Replacement EPR/PAS | Future administrative and clinical system of record |
| LIMS | Laboratory Information Management System | Representative laboratory orders and results system |
| RIS | Radiology Information System | Representative imaging-order and reporting system |
| PACS | Picture Archiving and Communication System | Representative imaging-content and report consumer |
| AEGIS_STAGING | Aegis staging database | Receives, validates and standardises migration and interface data |
| AEGIS_AUDIT | Aegis audit database | Records batch, interface, validation, rejection and replay activity |
| AEGIS_WAREHOUSE | Aegis analytical warehouse | Stores conformed patient and activity data |
| AEGIS_REPORTING | Aegis reporting database and semantic layer | Supports operational, migration and assurance reporting |
| REGIONAL_PLATFORM | Regional data consumer | Represents shared-care, population-health or approved regional use |
| STATUTORY_CONSUMER | Statutory reporting consumer | Represents admitted-patient and other mandated submissions |

---

## Interface inventory

| Interface code | Interface name | Source | Consumer | Direction | Format | Scope | Aegis implementation |
|---|---|---|---|---|---|---|---|
| IF-001 | Patient ADT | LEGACY_PAS | TARGET_EPR | Outbound | HL7 v2 | A01, A02, A03, A08 and A40 | Implemented as representative synthetic HL7 messages |
| IF-002 | Patient ADT downstream feed | LEGACY_PAS or TARGET_EPR | LEGACY_EPR and downstream clinical systems | Outbound | HL7 v2 | Patient demographics and encounter updates | Represented through interface metadata and selected message files |
| IF-003 | Laboratory orders | TARGET_EPR | LIMS | Outbound | HL7 ORM | Laboratory-order requests | Inventory and metadata only in the initial scope |
| IF-004 | Laboratory results | LIMS | TARGET_EPR | Inbound | HL7 ORU | Laboratory-result observations | One representative later implementation may be added |
| IF-005 | Imaging orders | TARGET_EPR | RIS | Outbound | HL7 ORM | Imaging-order requests | Inventory and metadata only |
| IF-006 | Imaging results | RIS or PACS | TARGET_EPR | Inbound | HL7 ORU | Imaging reports and result status | Inventory and metadata only |
| IF-007 | PAS relational extract | LEGACY_PAS | AEGIS_STAGING | Inbound | SQL or delimited extract | Patient, identifiers, merges, admissions and activity | Implemented through SQL Server and SSIS |
| IF-008 | EPR relational extract | LEGACY_EPR | AEGIS_STAGING | Inbound | SQL, CSV or JSON | Selected clinical and operational records | Limited representative implementation |
| IF-009 | Warehouse load | AEGIS_STAGING | AEGIS_WAREHOUSE | Internal | SQL Server and SSIS | Validated conformed dimensions and facts | Planned core implementation |
| IF-010 | APC-style extract | AEGIS_WAREHOUSE | STATUTORY_CONSUMER | Outbound | Delimited file | Admitted-patient episodes | Planned representative implementation |
| IF-011 | Operational reporting feed | AEGIS_WAREHOUSE | AEGIS_REPORTING | Internal | SQL Server | Migration, quality, activity and assurance datasets | Planned core implementation |
| IF-012 | Regional patient-activity feed | AEGIS_WAREHOUSE or TARGET_EPR | REGIONAL_PLATFORM | Outbound | Extract or API | Governed patient and encounter activity | Represented through metadata and synthetic extracts |
| IF-013 | Reconciliation results | AEGIS_STAGING and AEGIS_WAREHOUSE | AEGIS_AUDIT | Internal | SQL Server | Source-to-target counts and attribute comparisons | Planned core implementation |
| IF-014 | Interface audit feed | All implemented interfaces | AEGIS_AUDIT | Internal | SQL Server | Message status, latency, errors and replay state | Planned core implementation |

---

## HL7 ADT scope

The initial HL7 implementation will focus on the following events.

| Message type | Trigger event | Business meaning | Aegis use |
|---|---|---|---|
| ADT | A01 | Patient admission | Create or update an admitted-patient encounter |
| ADT | A02 | Patient transfer | Record a change of ward or care location |
| ADT | A03 | Patient discharge | Close an admitted-patient encounter |
| ADT | A08 | Patient information update | Update patient or encounter details |
| ADT | A40 | Patient identifier merge | Record surviving and superseded patient identities |

The implementation is intentionally selective. It demonstrates message receipt, parsing, validation, audit, rejection and replay without attempting to support every HL7 v2 segment, field or trigger event.

---

## Patient identity and merge requirements

Patient identity is a first-class migration domain.

The following principles apply:

- A patient may have multiple identifiers.
- Local hospital identifiers must be preserved.
- Historic identifiers must remain available for migration tracing.
- Identifier values may be duplicated or incomplete in the permissive source.
- Patient merges must retain both the surviving and superseded patient records.
- Merge lineage must be preserved.
- Superseded patients must not be double-counted in downstream reporting.
- A40 processing must be auditable.
- Duplicate message-control identifiers must be detectable.
- Invalid or circular merges must be routed for investigation rather than silently corrected.

The source structures supporting these requirements are:

- `pas.Patient`
- `pas.PatientIdentifier`
- `pas.PatientMerge`

---

## Data ownership by migration phase

### Phase 1 — Legacy operation

| Domain | System of record |
|---|---|
| Patient demographics | LEGACY_PAS |
| Patient identifiers | LEGACY_PAS |
| Admissions and transfers | LEGACY_PAS |
| Clinical records | LEGACY_EPR |
| Operational reporting | Existing warehouse and reporting estate |

During this phase, Aegis receives extracts and messages for profiling, migration preparation and reconciliation.

### Phase 2 — Coexistence

| Domain | System of record |
|---|---|
| Patient administration | LEGACY_PAS |
| Replacement-platform migrated history | TARGET_EPR |
| Parallel interface testing | LEGACY_PAS and TARGET_EPR |
| Migration reconciliation | AEGIS_STAGING, AEGIS_AUDIT and AEGIS_WAREHOUSE |

During coexistence:

- history is migrated to the replacement platform;
- live messages are replayed or dual-fed where appropriate;
- source and target totals are reconciled;
- downstream reports are compared;
- interface failures are monitored.

### Phase 3 — Cutover

| Domain | System of record |
|---|---|
| Patient administration | TARGET_EPR |
| Clinical records | TARGET_EPR |
| Warehouse feeds | TARGET_EPR and governed downstream extracts |
| Legacy PAS | Read-only or archived |

At cutover:

- production interfaces switch to the replacement source;
- the legacy PAS stops accepting normal operational updates;
- interface volumes and failures are closely monitored;
- reporting continuity is confirmed;
- post-go-live reconciliation is performed.

---

## Interface audit requirements

The future `Aegis_Audit` database will contain an interface-message audit structure with concepts including:

| Attribute | Purpose |
|---|---|
| InterfaceMessageId | Surrogate audit identifier |
| InterfaceCode | Identifies the interface definition |
| MessageControlId | Identifies the source message |
| MessageType | Identifies the message family |
| TriggerEvent | Identifies the business event |
| SourceSystemCode | Identifies the sending system |
| TargetSystemCode | Identifies the intended consumer |
| ReceivedAt | Records message receipt time |
| ProcessedAt | Records completion time |
| ProcessingStatus | Records received, processed, rejected or replay state |
| RetryCount | Records the number of replay attempts |
| ErrorCode | Stores a structured failure code |
| ErrorDetail | Stores diagnostic information |

This structure will support operational reporting for:

- messages received;
- messages processed;
- rejected messages;
- duplicate message-control identifiers;
- messages awaiting replay;
- processing latency;
- trigger-event volumes;
- repeated failures;
- cutover readiness.

---

## Processing-status model

The initial status model will use the following conceptual states.

| Status | Meaning |
|---|---|
| RECEIVED | Message or extract has been received but not yet processed |
| PROCESSING | Processing has started |
| PROCESSED | Processing completed successfully |
| REJECTED | Validation or processing failed |
| QUARANTINED | Record requires investigation before replay |
| REPLAY_PENDING | Record has been approved for another attempt |
| REPLAYED | Record has been processed through the replay mechanism |
| DUPLICATE | Message-control identifier or business event has already been processed |
| CANCELLED | Processing was intentionally stopped |

Exact implementation values will be defined when the audit database is created.

---

## Reconciliation requirements

Interface and migration reconciliation will compare:

```text
Legacy PAS source
        ↓
Migration staging and replacement target
        ↓
Warehouse and reporting outputs
```

The minimum reconciliation controls are:

| Reconciliation area | Example control |
|---|---|
| Patient totals | Compare source patients with staged and warehouse patients |
| Patient merges | Compare raw patient count with active patient count after merges |
| Patient identifiers | Confirm current and historic identifiers are retained |
| Admissions | Compare open and closed admission totals |
| Consultant episodes | Compare episode counts per admission |
| Diagnoses | Compare diagnosis counts and sequence values |
| Procedures | Compare procedure counts and dates |
| Ward stays | Compare movement sequence and current location |
| Daily activity | Compare admissions, transfers and discharges by date |
| Interface messages | Compare received, processed, rejected and replayed totals |
| Statutory extract | Compare episode and activity totals before submission |
| Reporting continuity | Compare equivalent report totals before and after source transition |

All reconciliations must be repeatable and attributable to a batch, extract or interface run.

---

## Error and quarantine categories

Representative failure categories include:

| Error category | Example |
|---|---|
| Missing mandatory identifier | Patient message has no usable local identifier |
| Unknown patient | Encounter refers to a patient that does not exist |
| Duplicate identifier | Same identifier is assigned to multiple active patients |
| Invalid merge | Surviving and superseded patients are the same |
| Circular merge | Merge lineage creates a loop |
| Duplicate message | Message-control identifier has already been processed |
| Invalid event sequence | Discharge occurs before admission |
| Invalid ward movement | Transfer sequence is incomplete or contradictory |
| Referential failure | Diagnosis refers to an unknown consultant episode |
| Invalid code | Specialty, ward or organisation code is not recognised |
| Invalid date | Date of death precedes date of birth |
| Out-of-order message | An earlier business event arrives after a later one |

The permissive `Aegis_Source` database may contain these defects deliberately.

The staging and interface-processing layers will:

- detect them;
- record them;
- quarantine them where necessary;
- avoid silently correcting source history;
- support controlled replay.

---

## Security and information-governance rules

Only fully synthetic data may be used in implemented interfaces or committed to GitHub.

The following rules apply:

- No real patient information may enter the repository.
- No pseudonymised patient information may enter the repository.
- Private reference material must remain under `data/private`.
- `data/private` must remain excluded through `.gitignore`.
- Generated examples must not reproduce real patient journeys.
- NHS-number-like values must not be mathematically valid numbers that could belong to real people.
- Local identifiers must be clearly synthetic.
- Synthetic dates, addresses and names must be generated independently.
- Message examples must use fictional organisations, clinicians and locations.
- Secrets, passwords and connection strings must remain outside source control.

---

## File and message conventions

Representative file names should include:

- interface code;
- extraction or message date;
- sequence or batch identifier;
- environment where appropriate.

Example pattern:

```text
IF-007_PAS_20260725_BATCH001.csv
```

Representative HL7 message-control identifiers should follow a synthetic pattern such as:

```text
AEGIS-ADT-20260725-000001
```

These values must remain synthetic and must not be copied from real healthcare messages.

---

## Operational assurance measures

Planned operational measures include:

- messages received by interface;
- messages processed successfully;
- messages rejected;
- duplicate messages;
- replay-pending messages;
- average processing latency;
- maximum processing latency;
- failures by error category;
- events by trigger type;
- activity by source and target system;
- interface completeness by business date;
- cutover readiness status.

These measures will later support SSRS and optional Power BI reporting.

---

## Implementation boundaries

Aegis will implement enough functionality to demonstrate:

- relational PAS extraction;
- SSIS ingestion;
- patient and encounter validation;
- representative ADT parsing;
- patient-merge processing;
- audit and quarantine handling;
- source-to-target reconciliation;
- warehouse loading;
- operational reporting;
- cutover assurance.

Aegis will not implement:

- a complete NHS PAS;
- a complete EPR;
- a production interface engine;
- a full LIMS;
- a full RIS or PACS;
- a national statutory submission service;
- a regional shared-care platform;
- every HL7 v2 message or segment;
- production clinical workflows.

External systems are represented through controlled synthetic messages, files, tables, metadata and audit records.

---

## Initial implementation priority

The implementation order is:

1. Create synthetic PAS reference data.
2. Create valid synthetic patient journeys.
3. Add historic and duplicate identifiers.
4. Add patient-merge scenarios.
5. Add deliberately invalid source records.
6. Build relational PAS extracts.
7. Create staging and audit databases.
8. Build SSIS ingestion and validation.
9. Add representative ADT messages.
10. Reconcile source, staging, warehouse and reporting totals.

---

## Document status

| Attribute | Value |
|---|---|
| Project | Aegis Clinical Data Platform |
| Document | Interface Inventory |
| Status | Initial Day 2 baseline |
| Repository branch | dev |
| Data classification | Public synthetic project documentation |
| Source-data rule | Fully synthetic data only |
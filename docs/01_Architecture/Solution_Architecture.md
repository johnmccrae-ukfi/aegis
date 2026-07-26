# Aegis Solution Architecture

## Overview

Aegis uses a layered SQL Server architecture to simulate the migration of legacy clinical data into a governed reporting and analytical platform.

The architecture separates source simulation, ingestion, validation, auditing, warehousing, reporting and operational resilience.

## Logical architecture

```text
Source systems
├── HL7 v2 files
├── FHIR JSON files
├── Legacy PAS tables
└── Legacy EPR extracts
        │
        ▼
Aegis_Source
        │
        ▼
SSIS ingestion
        │
        ├── Aegis_Staging
        └── Aegis_Audit
        │
        ▼
Validation and transformation
        │
        ├── Accepted records
        ├── Rejected records
        └── Reconciliation controls
        │
        ▼
Aegis_Warehouse
        │
        ├── SSAS semantic model
        ├── SSRS operational reporting
        ├── Power BI analytics
        └── Azure SQL demonstration target
```

## Database responsibilities

### Aegis_Source

Simulates legacy PAS and EPR source systems and stores structured source records used by the migration process.

### Aegis_Staging

Stores raw and lightly parsed data from HL7, FHIR and relational source feeds.

Staging tables preserve source values and support repeatable validation and transformation.

### Aegis_Audit

Stores:

- Batch execution records
- Package execution details
- Source and target counts
- Validation outcomes
- Data-quality issues
- Reconciliation results
- Operational metrics

### Aegis_Warehouse

Stores conformed dimensions and facts for clinical, operational and migration reporting.

### Aegis_Reporting

Provides optional flattened datasets, reporting views or extracts where operational SSRS requirements do not fit the dimensional warehouse directly.

## Processing principles

Each ingestion process follows the same logical pattern:

1. Register batch.
2. Validate source availability.
3. Ingest raw data.
4. Parse source format.
5. Apply structural validation.
6. Apply business validation.
7. Route rejected records.
8. Transform accepted records.
9. Load warehouse objects.
10. Reconcile source and target.
11. Record completion status.

## Deployment model

The primary implementation will run locally using SQL Server Developer Edition.

Selected database projects will also support deployment to Azure SQL Database for cloud demonstration and portability testing.

## Operational resilience

Transactional replication will provide a reporting replica of selected source or operational tables.

Log shipping will provide a disaster-recovery copy of the reporting warehouse.

These mechanisms are included to demonstrate SQL Server operational engineering as well as analytical delivery.
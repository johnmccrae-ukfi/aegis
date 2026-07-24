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
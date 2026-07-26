# Aegis

**Aegis Clinical Data Platform** is a synthetic NHS-style data migration, reporting and operational assurance platform built using the Microsoft SQL Server data platform.

The project demonstrates how traditional enterprise technologies such as SQL Server, SSIS, SSAS and SSRS can be delivered using modern engineering practices including GitHub version control, database projects, automated deployment, structured testing and cloud-compatible design.

## Project objectives

Aegis simulates the migration of patient, encounter and clinical data from legacy PAS and EPR systems into a replacement clinical platform and governed reporting warehouse.

The solution will demonstrate:

- HL7 v2 pipe-delimited ingestion
- FHIR JSON ingestion
- Legacy PAS and EPR data migration
- SQL Server data warehousing
- SSIS ETL orchestration
- Data profiling, cleansing and validation
- Source-to-target mapping
- Migration reconciliation
- SSAS semantic modelling
- SSRS operational reporting
- Power BI analytical reporting
- Transactional replication
- Log shipping and disaster recovery
- Database DevOps using GitHub and SQL projects
- Optional Azure SQL deployment for cloud demonstration

## Planned architecture

```text
Synthetic clinical source systems
        │
        ├── HL7 v2 messages
        ├── FHIR JSON resources
        └── Legacy PAS/EPR relational data
        │
        ▼
Aegis_Source
        │
        ▼
SSIS ingestion and validation
        │
        ├── Aegis_Staging
        ├── Aegis_Audit
        └── Rejected and quarantined records
        │
        ▼
Aegis_Warehouse
        │
        ├── SSAS semantic model
        ├── SSRS operational reports
        ├── Power BI analytics
        └── Azure SQL demonstration target
        │
        ├── Transactional replication
        └── Log shipping to DR
```

## Technology stack

- SQL Server Developer Edition
- SQL Server Management Studio 22
- SQL Server Database DevOps projects
- SQL Server Integration Services
- SQL Server Analysis Services
- SQL Server Reporting Services
- Visual Studio and SQL Server Data Tools
- T-SQL
- PowerShell
- Python for synthetic data generation
- GitHub
- Azure SQL Database
- Power BI

## Repository structure

```text
src/          SQL database, SSIS, SSAS and SSRS project source
data/         Synthetic source data, schemas and generators
sql/          Deployment, administration, monitoring and test scripts
docs/         Architecture, migration, reporting and operational documentation
images/       Architecture diagrams and implementation screenshots
```

## Data governance

Only fully synthetic data will be committed to this public repository.

Pseudonymised or source-reference data may be used locally to understand structures and distributions, but it will remain outside source control and will not be published.

## Delivery status

Aegis is currently in the repository and architecture foundation phase.

See:

- [Project Scope](docs/00_Project/Project_Scope.md)
- [Delivery Plan](docs/00_Project/Delivery_Plan.md)
- [Solution Architecture](docs/01_Architecture/Solution_Architecture.md)
- [Master Context](docs/00_Project/AEGIS_MASTER_CONTEXT.md)

## Related portfolio project

Aegis complements [Atlas](https://github.com/johnmccrae-ukfi/atlas), a Microsoft Fabric enterprise AI intelligence platform.

Atlas demonstrates modern cloud-native data engineering and AI architecture, while Aegis demonstrates enterprise SQL Server, clinical migration, reporting and operational resilience.


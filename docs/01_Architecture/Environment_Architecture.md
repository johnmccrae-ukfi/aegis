# Aegis Environment Architecture

## Overview

Aegis uses a local SQL Server development environment to reproduce the core technologies and operational patterns commonly found in established NHS, legal and enterprise Microsoft data estates.

The platform combines:

- SQL Server database development
- SSIS integration and orchestration
- SSAS Tabular semantic modelling
- SSRS operational reporting
- SQL Server Agent scheduling
- Transactional replication
- Log shipping and disaster recovery
- GitHub source control
- SQL Server Database DevOps projects
- Optional Azure SQL deployment

The primary development environment runs locally on a single Windows workstation using SQL Server 2022 Developer Edition.

This approach provides the full SQL Server feature set required for Aegis while keeping the solution free to develop and suitable for repeatable demonstrations.

## Development workstation

```text
Machine name: DESKTOP-N58JDOH
Operating model: Local development workstation
Primary repository: F:\ukfi\Development\Aegis\aegis
GitHub repository: Aegis
Primary branch: dev
Release branch: main
```

## Installed SQL Server platform

The local platform currently includes:

- SQL Server 2022 Developer Edition
- SQL Server Database Engine
- SQL Server Agent
- SQL Server Replication
- SQL Server Integration Services 16.0
- SQL Server Analysis Services 16.0 in Tabular mode
- SQL Server Reporting Services 2022 Developer Edition
- SQL Server Browser
- SQL Server Azure Extension
- SQL Server Management Studio 22
- Visual Studio 2022
- SQL Server Data Tools and BI project extensions

## Current local topology

```text
DESKTOP-N58JDOH
│
├── SQL Server Database Engine
│   └── Default instance: MSSQLSERVER
│
├── SQL Server Agent
│   └── Default instance: MSSQLSERVER
│
├── SQL Server Integration Services
│   ├── Service version: 16.0
│   └── SSIS Catalog: SSISDB
│       └── Folder: Aegis
│
├── SQL Server Analysis Services
│   ├── Default instance: MSSQLSERVER
│   └── Server mode: Tabular
│
├── SQL Server Reporting Services
│   ├── Instance name: SSRS
│   ├── Web service endpoint: /ReportServer
│   └── Web portal endpoint: /Reports
│
└── Azure Extension for SQL Server
    └── Connected to Azure resource group: rg-aegis-dev
```

## SQL Server Database Engine

The default SQL Server instance will initially host the core Aegis databases:

```text
DESKTOP-N58JDOH
├── Aegis_Source
├── Aegis_Staging
├── Aegis_Audit
├── Aegis_Warehouse
└── Aegis_Reporting
```

### Database responsibilities

#### Aegis_Source

Simulates legacy PAS and EPR source systems and stores structured synthetic clinical and operational records.

#### Aegis_Staging

Stores raw and lightly parsed data from:

- HL7 v2 files
- FHIR JSON resources
- Legacy PAS extracts
- Legacy EPR extracts
- Reference datasets

#### Aegis_Audit

Stores:

- Batch execution records
- Package execution records
- Validation results
- Rejected records
- Reconciliation controls
- Data-quality issues
- Operational metrics

#### Aegis_Warehouse

Stores conformed dimensions and facts for clinical, operational and migration reporting.

#### Aegis_Reporting

Provides operational reporting views, flattened datasets and report-specific structures where required.

## SQL Server Integration Services

SSIS is installed and operational.

The modern project deployment model will be used.

```text
Visual Studio SSIS project
        │
        ▼
Build .ispac
        │
        ▼
Deploy to SSISDB
        │
        ▼
SSISDB
└── Aegis
    ├── Projects
    └── Environments
```

The existing `SSISDB` catalog is retained and contains an `Aegis` folder dedicated to this project.

Aegis SSIS projects will use:

- Project parameters
- Package parameters
- SSIS environments
- Environment references
- SQL Server Agent execution
- SSISDB logging and execution history

Credentials and environment-specific connection details must not be committed to GitHub.

## SQL Server Analysis Services

SSAS is installed in Tabular mode and is available through the local default instance.

The Aegis semantic model will provide:

- Governed measures
- Conformed relationships
- Clinical activity analysis
- Migration assurance measures
- Data-quality analysis
- Patient-flow analysis
- Reusable reporting metrics

The SSAS project source will be stored under:

```text
src/ssas/Aegis.SemanticModel
```

The deployed model will initially use `Aegis_Warehouse` and selected `Aegis_Reporting` objects as data sources.

## SQL Server Reporting Services

SSRS 2022 Developer Edition is installed and configured as the named instance:

```text
DESKTOP-N58JDOH\SSRS
```

The configured endpoints are:

```text
Web service:
http://localhost/ReportServer
http://DESKTOP-N58JDOH/ReportServer

Web portal:
http://localhost/Reports
http://DESKTOP-N58JDOH/Reports
```

The SSRS project source will be stored under:

```text
src/ssrs/Aegis.Reports
```

Initial planned reports include:

- Migration Reconciliation Report
- Data Quality Exception Report
- Patient Journey Report
- Daily Operational Readiness Report

SSRS will be used primarily for detailed, parameterised, printable and auditable operational reporting.

## Visual Studio and SQL Server Data Tools

Visual Studio 2022 is installed with the required Microsoft BI extensions:

- SQL Server Integration Services Projects 2022+
- Microsoft Analysis Services Projects
- Microsoft Reporting Services Projects

Visual Studio will be used where graphical designers or project-specific deployment tooling are required.

Primary Visual Studio responsibilities:

- SSIS package development
- SSAS Tabular model development
- SSRS report development
- BI project build and deployment

## Visual Studio Code

Visual Studio Code remains the primary development environment for:

- Git operations
- Markdown documentation
- T-SQL scripts
- PowerShell scripts
- Python synthetic-data generation
- Repository management
- Test scripts
- Configuration templates
- Architecture documentation

Aegis will not reuse the Atlas Python virtual environment.

A dedicated Aegis virtual environment will be created later when Python-based synthetic data generation begins.

## SQL Server Management Studio 22

SSMS 22 is used for:

- Database administration
- T-SQL development
- SQL Server Agent
- SSISDB management
- SSAS connectivity
- SSRS connectivity
- Replication administration
- Log shipping configuration
- Performance monitoring
- Database deployment validation
- SQL Server migration assessment

The SSMS Database DevOps public preview will be evaluated for creating and managing SQL database projects within the Aegis repository.

## Azure integration

The local SQL Server instance is connected to Azure through the Azure Extension for SQL Server.

The Aegis development resource group is:

```text
rg-aegis-dev
```

The Azure environment will be used later for:

- SQL Server migration assessment
- Azure SQL compatibility review
- Azure SQL Database deployment
- Cloud demonstration access
- Remote interview demonstrations
- Environment comparison documentation

The local SQL Server environment remains the primary platform because Azure SQL Database does not reproduce the full SSIS, SSAS, SSRS, replication and log-shipping feature set.

## Source-control model

```text
GitHub repository
        │
        ├── main
        │     └── Stable and released code
        │
        └── dev
              └── Active development
```

Feature branches may be used for larger isolated changes.

The standard workflow is:

```text
Local development
        │
        ▼
Commit to dev
        │
        ▼
Push to origin/dev
        │
        ▼
Pull request
        │
        ▼
Merge to main
        │
        ▼
Create release tag
        │
        ▼
Synchronise dev with main
```

## Planned secondary SQL Server instance

A second local Database Engine instance will be introduced during the high-availability and disaster-recovery phase.

Proposed instance name:

```text
DESKTOP-N58JDOH\AEGISSECONDARY
```

Planned responsibilities:

```text
AEGISSECONDARY
├── Aegis_Source_ReportingReplica
└── Aegis_Warehouse_DR
```

The secondary instance will support:

- Transactional replication subscriber
- Log-shipping secondary database
- Replication latency monitoring
- Disaster-recovery testing
- Controlled failover exercises

Using one secondary instance for both portfolio exercises is acceptable for local development, although a production design would normally separate reporting and disaster-recovery responsibilities.

## Planned replication topology

```text
DESKTOP-N58JDOH
Default SQL Server instance
Publisher and Distributor
        │
        ▼
DESKTOP-N58JDOH\AEGISSECONDARY
Subscriber
        │
        └── Aegis_Source_ReportingReplica
```

Transactional replication will be used to:

- Offload selected reporting or extraction workloads
- Demonstrate near-real-time data distribution
- Monitor replication latency
- Validate subscriber consistency
- Practise publisher, distributor and subscriber administration

## Planned log-shipping topology

```text
DESKTOP-N58JDOH
Aegis_Warehouse primary
        │
        ├── Transaction-log backup
        ├── File copy
        └── Restore
                │
                ▼
DESKTOP-N58JDOH\AEGISSECONDARY
Aegis_Warehouse_DR secondary
```

The initial demonstration objectives are:

- Recovery point objective: 15 minutes or less
- Recovery time objective: 30 minutes or less

These are prototype objectives and not production NHS service commitments.

## Service configuration

During active Aegis development, the following services are configured to start automatically:

- SQL Server Database Engine
- SQL Server Agent
- SQL Server Integration Services
- SQL Server Analysis Services
- SQL Server Reporting Services
- Azure Extension for SQL Server

SQL Server Browser may remain manual until the named secondary Database Engine instance is introduced.

## Environment-specific configuration

Secrets and machine-specific values must not be committed to GitHub.

Environment configuration will use:

- Database project publish profiles
- SQLCMD variables
- SSIS project parameters
- SSIS package parameters
- SSISDB environments
- Local configuration files excluded through `.gitignore`
- Secure Azure configuration where required

Examples of values that must remain outside source control include:

- Passwords
- SSISDB encryption passwords
- SSRS encryption-key passwords
- Azure credentials
- Production-style connection strings
- Private source-data locations

## Local private storage

Any pseudonymised, real-derived or reference source data must remain in an ignored local location such as:

```text
data/private/
```

Only fully synthetic data may be committed to the public Aegis repository.

## Current environment status

| Component | Status |
|---|---|
| SQL Server Database Engine | Installed and running |
| SQL Server Agent | Installed and running |
| SQL Server Replication | Installed |
| SSIS runtime | Installed and running |
| SSISDB | Configured |
| SSISDB Aegis folder | Created |
| SSAS Tabular | Installed and connected |
| SSRS service | Installed and running |
| SSRS Web Service URL | Configured and working |
| SSRS Web Portal URL | Configured and working |
| Visual Studio BI extensions | Installed |
| SSMS 22 | Installed |
| Azure SQL extension | Connected |
| Azure resource group | Created |
| Secondary SQL instance | Deferred |
| Azure SQL demo database | Deferred |


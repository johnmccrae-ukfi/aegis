# Aegis Environment Architecture

## Initial local environment

The development environment will use local SQL Server Developer Edition named instances.

```text
AEGISDEV
├── Aegis_Source
├── Aegis_Staging
├── Aegis_Audit
├── Aegis_Warehouse
└── Aegis_Reporting

AEGISREPORT
└── Aegis_Source_ReportingReplica

AEGISDR
└── Aegis_Warehouse_DR
```

## Platform services

The local environment will include:

- SQL Server Database Engine
- SQL Server Agent
- SQL Server Integration Services
- SSIS Catalog
- SQL Server Analysis Services Tabular
- SQL Server Reporting Services
- Visual Studio with SQL Server Data Tools
- SQL Server Management Studio 22
- PowerShell
- Git

## Source-control model

```text
GitHub repository
        │
        ├── main
        └── dev
              │
              └── Feature branches where required
```

Development changes are committed to `dev` and merged to `main` through pull requests.

## Cloud demonstration environment

A later project phase will deploy selected database projects to Azure SQL Database.

The cloud target will demonstrate:

- Database portability
- DACPAC deployment
- SQLCMD variables
- Environment-specific configuration
- Remote interview demonstration
- SQL Server to Azure SQL migration assessment

## Environment configuration

Secrets and environment-specific connection values must not be committed.

Configuration will use:

- Database project publish profiles
- SQLCMD variables
- SSIS parameters and environments
- Local environment files excluded by `.gitignore`
- Secure Azure configuration where required
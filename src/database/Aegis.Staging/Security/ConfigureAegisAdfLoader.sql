/*
    Configures the database-level identity and least-privilege permissions
    required by Azure Data Factory.

    Prerequisite:
    The server-level SQL login [aegis_adf_loader] must already exist.
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE [name] = N'aegis_adf_loader'
)
BEGIN
    CREATE USER [aegis_adf_loader]
        FOR LOGIN [aegis_adf_loader];
END;
GO


/* Raw and typed landing */

GRANT SELECT
ON OBJECT::[landing].[Admission]
TO [aegis_adf_loader];
GO

GRANT INSERT
ON OBJECT::[landing].[Admission]
TO [aegis_adf_loader];
GO

GRANT SELECT
ON OBJECT::[landing].[AdmissionAdfRaw]
TO [aegis_adf_loader];
GO

GRANT INSERT
ON OBJECT::[landing].[AdmissionAdfRaw]
TO [aegis_adf_loader];
GO


/* Staging and snapshot reconciliation */

GRANT SELECT
ON OBJECT::[stg].[Admission]
TO [aegis_adf_loader];
GO

GRANT SELECT
ON OBJECT::[curated].[Admission]
TO [aegis_adf_loader];
GO

GRANT SELECT
ON OBJECT::[quarantine].[Admission]
TO [aegis_adf_loader];
GO


/* ADF processing procedures */

GRANT EXECUTE
ON OBJECT::[landing].[usp_ClearAdfAdmissionsRaw]
TO [aegis_adf_loader];
GO

GRANT EXECUTE
ON OBJECT::[landing].[usp_PromoteAdfAdmissionsRaw]
TO [aegis_adf_loader];
GO

GRANT EXECUTE
ON OBJECT::[stg].[usp_ProcessAdfAdmissions]
TO [aegis_adf_loader];
GO

GRANT EXECUTE
ON OBJECT::[curated].[usp_ActivateAdfAdmissionsSnapshot]
TO [aegis_adf_loader];
GO
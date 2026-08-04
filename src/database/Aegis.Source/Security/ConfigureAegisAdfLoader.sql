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

GRANT SELECT
ON OBJECT::[pas].[Patient]
TO [aegis_adf_loader];
GO

GRANT SELECT
ON OBJECT::[ref].[Organisation]
TO [aegis_adf_loader];
GO

GRANT SELECT
ON OBJECT::[ref].[Site]
TO [aegis_adf_loader];
GO
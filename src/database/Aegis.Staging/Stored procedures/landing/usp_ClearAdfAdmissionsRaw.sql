CREATE PROCEDURE [landing].[usp_ClearAdfAdmissionsRaw]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM [landing].[AdmissionAdfRaw];

        DECLARE @RowsDeleted BIGINT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @RowsDeleted AS [RowsDeleted],
            SYSUTCDATETIME() AS [ClearedAt];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
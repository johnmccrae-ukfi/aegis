CREATE PROCEDURE [curated].[usp_ActivateAdfAdmissionsSnapshot]
    @BatchId BIGINT,
    @PackageExecutionId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @ActivatedCuratedRowCount BIGINT,
        @ActivatedQuarantineRowCount BIGINT;

    IF @BatchId IS NULL OR @BatchId <= 0
    BEGIN
        THROW 51000, 'BatchId must be a positive value.', 1;
    END;

    IF @PackageExecutionId IS NULL OR @PackageExecutionId <= 0
    BEGIN
        THROW 51000, 'PackageExecutionId must be a positive value.', 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [curated].[Admission]
        WHERE
            [BatchId] = @BatchId
            AND [PackageExecutionId] = @PackageExecutionId
    )
    BEGIN
        THROW 51000, 'No curated Admissions were found for the supplied execution.', 1;
    END;

    /*
        This procedure may be called inside the Audit completion
        transaction. Do not start or commit a separate transaction here.
    */

    UPDATE [curated].[Admission]
    SET [IsCurrent] = 0
    WHERE [IsCurrent] = 1;

    UPDATE [quarantine].[Admission]
    SET [IsCurrent] = 0
    WHERE [IsCurrent] = 1;

    UPDATE [curated].[Admission]
    SET [IsCurrent] = 1
    WHERE
        [BatchId] = @BatchId
        AND [PackageExecutionId] = @PackageExecutionId;

    SET @ActivatedCuratedRowCount = @@ROWCOUNT;

    UPDATE [quarantine].[Admission]
    SET [IsCurrent] = 1
    WHERE
        [BatchId] = @BatchId
        AND [PackageExecutionId] = @PackageExecutionId;

    SET @ActivatedQuarantineRowCount = @@ROWCOUNT;

    SELECT
        @BatchId AS [BatchId],
        @PackageExecutionId AS [PackageExecutionId],
        @ActivatedCuratedRowCount AS [ActivatedCuratedRowCount],
        @ActivatedQuarantineRowCount AS [ActivatedQuarantineRowCount];
END;
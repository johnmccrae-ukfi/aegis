CREATE PROCEDURE [audit].[usp_CompleteAdfAdmissionsBatch]
    @PipelineRunId       NVARCHAR(100),
    @LandedRowCount      BIGINT,
    @AcceptedRowCount    BIGINT = NULL,
    @RejectedRowCount    BIGINT = NULL,
    @QuarantinedRowCount BIGINT = NULL,
    @WarningRowCount     BIGINT = NULL,
    @DuplicateRowCount   BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @ExecutionReference UNIQUEIDENTIFIER,
        @BatchId BIGINT,
        @PackageExecutionId BIGINT,
        @SourceRowCount BIGINT,
        @CuratedRowCount BIGINT,
        @QuarantineRowCount BIGINT,
        @ActivatedCuratedRowCount BIGINT,
        @ActivatedQuarantineRowCount BIGINT,
        @BatchStatus VARCHAR(30),
        @ExecutionStatus VARCHAR(30),
        @CompletedAt DATETIME2(3);

    IF NULLIF(LTRIM(RTRIM(@PipelineRunId)), N'') IS NULL
    BEGIN
        THROW 51000, 'PipelineRunId is required.', 1;
    END;

    SET @ExecutionReference =
        TRY_CONVERT
        (
            UNIQUEIDENTIFIER,
            LTRIM(RTRIM(@PipelineRunId))
        );

    IF @ExecutionReference IS NULL
    BEGIN
        THROW 51000, 'PipelineRunId must be a valid uniqueidentifier.', 1;
    END;

    IF @LandedRowCount < 0
    BEGIN
        THROW 51000, 'LandedRowCount cannot be negative.', 1;
    END;

    IF @AcceptedRowCount IS NOT NULL
       AND @AcceptedRowCount < 0
    BEGIN
        THROW 51000, 'AcceptedRowCount cannot be negative.', 1;
    END;

    IF @RejectedRowCount IS NOT NULL
       AND @RejectedRowCount < 0
    BEGIN
        THROW 51000, 'RejectedRowCount cannot be negative.', 1;
    END;

    IF @QuarantinedRowCount IS NOT NULL
       AND @QuarantinedRowCount < 0
    BEGIN
        THROW 51000, 'QuarantinedRowCount cannot be negative.', 1;
    END;

    IF @WarningRowCount IS NOT NULL
       AND @WarningRowCount < 0
    BEGIN
        THROW 51000, 'WarningRowCount cannot be negative.', 1;
    END;

    IF @DuplicateRowCount IS NOT NULL
       AND @DuplicateRowCount < 0
    BEGIN
        THROW 51000, 'DuplicateRowCount cannot be negative.', 1;
    END;

    SELECT
        @BatchId = b.[BatchId],
        @PackageExecutionId = pe.[PackageExecutionId],
        @SourceRowCount = COALESCE
        (
            pe.[SourceRowCount],
            b.[SourceRowCount]
        )
    FROM [audit].[PackageExecution] AS pe
    INNER JOIN [audit].[Batch] AS b
        ON b.[BatchId] = pe.[BatchId]
    WHERE
        pe.[ExecutionReference] = @ExecutionReference
        AND pe.[PackageName] = N'PL_Load_Admissions_From_ADLS'
        AND pe.[ExecutionStatus] = 'STARTED'
        AND b.[BatchStatus] = 'PROCESSING';

    IF @BatchId IS NULL
       OR @PackageExecutionId IS NULL
    BEGIN
        THROW 51000, 'An active ADF Admissions execution was not found for this PipelineRunId.', 1;
    END;

    IF @SourceRowCount IS NOT NULL
       AND @SourceRowCount <> @LandedRowCount
    BEGIN
        THROW 51000, 'SourceRowCount must equal LandedRowCount before the batch can complete.', 1;
    END;

    IF @AcceptedRowCount IS NOT NULL
       AND @RejectedRowCount IS NOT NULL
       AND @QuarantinedRowCount IS NOT NULL
       AND
       (
           @AcceptedRowCount
           + @RejectedRowCount
           + @QuarantinedRowCount
       ) <> @LandedRowCount
    BEGIN
        THROW 51000, 'Accepted, rejected and quarantined row counts must reconcile to LandedRowCount.', 1;
    END;

    SELECT
        @CuratedRowCount = COUNT_BIG(*)
    FROM [$(AegisStagingDatabase)].[curated].[Admission]
    WHERE
        [BatchId] = @BatchId
        AND [PackageExecutionId] = @PackageExecutionId;

    SELECT
        @QuarantineRowCount = COUNT_BIG(*)
    FROM [$(AegisStagingDatabase)].[quarantine].[Admission]
    WHERE
        [BatchId] = @BatchId
        AND [PackageExecutionId] = @PackageExecutionId;

    IF @AcceptedRowCount IS NOT NULL
       AND @CuratedRowCount <> @AcceptedRowCount
    BEGIN
        THROW 51000, 'The curated Admission row count does not match AcceptedRowCount.', 1;
    END;

    IF @QuarantinedRowCount IS NOT NULL
       AND @QuarantineRowCount <> @QuarantinedRowCount
    BEGIN
        THROW 51000, 'The quarantine Admission row count does not match QuarantinedRowCount.', 1;
    END;

    IF COALESCE(@RejectedRowCount, 0) > 0
       OR COALESCE(@QuarantinedRowCount, 0) > 0
       OR COALESCE(@WarningRowCount, 0) > 0
       OR COALESCE(@DuplicateRowCount, 0) > 0
    BEGIN
        SET @BatchStatus = 'COMPLETED_WITH_EXCEPTIONS';
        SET @ExecutionStatus = 'SUCCEEDED_WITH_EXCEPTIONS';
    END;
    ELSE
    BEGIN
        SET @BatchStatus = 'COMPLETED';
        SET @ExecutionStatus = 'SUCCEEDED';
    END;

    SET @CompletedAt = SYSUTCDATETIME();

    BEGIN TRY
        BEGIN TRANSACTION;

        /*
            Supersede the previous reporting snapshot only after the new
            execution has fully reconciled.
        */
                DECLARE @SnapshotActivation TABLE
        (
            [BatchId] BIGINT,
            [PackageExecutionId] BIGINT,
            [ActivatedCuratedRowCount] BIGINT,
            [ActivatedQuarantineRowCount] BIGINT
        );

        INSERT INTO @SnapshotActivation
        (
            [BatchId],
            [PackageExecutionId],
            [ActivatedCuratedRowCount],
            [ActivatedQuarantineRowCount]
        )
        EXEC [$(AegisStagingDatabase)]
            .[curated].[usp_ActivateAdfAdmissionsSnapshot]
                @BatchId = @BatchId,
                @PackageExecutionId = @PackageExecutionId;

        SELECT
            @ActivatedCuratedRowCount =
                [ActivatedCuratedRowCount],
            @ActivatedQuarantineRowCount =
                [ActivatedQuarantineRowCount]
        FROM @SnapshotActivation
        WHERE
            [BatchId] = @BatchId
            AND [PackageExecutionId] = @PackageExecutionId;

        IF @ActivatedCuratedRowCount IS NULL
        BEGIN
            THROW 51000, 'The curated Admissions snapshot activation returned no result.', 1;
        END;

        IF @AcceptedRowCount IS NOT NULL
           AND @ActivatedCuratedRowCount <> @AcceptedRowCount
        BEGIN
            THROW 51000, 'The expected curated Admissions snapshot could not be activated.', 1;
        END;

        IF @ActivatedQuarantineRowCount IS NULL
        BEGIN
            THROW 51000, 'The quarantine Admissions snapshot activation returned no result.', 1;
        END;

        IF @QuarantinedRowCount IS NOT NULL
           AND @ActivatedQuarantineRowCount <> @QuarantinedRowCount
        BEGIN
            THROW 51000, 'The expected quarantine Admissions snapshot could not be activated.', 1;
        END;
        

        UPDATE [audit].[Batch]
        SET
            [LandedRowCount] = @LandedRowCount,
            [AcceptedRowCount] = @AcceptedRowCount,
            [RejectedRowCount] = @RejectedRowCount,
            [QuarantinedRowCount] = @QuarantinedRowCount,
            [WarningRowCount] = @WarningRowCount,
            [DuplicateRowCount] = @DuplicateRowCount,
            [BatchStatus] = @BatchStatus,
            [CompletedAt] = @CompletedAt,
            [UpdatedAt] = @CompletedAt,
            [ErrorCode] = NULL,
            [ErrorDetail] = NULL
        WHERE
            [BatchId] = @BatchId
            AND [BatchStatus] = 'PROCESSING';

        IF @@ROWCOUNT <> 1
        BEGIN
            THROW 51000, 'The ADF Admissions batch could not be completed.', 1;
        END;

        UPDATE [audit].[PackageExecution]
        SET
            [LandedRowCount] = @LandedRowCount,
            [AcceptedRowCount] = @AcceptedRowCount,
            [RejectedRowCount] = @RejectedRowCount,
            [QuarantinedRowCount] = @QuarantinedRowCount,
            [WarningRowCount] = @WarningRowCount,
            [DuplicateRowCount] = @DuplicateRowCount,
            [ExecutionStatus] = @ExecutionStatus,
            [CompletedAt] = @CompletedAt,
            [UpdatedAt] = @CompletedAt,
            [ErrorCode] = NULL,
            [ErrorDetail] = NULL
        WHERE
            [PackageExecutionId] = @PackageExecutionId
            AND [ExecutionStatus] = 'STARTED';

        IF @@ROWCOUNT <> 1
        BEGIN
            THROW 51000, 'The ADF Admissions package execution could not be completed.', 1;
        END;

        COMMIT TRANSACTION;

        SELECT
            b.[BatchId],
            pe.[PackageExecutionId],
            b.[BatchReference],
            pe.[ExecutionReference],
            b.[BatchStatus],
            pe.[ExecutionStatus],
            b.[SourceRowCount],
            b.[LandedRowCount],
            b.[AcceptedRowCount],
            b.[RejectedRowCount],
            b.[QuarantinedRowCount],
            b.[WarningRowCount],
            b.[DuplicateRowCount],
            @ActivatedCuratedRowCount AS [ActivatedCuratedRowCount],
            @ActivatedQuarantineRowCount AS [ActivatedQuarantineRowCount],
            b.[CompletedAt]
        FROM [audit].[Batch] AS b
        INNER JOIN [audit].[PackageExecution] AS pe
            ON pe.[BatchId] = b.[BatchId]
        WHERE
            b.[BatchId] = @BatchId
            AND pe.[PackageExecutionId] = @PackageExecutionId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
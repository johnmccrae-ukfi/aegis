CREATE PROCEDURE [audit].[usp_FailAdfAdmissionsBatch]
    @PipelineRunId     NVARCHAR(100),
    @ErrorCode         VARCHAR(100) = NULL,
    @ErrorDetail       NVARCHAR(2000) = NULL,
    @FailedActivityName NVARCHAR(260) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @ExecutionReference UNIQUEIDENTIFIER,
        @BatchId BIGINT,
        @PackageExecutionId BIGINT,
        @CurrentBatchStatus VARCHAR(30),
        @CurrentExecutionStatus VARCHAR(30),
        @CompletedAt DATETIME2(3),
        @NormalisedErrorCode VARCHAR(100),
        @NormalisedErrorDetail NVARCHAR(2000);

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

    SET @NormalisedErrorCode =
        LEFT
        (
            COALESCE
            (
                NULLIF(LTRIM(RTRIM(@ErrorCode)), ''),
                'ADF_PIPELINE_FAILURE'
            ),
            100
        );

    SET @NormalisedErrorDetail =
        LEFT
        (
            CASE
                WHEN NULLIF(LTRIM(RTRIM(@FailedActivityName)), N'') IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(@ErrorDetail)), N'') IS NOT NULL
                THEN
                    CONCAT
                    (
                        N'Activity: ',
                        LTRIM(RTRIM(@FailedActivityName)),
                        N'. ',
                        LTRIM(RTRIM(@ErrorDetail))
                    )

                WHEN NULLIF(LTRIM(RTRIM(@FailedActivityName)), N'') IS NOT NULL
                THEN
                    CONCAT
                    (
                        N'Activity: ',
                        LTRIM(RTRIM(@FailedActivityName)),
                        N'. The ADF activity failed.'
                    )

                WHEN NULLIF(LTRIM(RTRIM(@ErrorDetail)), N'') IS NOT NULL
                THEN
                    LTRIM(RTRIM(@ErrorDetail))

                ELSE
                    N'The ADF Admissions pipeline failed before successful completion.'
            END,
            2000
        );

    SELECT
        @BatchId = b.[BatchId],
        @PackageExecutionId = pe.[PackageExecutionId],
        @CurrentBatchStatus = b.[BatchStatus],
        @CurrentExecutionStatus = pe.[ExecutionStatus]
    FROM [audit].[PackageExecution] AS pe
    INNER JOIN [audit].[Batch] AS b
        ON b.[BatchId] = pe.[BatchId]
    WHERE
        pe.[ExecutionReference] = @ExecutionReference
        AND pe.[PackageName] = N'PL_Load_Admissions_From_ADLS';

    IF @BatchId IS NULL
       OR @PackageExecutionId IS NULL
    BEGIN
        THROW 51000, 'An ADF Admissions execution was not found for this PipelineRunId.', 1;
    END;

    /*
        Idempotent response: preserve the first recorded failure rather than
        overwriting it when more than one ADF failure path invokes the
        procedure for the same pipeline run.
    */
    IF @CurrentBatchStatus = 'FAILED'
       AND @CurrentExecutionStatus = 'FAILED'
    BEGIN
        SELECT
            b.[BatchId],
            pe.[PackageExecutionId],
            b.[BatchReference],
            pe.[ExecutionReference],
            b.[BatchStatus],
            pe.[ExecutionStatus],
            b.[ErrorCode],
            b.[ErrorDetail],
            b.[CompletedAt]
        FROM [audit].[Batch] AS b
        INNER JOIN [audit].[PackageExecution] AS pe
            ON pe.[BatchId] = b.[BatchId]
        WHERE
            b.[BatchId] = @BatchId
            AND pe.[PackageExecutionId] = @PackageExecutionId;

        RETURN;
    END;

    IF @CurrentBatchStatus IN
       (
           'COMPLETED',
           'COMPLETED_WITH_EXCEPTIONS',
           'CANCELLED'
       )
       OR @CurrentExecutionStatus IN
       (
           'SUCCEEDED',
           'SUCCEEDED_WITH_EXCEPTIONS',
           'CANCELLED'
       )
    BEGIN
        THROW 51000, 'A completed or cancelled ADF Admissions execution cannot be marked as failed.', 1;
    END;

    IF @CurrentBatchStatus <> 'PROCESSING'
       OR @CurrentExecutionStatus <> 'STARTED'
    BEGIN
        THROW 51000, 'The ADF Admissions execution is not in an active state that can be failed.', 1;
    END;

    SET @CompletedAt = SYSUTCDATETIME();

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE [audit].[Batch]
        SET
            [BatchStatus] = 'FAILED',
            [CompletedAt] = @CompletedAt,
            [ErrorCode] = @NormalisedErrorCode,
            [ErrorDetail] = @NormalisedErrorDetail,
            [UpdatedAt] = @CompletedAt
        WHERE
            [BatchId] = @BatchId
            AND [BatchStatus] = 'PROCESSING';

        IF @@ROWCOUNT <> 1
        BEGIN
            THROW 51000, 'The ADF Admissions batch could not be marked as failed.', 1;
        END;

        UPDATE [audit].[PackageExecution]
        SET
            [ExecutionStatus] = 'FAILED',
            [CompletedAt] = @CompletedAt,
            [ErrorCode] = @NormalisedErrorCode,
            [ErrorDetail] = @NormalisedErrorDetail,
            [UpdatedAt] = @CompletedAt
        WHERE
            [PackageExecutionId] = @PackageExecutionId
            AND [ExecutionStatus] = 'STARTED';

        IF @@ROWCOUNT <> 1
        BEGIN
            THROW 51000, 'The ADF Admissions package execution could not be marked as failed.', 1;
        END;

        COMMIT TRANSACTION;

        SELECT
            b.[BatchId],
            pe.[PackageExecutionId],
            b.[BatchReference],
            pe.[ExecutionReference],
            b.[BatchStatus],
            pe.[ExecutionStatus],
            b.[ErrorCode],
            b.[ErrorDetail],
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
CREATE PROCEDURE [audit].[usp_StartAdfAdmissionsBatch]
    @PipelineRunId       NVARCHAR(100),
    @SourceFileName      NVARCHAR(260),
    @SourceFilePath      NVARCHAR(1000),
    @SourceExtractedAt   DATETIME2(3) = NULL,
    @SourceRowCount      BIGINT = NULL,
    @PackageVersion      VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @InterfaceId INT,
        @ExecutionReference UNIQUEIDENTIFIER,
        @BatchId BIGINT,
        @PackageExecutionId BIGINT;

    IF NULLIF(LTRIM(RTRIM(@PipelineRunId)), N'') IS NULL
    BEGIN
        THROW 51000, 'PipelineRunId is required.', 1;
    END;

    SET @ExecutionReference = TRY_CONVERT
    (
        UNIQUEIDENTIFIER,
        LTRIM(RTRIM(@PipelineRunId))
    );

    IF @ExecutionReference IS NULL
    BEGIN
        THROW 51000, 'PipelineRunId must be a valid uniqueidentifier.', 1;
    END;

    IF NULLIF(LTRIM(RTRIM(@SourceFileName)), N'') IS NULL
    BEGIN
        THROW 51000, 'SourceFileName is required.', 1;
    END;

    IF NULLIF(LTRIM(RTRIM(@SourceFilePath)), N'') IS NULL
    BEGIN
        THROW 51000, 'SourceFilePath is required.', 1;
    END;

    IF @SourceRowCount IS NOT NULL
       AND @SourceRowCount < 0
    BEGIN
        THROW 51000, 'SourceRowCount cannot be negative.', 1;
    END;

    SELECT
        @InterfaceId = [InterfaceId]
    FROM [audit].[Interface]
    WHERE
        [InterfaceCode] = 'PAS_ADMISSION_EXTRACT'
        AND [IsActive] = 1;

    IF @InterfaceId IS NULL
    BEGIN
        THROW 51000, 'Active interface PAS_ADMISSION_EXTRACT was not found.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [audit].[PackageExecution]
        WHERE [ExecutionReference] = @ExecutionReference
    )
    BEGIN
        THROW 51000, 'An audit execution already exists for this PipelineRunId.', 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO [audit].[Batch]
        (
            [InterfaceId],
            [SourceFileName],
            [SourceFilePath],
            [SourceExtractedAt],
            [ReceivedAt],
            [StartedAt],
            [BatchStatus],
            [IsReplay],
            [SourceRowCount]
        )
        VALUES
        (
            @InterfaceId,
            LTRIM(RTRIM(@SourceFileName)),
            LTRIM(RTRIM(@SourceFilePath)),
            @SourceExtractedAt,
            SYSUTCDATETIME(),
            SYSUTCDATETIME(),
            'PROCESSING',
            0,
            @SourceRowCount
        );

        SET @BatchId = SCOPE_IDENTITY();

        INSERT INTO [audit].[PackageExecution]
        (
            [BatchId],
            [PackageName],
            [PackageVersion],
            [ExecutionReference],
            [SsisExecutionId],
            [ExecutionStatus],
            [StartedAt],
            [SourceRowCount]
        )
        VALUES
        (
            @BatchId,
            N'PL_Load_Admissions_From_ADLS',
            NULLIF(LTRIM(RTRIM(@PackageVersion)), ''),
            @ExecutionReference,
            NULL,
            'STARTED',
            SYSUTCDATETIME(),
            @SourceRowCount
        );

        SET @PackageExecutionId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT
            @BatchId AS [BatchId],
            @PackageExecutionId AS [PackageExecutionId],
            [BatchReference],
            @ExecutionReference AS [ExecutionReference]
        FROM [audit].[Batch]
        WHERE [BatchId] = @BatchId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
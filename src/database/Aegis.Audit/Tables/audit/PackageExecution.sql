CREATE TABLE [audit].[PackageExecution]
(
    [PackageExecutionId]       BIGINT IDENTITY (1, 1) NOT NULL,
    [BatchId]                  BIGINT                 NOT NULL,
    [PackageName]              NVARCHAR(260)          NOT NULL,
    [PackageVersion]           VARCHAR(50)            NULL,
    [ExecutionReference]       UNIQUEIDENTIFIER       NOT NULL
        CONSTRAINT [DF_audit_PackageExecution_ExecutionReference]
        DEFAULT (NEWSEQUENTIALID()),
    [SsisExecutionId]          BIGINT                 NULL,
    [ExecutionStatus]          VARCHAR(30)            NOT NULL
        CONSTRAINT [DF_audit_PackageExecution_ExecutionStatus]
        DEFAULT ('STARTED'),
    [StartedAt]                DATETIME2(3)           NOT NULL
        CONSTRAINT [DF_audit_PackageExecution_StartedAt]
        DEFAULT (SYSUTCDATETIME()),
    [CompletedAt]              DATETIME2(3)           NULL,
    [SourceRowCount]           BIGINT                 NULL,
    [LandedRowCount]           BIGINT                 NULL,
    [AcceptedRowCount]         BIGINT                 NULL,
    [RejectedRowCount]         BIGINT                 NULL,
    [QuarantinedRowCount]      BIGINT                 NULL,
    [WarningRowCount]          BIGINT                 NULL,
    [DuplicateRowCount]        BIGINT                 NULL,
    [ErrorCode]                VARCHAR(100)           NULL,
    [ErrorDetail]              NVARCHAR(2000)         NULL,
    [CreatedAt]                DATETIME2(3)           NOT NULL
        CONSTRAINT [DF_audit_PackageExecution_CreatedAt]
        DEFAULT (SYSUTCDATETIME()),
    [UpdatedAt]                DATETIME2(3)           NULL,

    CONSTRAINT [PK_audit_PackageExecution]
        PRIMARY KEY CLUSTERED ([PackageExecutionId]),

    CONSTRAINT [UQ_audit_PackageExecution_ExecutionReference]
        UNIQUE ([ExecutionReference]),

    CONSTRAINT [FK_audit_PackageExecution_Batch]
        FOREIGN KEY ([BatchId])
        REFERENCES [audit].[Batch] ([BatchId]),

    CONSTRAINT [CK_audit_PackageExecution_PackageName_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([PackageName]))) > 0),

    CONSTRAINT [CK_audit_PackageExecution_ExecutionStatus]
        CHECK
        (
            [ExecutionStatus] IN
            (
                'STARTED',
                'SUCCEEDED',
                'SUCCEEDED_WITH_EXCEPTIONS',
                'FAILED',
                'CANCELLED'
            )
        ),

    CONSTRAINT [CK_audit_PackageExecution_SsisExecutionId]
        CHECK ([SsisExecutionId] IS NULL OR [SsisExecutionId] > 0),

    CONSTRAINT [CK_audit_PackageExecution_SourceRowCount]
        CHECK ([SourceRowCount] IS NULL OR [SourceRowCount] >= 0),

    CONSTRAINT [CK_audit_PackageExecution_LandedRowCount]
        CHECK ([LandedRowCount] IS NULL OR [LandedRowCount] >= 0),

    CONSTRAINT [CK_audit_PackageExecution_AcceptedRowCount]
        CHECK ([AcceptedRowCount] IS NULL OR [AcceptedRowCount] >= 0),

    CONSTRAINT [CK_audit_PackageExecution_RejectedRowCount]
        CHECK ([RejectedRowCount] IS NULL OR [RejectedRowCount] >= 0),

    CONSTRAINT [CK_audit_PackageExecution_QuarantinedRowCount]
        CHECK ([QuarantinedRowCount] IS NULL OR [QuarantinedRowCount] >= 0),

    CONSTRAINT [CK_audit_PackageExecution_WarningRowCount]
        CHECK ([WarningRowCount] IS NULL OR [WarningRowCount] >= 0),

    CONSTRAINT [CK_audit_PackageExecution_DuplicateRowCount]
        CHECK ([DuplicateRowCount] IS NULL OR [DuplicateRowCount] >= 0),

    CONSTRAINT [CK_audit_PackageExecution_CompletedAt]
        CHECK ([CompletedAt] IS NULL OR [CompletedAt] >= [StartedAt]),

    CONSTRAINT [CK_audit_PackageExecution_UpdatedAt]
        CHECK ([UpdatedAt] IS NULL OR [UpdatedAt] >= [CreatedAt])
);
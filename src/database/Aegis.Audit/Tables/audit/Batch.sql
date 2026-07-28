CREATE TABLE [audit].[Batch]
(
    [BatchId]                  BIGINT IDENTITY (1, 1) NOT NULL,
    [BatchReference]           UNIQUEIDENTIFIER       NOT NULL
        CONSTRAINT [DF_audit_Batch_BatchReference]
        DEFAULT (NEWSEQUENTIALID()),
    [InterfaceId]              INT                    NOT NULL,
    [ParentBatchId]            BIGINT                 NULL,
    [SourceFileName]           NVARCHAR(260)          NULL,
    [SourceFilePath]           NVARCHAR(1000)         NULL,
    [SourceExtractedAt]        DATETIME2(3)           NULL,
    [ReceivedAt]               DATETIME2(3)           NOT NULL
        CONSTRAINT [DF_audit_Batch_ReceivedAt]
        DEFAULT (SYSUTCDATETIME()),
    [StartedAt]                DATETIME2(3)           NULL,
    [CompletedAt]              DATETIME2(3)           NULL,
    [BatchStatus]              VARCHAR(30)            NOT NULL
        CONSTRAINT [DF_audit_Batch_BatchStatus]
        DEFAULT ('RECEIVED'),
    [IsReplay]                 BIT                    NOT NULL
        CONSTRAINT [DF_audit_Batch_IsReplay]
        DEFAULT (0),
    [SourceRowCount]           BIGINT                 NULL,
    [LandedRowCount]           BIGINT                 NULL,
    [AcceptedRowCount]         BIGINT                 NULL,
    [RejectedRowCount]         BIGINT                 NULL,
    [QuarantinedRowCount]      BIGINT                 NULL,
    [WarningRowCount]          BIGINT                 NULL,
    [DuplicateRowCount]        BIGINT                 NULL,
    [ReplayedRowCount]         BIGINT                 NULL,
    [ErrorCode]                VARCHAR(100)           NULL,
    [ErrorDetail]              NVARCHAR(2000)         NULL,
    [CreatedAt]                DATETIME2(3)           NOT NULL
        CONSTRAINT [DF_audit_Batch_CreatedAt]
        DEFAULT (SYSUTCDATETIME()),
    [UpdatedAt]                DATETIME2(3)           NULL,

    CONSTRAINT [PK_audit_Batch]
        PRIMARY KEY CLUSTERED ([BatchId]),

    CONSTRAINT [UQ_audit_Batch_BatchReference]
        UNIQUE ([BatchReference]),

    CONSTRAINT [FK_audit_Batch_Interface]
        FOREIGN KEY ([InterfaceId])
        REFERENCES [audit].[Interface] ([InterfaceId]),

    CONSTRAINT [FK_audit_Batch_ParentBatch]
        FOREIGN KEY ([ParentBatchId])
        REFERENCES [audit].[Batch] ([BatchId]),

    CONSTRAINT [CK_audit_Batch_BatchStatus]
        CHECK
        (
            [BatchStatus] IN
            (
                'RECEIVED',
                'PROCESSING',
                'COMPLETED',
                'COMPLETED_WITH_EXCEPTIONS',
                'FAILED',
                'CANCELLED'
            )
        ),

    CONSTRAINT [CK_audit_Batch_SourceRowCount]
        CHECK ([SourceRowCount] IS NULL OR [SourceRowCount] >= 0),

    CONSTRAINT [CK_audit_Batch_LandedRowCount]
        CHECK ([LandedRowCount] IS NULL OR [LandedRowCount] >= 0),

    CONSTRAINT [CK_audit_Batch_AcceptedRowCount]
        CHECK ([AcceptedRowCount] IS NULL OR [AcceptedRowCount] >= 0),

    CONSTRAINT [CK_audit_Batch_RejectedRowCount]
        CHECK ([RejectedRowCount] IS NULL OR [RejectedRowCount] >= 0),

    CONSTRAINT [CK_audit_Batch_QuarantinedRowCount]
        CHECK ([QuarantinedRowCount] IS NULL OR [QuarantinedRowCount] >= 0),

    CONSTRAINT [CK_audit_Batch_WarningRowCount]
        CHECK ([WarningRowCount] IS NULL OR [WarningRowCount] >= 0),

    CONSTRAINT [CK_audit_Batch_DuplicateRowCount]
        CHECK ([DuplicateRowCount] IS NULL OR [DuplicateRowCount] >= 0),

    CONSTRAINT [CK_audit_Batch_ReplayedRowCount]
        CHECK ([ReplayedRowCount] IS NULL OR [ReplayedRowCount] >= 0),

    CONSTRAINT [CK_audit_Batch_StartedAt]
        CHECK ([StartedAt] IS NULL OR [StartedAt] >= [ReceivedAt]),

    CONSTRAINT [CK_audit_Batch_CompletedAt]
        CHECK
        (
            [CompletedAt] IS NULL
            OR
            (
                [StartedAt] IS NOT NULL
                AND [CompletedAt] >= [StartedAt]
            )
        ),

    CONSTRAINT [CK_audit_Batch_UpdatedAt]
        CHECK ([UpdatedAt] IS NULL OR [UpdatedAt] >= [CreatedAt]),

    CONSTRAINT [CK_audit_Batch_ReplayParent]
        CHECK
        (
            ([IsReplay] = 0 AND [ParentBatchId] IS NULL)
            OR
            ([IsReplay] = 1 AND [ParentBatchId] IS NOT NULL)
        )
);
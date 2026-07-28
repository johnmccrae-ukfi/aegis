CREATE TABLE [replay].[ReplayAttempt]
(
    [ReplayAttemptId]          BIGINT IDENTITY (1, 1) NOT NULL,
    [ReplayRequestId]          BIGINT                 NOT NULL,
    [ReplayBatchId]            BIGINT                 NOT NULL,
    [PackageExecutionId]       BIGINT                 NOT NULL,
    [AttemptNumber]            INT                    NOT NULL,
    [AttemptStatus]            VARCHAR(30)            NOT NULL
        CONSTRAINT [DF_replay_ReplayAttempt_AttemptStatus]
        DEFAULT ('STARTED'),
    [StartedAt]                DATETIME2(3)           NOT NULL
        CONSTRAINT [DF_replay_ReplayAttempt_StartedAt]
        DEFAULT (SYSUTCDATETIME()),
    [CompletedAt]              DATETIME2(3)           NULL,
    [SourceRowCount]           BIGINT                 NULL,
    [AcceptedRowCount]         BIGINT                 NULL,
    [RejectedRowCount]         BIGINT                 NULL,
    [QuarantinedRowCount]      BIGINT                 NULL,
    [ErrorCode]                VARCHAR(100)           NULL,
    [ErrorDetail]              NVARCHAR(2000)         NULL,
    [CreatedAt]                DATETIME2(3)           NOT NULL
        CONSTRAINT [DF_replay_ReplayAttempt_CreatedAt]
        DEFAULT (SYSUTCDATETIME()),
    [UpdatedAt]                DATETIME2(3)           NULL,

    CONSTRAINT [PK_replay_ReplayAttempt]
        PRIMARY KEY CLUSTERED ([ReplayAttemptId]),

    CONSTRAINT [FK_replay_ReplayAttempt_ReplayRequest]
        FOREIGN KEY ([ReplayRequestId])
        REFERENCES [replay].[ReplayRequest] ([ReplayRequestId]),

    CONSTRAINT [FK_replay_ReplayAttempt_ReplayBatch]
        FOREIGN KEY ([ReplayBatchId])
        REFERENCES [audit].[Batch] ([BatchId]),

    CONSTRAINT [FK_replay_ReplayAttempt_PackageExecution]
        FOREIGN KEY ([PackageExecutionId])
        REFERENCES [audit].[PackageExecution] ([PackageExecutionId]),

    CONSTRAINT [UQ_replay_ReplayAttempt_Request_AttemptNumber]
        UNIQUE
        (
            [ReplayRequestId],
            [AttemptNumber]
        ),

    CONSTRAINT [CK_replay_ReplayAttempt_AttemptNumber]
        CHECK ([AttemptNumber] > 0),

    CONSTRAINT [CK_replay_ReplayAttempt_AttemptStatus]
        CHECK
        (
            [AttemptStatus] IN
            (
                'STARTED',
                'SUCCEEDED',
                'SUCCEEDED_WITH_EXCEPTIONS',
                'FAILED',
                'CANCELLED'
            )
        ),

    CONSTRAINT [CK_replay_ReplayAttempt_SourceRowCount]
        CHECK ([SourceRowCount] IS NULL OR [SourceRowCount] >= 0),

    CONSTRAINT [CK_replay_ReplayAttempt_AcceptedRowCount]
        CHECK ([AcceptedRowCount] IS NULL OR [AcceptedRowCount] >= 0),

    CONSTRAINT [CK_replay_ReplayAttempt_RejectedRowCount]
        CHECK ([RejectedRowCount] IS NULL OR [RejectedRowCount] >= 0),

    CONSTRAINT [CK_replay_ReplayAttempt_QuarantinedRowCount]
        CHECK ([QuarantinedRowCount] IS NULL OR [QuarantinedRowCount] >= 0),

    CONSTRAINT [CK_replay_ReplayAttempt_CompletedAt]
        CHECK
        (
            (
                [AttemptStatus] = 'STARTED'
                AND [CompletedAt] IS NULL
            )
            OR
            (
                [AttemptStatus] IN
                (
                    'SUCCEEDED',
                    'SUCCEEDED_WITH_EXCEPTIONS',
                    'FAILED',
                    'CANCELLED'
                )
                AND [CompletedAt] IS NOT NULL
                AND [CompletedAt] >= [StartedAt]
            )
        ),

    CONSTRAINT [CK_replay_ReplayAttempt_UpdatedAt]
        CHECK
        (
            [UpdatedAt] IS NULL
            OR [UpdatedAt] >= [CreatedAt]
        )
);
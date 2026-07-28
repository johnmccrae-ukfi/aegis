CREATE TABLE [replay].[ReplayRequest]
(
    [ReplayRequestId]          BIGINT IDENTITY (1, 1) NOT NULL,
    [ReplayReference]          UNIQUEIDENTIFIER       NOT NULL
        CONSTRAINT [DF_replay_ReplayRequest_ReplayReference]
        DEFAULT (NEWSEQUENTIALID()),
    [OriginalBatchId]          BIGINT                 NOT NULL,
    [DataQualityExceptionId]   BIGINT                 NULL,
    [SourceDomain]             VARCHAR(50)            NOT NULL,
    [SourceObject]             VARCHAR(128)           NOT NULL,
    [SourceRecordIdentifier]   NVARCHAR(200)          NULL,
    [ReplayScope]              VARCHAR(20)            NOT NULL,
    [ReplayStatus]             VARCHAR(30)            NOT NULL
        CONSTRAINT [DF_replay_ReplayRequest_ReplayStatus]
        DEFAULT ('REQUESTED'),
    [RequestedBy]              NVARCHAR(256)           NOT NULL,
    [RequestedAt]              DATETIME2(3)            NOT NULL
        CONSTRAINT [DF_replay_ReplayRequest_RequestedAt]
        DEFAULT (SYSUTCDATETIME()),
    [AuthorisedBy]             NVARCHAR(256)           NULL,
    [AuthorisedAt]             DATETIME2(3)            NULL,
    [CompletedAt]              DATETIME2(3)            NULL,
    [ReplayReason]             NVARCHAR(1000)          NOT NULL,
    [ResolutionDetail]         NVARCHAR(2000)          NULL,
    [CreatedAt]                DATETIME2(3)            NOT NULL
        CONSTRAINT [DF_replay_ReplayRequest_CreatedAt]
        DEFAULT (SYSUTCDATETIME()),
    [UpdatedAt]                DATETIME2(3)            NULL,

    CONSTRAINT [PK_replay_ReplayRequest]
        PRIMARY KEY CLUSTERED ([ReplayRequestId]),

    CONSTRAINT [UQ_replay_ReplayRequest_ReplayReference]
        UNIQUE ([ReplayReference]),

    CONSTRAINT [FK_replay_ReplayRequest_OriginalBatch]
        FOREIGN KEY ([OriginalBatchId])
        REFERENCES [audit].[Batch] ([BatchId]),

    CONSTRAINT [FK_replay_ReplayRequest_DataQualityException]
        FOREIGN KEY ([DataQualityExceptionId])
        REFERENCES [dq].[DataQualityException] ([DataQualityExceptionId]),

    CONSTRAINT [CK_replay_ReplayRequest_SourceDomain_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceDomain]))) > 0),

    CONSTRAINT [CK_replay_ReplayRequest_SourceObject_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceObject]))) > 0),

    CONSTRAINT [CK_replay_ReplayRequest_ReplayScope]
        CHECK
        (
            [ReplayScope] IN
            (
                'RECORD',
                'BATCH',
                'INTERFACE'
            )
        ),

    CONSTRAINT [CK_replay_ReplayRequest_ReplayStatus]
        CHECK
        (
            [ReplayStatus] IN
            (
                'REQUESTED',
                'AUTHORISED',
                'IN_PROGRESS',
                'COMPLETED',
                'FAILED',
                'CANCELLED'
            )
        ),

    CONSTRAINT [CK_replay_ReplayRequest_RequestedBy_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([RequestedBy]))) > 0),

    CONSTRAINT [CK_replay_ReplayRequest_ReplayReason_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([ReplayReason]))) > 0),

    CONSTRAINT [CK_replay_ReplayRequest_RecordScope]
        CHECK
        (
            (
                [ReplayScope] = 'RECORD'
                AND [SourceRecordIdentifier] IS NOT NULL
                AND [DataQualityExceptionId] IS NOT NULL
            )
            OR
            (
                [ReplayScope] IN ('BATCH', 'INTERFACE')
                AND [DataQualityExceptionId] IS NULL
            )
        ),

    CONSTRAINT [CK_replay_ReplayRequest_Authorisation]
        CHECK
        (
            (
                [ReplayStatus] = 'REQUESTED'
                AND [AuthorisedBy] IS NULL
                AND [AuthorisedAt] IS NULL
            )
            OR
            (
                [ReplayStatus] IN
                (
                    'AUTHORISED',
                    'IN_PROGRESS',
                    'COMPLETED',
                    'FAILED',
                    'CANCELLED'
                )
                AND [AuthorisedBy] IS NOT NULL
                AND [AuthorisedAt] IS NOT NULL
            )
        ),

    CONSTRAINT [CK_replay_ReplayRequest_AuthorisedAt]
        CHECK
        (
            [AuthorisedAt] IS NULL
            OR [AuthorisedAt] >= [RequestedAt]
        ),

    CONSTRAINT [CK_replay_ReplayRequest_CompletedAt]
        CHECK
        (
            (
                [ReplayStatus] IN
                (
                    'REQUESTED',
                    'AUTHORISED',
                    'IN_PROGRESS'
                )
                AND [CompletedAt] IS NULL
            )
            OR
            (
                [ReplayStatus] IN
                (
                    'COMPLETED',
                    'FAILED',
                    'CANCELLED'
                )
                AND [CompletedAt] IS NOT NULL
                AND [CompletedAt] >= [RequestedAt]
            )
        ),

    CONSTRAINT [CK_replay_ReplayRequest_UpdatedAt]
        CHECK
        (
            [UpdatedAt] IS NULL
            OR [UpdatedAt] >= [CreatedAt]
        )
);
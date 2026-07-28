CREATE TABLE [dq].[DataQualityException]
(
    [DataQualityExceptionId]   BIGINT IDENTITY (1, 1) NOT NULL,
    [RecordOutcomeId]          BIGINT                 NOT NULL,
    [BatchId]                  BIGINT                 NOT NULL,
    [PackageExecutionId]       BIGINT                 NOT NULL,
    [ValidationRuleId]         INT                    NOT NULL,
    [SourceDomain]             VARCHAR(50)            NOT NULL,
    [SourceObject]             VARCHAR(128)           NOT NULL,
    [SourceRecordIdentifier]   NVARCHAR(200)          NOT NULL,
    [SourceColumnName]         NVARCHAR(128)          NULL,
    [SourceValue]              NVARCHAR(2000)         NULL,
    [ExpectedValue]            NVARCHAR(2000)         NULL,
    [ErrorCode]                VARCHAR(100)           NULL,
    [ErrorDetail]              NVARCHAR(2000)         NOT NULL,
    [ResolutionStatus]         VARCHAR(30)            NOT NULL
        CONSTRAINT [DF_dq_DataQualityException_ResolutionStatus]
        DEFAULT ('OPEN'),
    [QuarantinedAt]            DATETIME2(3)           NULL,
    [ResolvedAt]               DATETIME2(3)           NULL,
    [ResolutionDetail]         NVARCHAR(2000)         NULL,
    [CreatedAt]                DATETIME2(3)           NOT NULL
        CONSTRAINT [DF_dq_DataQualityException_CreatedAt]
        DEFAULT (SYSUTCDATETIME()),
    [UpdatedAt]                DATETIME2(3)           NULL,

    CONSTRAINT [PK_dq_DataQualityException]
        PRIMARY KEY CLUSTERED ([DataQualityExceptionId]),

    CONSTRAINT [FK_dq_DataQualityException_RecordOutcome]
        FOREIGN KEY ([RecordOutcomeId])
        REFERENCES [audit].[RecordOutcome] ([RecordOutcomeId]),

    CONSTRAINT [FK_dq_DataQualityException_Batch]
        FOREIGN KEY ([BatchId])
        REFERENCES [audit].[Batch] ([BatchId]),

    CONSTRAINT [FK_dq_DataQualityException_PackageExecution]
        FOREIGN KEY ([PackageExecutionId])
        REFERENCES [audit].[PackageExecution] ([PackageExecutionId]),

    CONSTRAINT [FK_dq_DataQualityException_ValidationRule]
        FOREIGN KEY ([ValidationRuleId])
        REFERENCES [dq].[ValidationRule] ([ValidationRuleId]),

    CONSTRAINT [UQ_dq_DataQualityException_RecordOutcome_Rule]
        UNIQUE
        (
            [RecordOutcomeId],
            [ValidationRuleId]
        ),

    CONSTRAINT [CK_dq_DataQualityException_SourceDomain_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceDomain]))) > 0),

    CONSTRAINT [CK_dq_DataQualityException_SourceObject_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceObject]))) > 0),

    CONSTRAINT [CK_dq_DataQualityException_SourceRecordIdentifier_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceRecordIdentifier]))) > 0),

    CONSTRAINT [CK_dq_DataQualityException_ErrorDetail_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([ErrorDetail]))) > 0),

    CONSTRAINT [CK_dq_DataQualityException_ResolutionStatus]
        CHECK
        (
            [ResolutionStatus] IN
            (
                'OPEN',
                'UNDER_REVIEW',
                'CORRECTED',
                'REPLAY_PENDING',
                'RESOLVED',
                'ACCEPTED_AS_LEGACY',
                'CANCELLED'
            )
        ),

    CONSTRAINT [CK_dq_DataQualityException_QuarantinedAt]
        CHECK
        (
            [QuarantinedAt] IS NULL
            OR [QuarantinedAt] >= [CreatedAt]
        ),

    CONSTRAINT [CK_dq_DataQualityException_ResolvedAt]
        CHECK
        (
            [ResolvedAt] IS NULL
            OR [ResolvedAt] >= [CreatedAt]
        ),

    CONSTRAINT [CK_dq_DataQualityException_ResolutionConsistency]
        CHECK
        (
            (
                [ResolutionStatus] IN
                (
                    'OPEN',
                    'UNDER_REVIEW',
                    'CORRECTED',
                    'REPLAY_PENDING'
                )
                AND [ResolvedAt] IS NULL
            )
            OR
            (
                [ResolutionStatus] IN
                (
                    'RESOLVED',
                    'ACCEPTED_AS_LEGACY',
                    'CANCELLED'
                )
                AND [ResolvedAt] IS NOT NULL
            )
        ),

    CONSTRAINT [CK_dq_DataQualityException_UpdatedAt]
        CHECK
        (
            [UpdatedAt] IS NULL
            OR [UpdatedAt] >= [CreatedAt]
        )
);
CREATE TABLE [audit].[RecordOutcome]
(
    [RecordOutcomeId]          BIGINT IDENTITY (1, 1) NOT NULL,
    [BatchId]                  BIGINT                 NOT NULL,
    [PackageExecutionId]       BIGINT                 NOT NULL,
    [SourceDomain]             VARCHAR(50)            NOT NULL,
    [SourceObject]             VARCHAR(128)           NOT NULL,
    [SourceRecordIdentifier]   NVARCHAR(200)          NOT NULL,
    [SourceRowNumber]          BIGINT                 NULL,
    [LandingRecordId]          BIGINT                 NULL,
    [ProcessingOutcome]        VARCHAR(20)            NOT NULL,
    [OutcomeReasonCode]        VARCHAR(100)           NULL,
    [OutcomeDetail]            NVARCHAR(2000)         NULL,
    [ProcessedAt]              DATETIME2(3)           NOT NULL
        CONSTRAINT [DF_audit_RecordOutcome_ProcessedAt]
        DEFAULT (SYSUTCDATETIME()),
    [CreatedAt]                DATETIME2(3)           NOT NULL
        CONSTRAINT [DF_audit_RecordOutcome_CreatedAt]
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT [PK_audit_RecordOutcome]
        PRIMARY KEY CLUSTERED ([RecordOutcomeId]),

    CONSTRAINT [FK_audit_RecordOutcome_Batch]
        FOREIGN KEY ([BatchId])
        REFERENCES [audit].[Batch] ([BatchId]),

    CONSTRAINT [FK_audit_RecordOutcome_PackageExecution]
        FOREIGN KEY ([PackageExecutionId])
        REFERENCES [audit].[PackageExecution] ([PackageExecutionId]),

    CONSTRAINT [UQ_audit_RecordOutcome_Batch_SourceRecord]
        UNIQUE
        (
            [BatchId],
            [SourceDomain],
            [SourceObject],
            [SourceRecordIdentifier]
        ),

    CONSTRAINT [CK_audit_RecordOutcome_SourceDomain_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceDomain]))) > 0),

    CONSTRAINT [CK_audit_RecordOutcome_SourceObject_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceObject]))) > 0),

    CONSTRAINT [CK_audit_RecordOutcome_SourceRecordIdentifier_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceRecordIdentifier]))) > 0),

    CONSTRAINT [CK_audit_RecordOutcome_SourceRowNumber]
        CHECK ([SourceRowNumber] IS NULL OR [SourceRowNumber] > 0),

    CONSTRAINT [CK_audit_RecordOutcome_LandingRecordId]
        CHECK ([LandingRecordId] IS NULL OR [LandingRecordId] > 0),

    CONSTRAINT [CK_audit_RecordOutcome_ProcessingOutcome]
        CHECK
        (
            [ProcessingOutcome] IN
            (
                'ACCEPTED',
                'WARNING',
                'QUARANTINED',
                'REJECTED',
                'DUPLICATE',
                'CANCELLED'
            )
        )
);
CREATE TABLE [pas].[PatientMerge]
(
    [PatientMergeId]              BIGINT IDENTITY (1, 1) NOT NULL,
    [SurvivingPatientId]          INT                  NOT NULL,
    [SupersededPatientId]         INT                  NOT NULL,
    [SurvivingIdentifierValue]    NVARCHAR(100)           NULL,
    [SupersededIdentifierValue]   NVARCHAR(100)           NULL,
    [MergeDateTime]               DATETIME2(0)            NOT NULL,
    [MergeReasonCode]             VARCHAR(30)             NULL,
    [MergeReasonDescription]      NVARCHAR(250)           NULL,
    [SourceMessageControlId]      VARCHAR(100)             NULL,
    [SourceSystemCode]            VARCHAR(30)              NULL,
    [CreatedAtUtc]                DATETIME2(0)             NOT NULL
        CONSTRAINT [DF_pas_PatientMerge_CreatedAtUtc]
        DEFAULT (SYSUTCDATETIME()),
    [UpdatedAtUtc]                DATETIME2(0)             NULL,

    CONSTRAINT [PK_pas_PatientMerge]
        PRIMARY KEY CLUSTERED ([PatientMergeId]),

    CONSTRAINT [FK_pas_PatientMerge_SurvivingPatient]
        FOREIGN KEY ([SurvivingPatientId])
        REFERENCES [pas].[Patient] ([PatientId]),

    CONSTRAINT [FK_pas_PatientMerge_SupersededPatient]
        FOREIGN KEY ([SupersededPatientId])
        REFERENCES [pas].[Patient] ([PatientId])
);
GO

CREATE NONCLUSTERED INDEX [IX_pas_PatientMerge_SurvivingPatientId]
    ON [pas].[PatientMerge] ([SurvivingPatientId]);
GO

CREATE NONCLUSTERED INDEX [IX_pas_PatientMerge_SupersededPatientId]
    ON [pas].[PatientMerge] ([SupersededPatientId]);
GO

CREATE NONCLUSTERED INDEX [IX_pas_PatientMerge_MergeDateTime]
    ON [pas].[PatientMerge] ([MergeDateTime]);
GO

CREATE NONCLUSTERED INDEX [IX_pas_PatientMerge_SourceMessageControlId]
    ON [pas].[PatientMerge] ([SourceMessageControlId]);
GO
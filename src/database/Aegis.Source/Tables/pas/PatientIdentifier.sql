CREATE TABLE [pas].[PatientIdentifier]
(
    [PatientIdentifierId] BIGINT IDENTITY (1, 1) NOT NULL,
    [PatientId]           INT                  NOT NULL,
    [IdentifierValue]     NVARCHAR(100)           NOT NULL,
    [IdentifierTypeCode]  VARCHAR(30)             NOT NULL,
    [AssigningAuthority]  VARCHAR(50)             NULL,
    [EffectiveFromDate]   DATE                    NULL,
    [EffectiveToDate]     DATE                    NULL,
    [IsCurrent]           BIT                     NULL,
    [CreatedAtUtc]        DATETIME2(0)            NOT NULL
        CONSTRAINT [DF_pas_PatientIdentifier_CreatedAtUtc]
        DEFAULT (SYSUTCDATETIME()),
    [UpdatedAtUtc]        DATETIME2(0)            NULL,

    CONSTRAINT [PK_pas_PatientIdentifier]
        PRIMARY KEY CLUSTERED ([PatientIdentifierId]),

    CONSTRAINT [FK_pas_PatientIdentifier_Patient]
        FOREIGN KEY ([PatientId])
        REFERENCES [pas].[Patient] ([PatientId])
);
GO

CREATE NONCLUSTERED INDEX [IX_pas_PatientIdentifier_PatientId]
    ON [pas].[PatientIdentifier] ([PatientId]);
GO

CREATE NONCLUSTERED INDEX [IX_pas_PatientIdentifier_IdentifierValue]
    ON [pas].[PatientIdentifier]
    (
        [IdentifierTypeCode],
        [IdentifierValue]
    );
GO
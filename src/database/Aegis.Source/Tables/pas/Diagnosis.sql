CREATE TABLE [pas].[Diagnosis]
(
    [DiagnosisId]             INT            IDENTITY (1, 1) NOT NULL,
    [ConsultantEpisodeId]     INT            NOT NULL,

    [SourceDiagnosisId]       VARCHAR(30)    NULL,
    [DiagnosisSequence]       SMALLINT       NULL,
    [IsPrimaryDiagnosis]      BIT            NULL,

    [DiagnosisCode]           VARCHAR(20)    NULL,
    [DiagnosisCodeSystem]     VARCHAR(20)    NULL,
    [DiagnosisDescription]    NVARCHAR(250)  NULL,
    [DiagnosisDate]           DATE           NULL,

    [PresentOnAdmissionCode]  VARCHAR(10)    NULL,
    [LateralityCode]          VARCHAR(10)    NULL,
    [DiagnosisStatusCode]     VARCHAR(20)    NULL,

    [RecordCreatedAt]         DATETIME2(0)   NOT NULL,
    [RecordUpdatedAt]         DATETIME2(0)   NOT NULL,
    [IsDeleted]               BIT            NOT NULL
        CONSTRAINT [DF_pas_Diagnosis_IsDeleted]
        DEFAULT (0),

    CONSTRAINT [PK_pas_Diagnosis]
        PRIMARY KEY CLUSTERED ([DiagnosisId]),

    CONSTRAINT [UQ_pas_Diagnosis_EpisodeSequence]
        UNIQUE ([ConsultantEpisodeId], [DiagnosisSequence]),

    CONSTRAINT [FK_pas_Diagnosis_ConsultantEpisode]
        FOREIGN KEY ([ConsultantEpisodeId])
        REFERENCES [pas].[ConsultantEpisode] ([ConsultantEpisodeId]),

    CONSTRAINT [CK_pas_Diagnosis_DiagnosisSequence]
        CHECK
        (
            [DiagnosisSequence] IS NULL
            OR [DiagnosisSequence] > 0
        )
);
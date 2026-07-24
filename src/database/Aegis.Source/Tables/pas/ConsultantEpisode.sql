CREATE TABLE [pas].[ConsultantEpisode]
(
    [ConsultantEpisodeId]        INT            IDENTITY (1, 1) NOT NULL,
    [AdmissionId]                INT            NOT NULL,

    [EpisodeNumber]              VARCHAR(30)    NOT NULL,
    [EpisodeSequence]            SMALLINT       NULL,

    [ConsultantId]               INT            NULL,
    [MainSpecialtyId]            INT            NULL,
    [TreatmentSpecialtyId]       INT            NULL,

    [EpisodeStartDateTime]       DATETIME2(0)   NULL,
    [EpisodeEndDateTime]         DATETIME2(0)   NULL,

    [EpisodeStatusCode]          VARCHAR(20)    NULL,
    [EpisodeTypeCode]            VARCHAR(20)    NULL,
    [PatientClassificationCode]  VARCHAR(10)    NULL,

    [RecordCreatedAt]            DATETIME2(0)   NOT NULL,
    [RecordUpdatedAt]            DATETIME2(0)   NOT NULL,
    [IsDeleted]                  BIT            NOT NULL
        CONSTRAINT [DF_pas_ConsultantEpisode_IsDeleted]
        DEFAULT (0),

    CONSTRAINT [PK_pas_ConsultantEpisode]
        PRIMARY KEY CLUSTERED ([ConsultantEpisodeId]),

    CONSTRAINT [UQ_pas_ConsultantEpisode_EpisodeNumber]
        UNIQUE ([EpisodeNumber]),

    CONSTRAINT [UQ_pas_ConsultantEpisode_AdmissionSequence]
        UNIQUE ([AdmissionId], [EpisodeSequence]),

    CONSTRAINT [FK_pas_ConsultantEpisode_Admission]
        FOREIGN KEY ([AdmissionId])
        REFERENCES [pas].[Admission] ([AdmissionId]),

    CONSTRAINT [FK_pas_ConsultantEpisode_Consultant]
        FOREIGN KEY ([ConsultantId])
        REFERENCES [ref].[Consultant] ([ConsultantId]),

    CONSTRAINT [FK_pas_ConsultantEpisode_MainSpecialty]
        FOREIGN KEY ([MainSpecialtyId])
        REFERENCES [ref].[Specialty] ([SpecialtyId]),

    CONSTRAINT [FK_pas_ConsultantEpisode_TreatmentSpecialty]
        FOREIGN KEY ([TreatmentSpecialtyId])
        REFERENCES [ref].[Specialty] ([SpecialtyId]),

    CONSTRAINT [CK_pas_ConsultantEpisode_EpisodeSequence]
        CHECK
        (
            [EpisodeSequence] IS NULL
            OR [EpisodeSequence] > 0
        )
);
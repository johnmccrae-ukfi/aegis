CREATE TABLE [pas].[Procedure]
(
    [ProcedureId]             INT            IDENTITY (1, 1) NOT NULL,
    [ConsultantEpisodeId]     INT            NOT NULL,

    [SourceProcedureId]       VARCHAR(30)    NULL,
    [ProcedureSequence]       SMALLINT       NULL,
    [IsPrimaryProcedure]      BIT            NULL,

    [ProcedureCode]           VARCHAR(20)    NULL,
    [ProcedureCodeSystem]     VARCHAR(20)    NULL,
    [ProcedureDescription]    NVARCHAR(250)  NULL,

    [ProcedureDateTime]       DATETIME2(0)   NULL,
    [ProcedureSiteCode]       VARCHAR(20)    NULL,
    [LateralityCode]          VARCHAR(10)    NULL,
    [ProcedureStatusCode]     VARCHAR(20)    NULL,

    [ConsultantId]            INT            NULL,
    [SiteId]                  INT            NULL,

    [RecordCreatedAt]         DATETIME2(0)   NOT NULL,
    [RecordUpdatedAt]         DATETIME2(0)   NOT NULL,
    [IsDeleted]               BIT            NOT NULL
        CONSTRAINT [DF_pas_Procedure_IsDeleted]
        DEFAULT (0),

    CONSTRAINT [PK_pas_Procedure]
        PRIMARY KEY CLUSTERED ([ProcedureId]),

    CONSTRAINT [UQ_pas_Procedure_EpisodeSequence]
        UNIQUE ([ConsultantEpisodeId], [ProcedureSequence]),

    CONSTRAINT [FK_pas_Procedure_ConsultantEpisode]
        FOREIGN KEY ([ConsultantEpisodeId])
        REFERENCES [pas].[ConsultantEpisode] ([ConsultantEpisodeId]),

    CONSTRAINT [FK_pas_Procedure_Consultant]
        FOREIGN KEY ([ConsultantId])
        REFERENCES [ref].[Consultant] ([ConsultantId]),

    CONSTRAINT [FK_pas_Procedure_Site]
        FOREIGN KEY ([SiteId])
        REFERENCES [ref].[Site] ([SiteId]),

    CONSTRAINT [CK_pas_Procedure_ProcedureSequence]
        CHECK
        (
            [ProcedureSequence] IS NULL
            OR [ProcedureSequence] > 0
        )
);
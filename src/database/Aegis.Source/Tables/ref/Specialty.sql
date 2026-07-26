CREATE TABLE [ref].[Specialty]
(
    [SpecialtyId]             INT            IDENTITY (1, 1) NOT NULL,
    [SpecialtyCode]           VARCHAR(20)    NOT NULL,
    [NationalSpecialtyCode]   VARCHAR(10)    NULL,
    [SpecialtyName]           NVARCHAR(200)  NOT NULL,
    [SpecialtyTypeCode]       VARCHAR(20)    NULL,
    [ParentSpecialtyCode]     VARCHAR(20)    NULL,
    [EffectiveFromDate]       DATE           NULL,
    [EffectiveToDate]         DATE           NULL,
    [RecordCreatedAt]         DATETIME2(0)   NOT NULL,
    [RecordUpdatedAt]         DATETIME2(0)   NOT NULL,
    [IsDeleted]               BIT            NOT NULL
        CONSTRAINT [DF_ref_Specialty_IsDeleted]
        DEFAULT (0),

    CONSTRAINT [PK_ref_Specialty]
        PRIMARY KEY CLUSTERED ([SpecialtyId]),

    CONSTRAINT [UQ_ref_Specialty_SpecialtyCode]
        UNIQUE ([SpecialtyCode]),

    CONSTRAINT [CK_ref_Specialty_EffectiveDates]
        CHECK
        (
            [EffectiveToDate] IS NULL
            OR [EffectiveFromDate] IS NULL
            OR [EffectiveToDate] >= [EffectiveFromDate]
        )
);
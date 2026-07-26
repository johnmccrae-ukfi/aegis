CREATE TABLE [ref].[Ward]
(
    [WardId]                 INT            IDENTITY (1, 1) NOT NULL,
    [SiteId]                 INT            NOT NULL,
    [WardCode]               VARCHAR(20)    NOT NULL,
    [WardName]               NVARCHAR(200)  NOT NULL,
    [WardTypeCode]           VARCHAR(20)    NULL,
    [SpecialtyId]            INT            NULL,
    [BedCapacity]            SMALLINT       NULL,
    [EffectiveFromDate]      DATE           NULL,
    [EffectiveToDate]        DATE           NULL,
    [RecordCreatedAt]        DATETIME2(0)   NOT NULL,
    [RecordUpdatedAt]        DATETIME2(0)   NOT NULL,
    [IsDeleted]              BIT            NOT NULL
        CONSTRAINT [DF_ref_Ward_IsDeleted]
        DEFAULT (0),

    CONSTRAINT [PK_ref_Ward]
        PRIMARY KEY CLUSTERED ([WardId]),

    CONSTRAINT [UQ_ref_Ward_Site_WardCode]
        UNIQUE ([SiteId], [WardCode]),

    CONSTRAINT [FK_ref_Ward_Site]
        FOREIGN KEY ([SiteId])
        REFERENCES [ref].[Site] ([SiteId]),

    CONSTRAINT [FK_ref_Ward_Specialty]
        FOREIGN KEY ([SpecialtyId])
        REFERENCES [ref].[Specialty] ([SpecialtyId]),

    CONSTRAINT [CK_ref_Ward_BedCapacity]
        CHECK
        (
            [BedCapacity] IS NULL
            OR [BedCapacity] >= 0
        ),

    CONSTRAINT [CK_ref_Ward_EffectiveDates]
        CHECK
        (
            [EffectiveToDate] IS NULL
            OR [EffectiveFromDate] IS NULL
            OR [EffectiveToDate] >= [EffectiveFromDate]
        )
);
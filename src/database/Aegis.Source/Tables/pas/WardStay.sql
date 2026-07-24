CREATE TABLE [pas].[WardStay]
(
    [WardStayId]             INT            IDENTITY (1, 1) NOT NULL,
    [AdmissionId]            INT            NOT NULL,
    [WardId]                 INT            NULL,

    [SourceWardStayId]       VARCHAR(30)    NULL,
    [WardStaySequence]       SMALLINT       NULL,

    [WardStartDateTime]      DATETIME2(0)   NULL,
    [WardEndDateTime]        DATETIME2(0)   NULL,

    [AdmissionWardFlag]      BIT            NULL,
    [DischargeWardFlag]      BIT            NULL,
    [BedNumber]              VARCHAR(20)    NULL,
    [BayCode]                VARCHAR(20)    NULL,
    [WardStayStatusCode]     VARCHAR(20)    NULL,

    [RecordCreatedAt]        DATETIME2(0)   NOT NULL,
    [RecordUpdatedAt]        DATETIME2(0)   NOT NULL,
    [IsDeleted]              BIT            NOT NULL
        CONSTRAINT [DF_pas_WardStay_IsDeleted]
        DEFAULT (0),

    CONSTRAINT [PK_pas_WardStay]
        PRIMARY KEY CLUSTERED ([WardStayId]),

    CONSTRAINT [UQ_pas_WardStay_AdmissionSequence]
        UNIQUE ([AdmissionId], [WardStaySequence]),

    CONSTRAINT [FK_pas_WardStay_Admission]
        FOREIGN KEY ([AdmissionId])
        REFERENCES [pas].[Admission] ([AdmissionId]),

    CONSTRAINT [FK_pas_WardStay_Ward]
        FOREIGN KEY ([WardId])
        REFERENCES [ref].[Ward] ([WardId]),

    CONSTRAINT [CK_pas_WardStay_WardStaySequence]
        CHECK
        (
            [WardStaySequence] IS NULL
            OR [WardStaySequence] > 0
        )
);
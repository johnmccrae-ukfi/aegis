CREATE TABLE [audit].[Interface]
(
    [InterfaceId]              INT IDENTITY (1, 1) NOT NULL,
    [InterfaceCode]            VARCHAR(50)         NOT NULL,
    [InterfaceName]            NVARCHAR(200)       NOT NULL,
    [InterfaceDirection]       VARCHAR(10)         NOT NULL,
    [SourceSystemCode]         VARCHAR(50)         NOT NULL,
    [TargetSystemCode]         VARCHAR(50)         NOT NULL,
    [TransportType]            VARCHAR(30)         NOT NULL,
    [DataFormat]               VARCHAR(30)         NOT NULL,
    [Description]              NVARCHAR(1000)      NULL,
    [IsActive]                 BIT                 NOT NULL
        CONSTRAINT [DF_audit_Interface_IsActive]
        DEFAULT (1),
    [CreatedAt]                DATETIME2(3)        NOT NULL
        CONSTRAINT [DF_audit_Interface_CreatedAt]
        DEFAULT (SYSUTCDATETIME()),
    [UpdatedAt]                DATETIME2(3)        NULL,

    CONSTRAINT [PK_audit_Interface]
        PRIMARY KEY CLUSTERED ([InterfaceId]),

    CONSTRAINT [UQ_audit_Interface_InterfaceCode]
        UNIQUE ([InterfaceCode]),

    CONSTRAINT [CK_audit_Interface_InterfaceCode_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([InterfaceCode]))) > 0),

    CONSTRAINT [CK_audit_Interface_InterfaceName_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([InterfaceName]))) > 0),

    CONSTRAINT [CK_audit_Interface_InterfaceDirection]
        CHECK ([InterfaceDirection] IN ('INBOUND', 'OUTBOUND')),

    CONSTRAINT [CK_audit_Interface_SourceSystemCode_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceSystemCode]))) > 0),

    CONSTRAINT [CK_audit_Interface_TargetSystemCode_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([TargetSystemCode]))) > 0),

    CONSTRAINT [CK_audit_Interface_TransportType]
        CHECK
        (
            [TransportType] IN
            (
                'FILE',
                'SQL',
                'HL7',
                'FHIR',
                'API'
            )
        ),

    CONSTRAINT [CK_audit_Interface_DataFormat]
        CHECK
        (
            [DataFormat] IN
            (
                'CSV',
                'DELIMITED',
                'RELATIONAL',
                'HL7_V2',
                'FHIR_JSON',
                'JSON',
                'XML'
            )
        ),

    CONSTRAINT [CK_audit_Interface_UpdatedAt]
        CHECK ([UpdatedAt] IS NULL OR [UpdatedAt] >= [CreatedAt])
);
CREATE INDEX [IX_landing_Admission_BatchId]
    ON [landing].[Admission]
    (
        [BatchId],
        [LandingAdmissionId]
    )
    INCLUDE
    (
        [PackageExecutionId],
        [SourceRecordIdentifier],
        [AdmissionId],
        [AdmissionNumber],
        [LandedAt]
    );
GO

CREATE INDEX [IX_landing_Admission_PackageExecutionId]
    ON [landing].[Admission]
    (
        [PackageExecutionId],
        [LandingAdmissionId]
    );
GO

CREATE INDEX [IX_landing_Admission_SourceRecordIdentifier]
    ON [landing].[Admission]
    (
        [SourceSystemCode],
        [SourceRecordIdentifier]
    )
    INCLUDE
    (
        [BatchId],
        [AdmissionId],
        [AdmissionNumber],
        [LandedAt]
    );
GO

CREATE INDEX [IX_landing_Admission_AdmissionNumber]
    ON [landing].[Admission]
    (
        [AdmissionNumber]
    )
    WHERE [AdmissionNumber] IS NOT NULL;
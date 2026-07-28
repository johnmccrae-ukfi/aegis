CREATE INDEX [IX_stg_Admission_BatchId_ProcessingOutcome]
    ON [stg].[Admission]
    (
        [BatchId],
        [ProcessingOutcome]
    )
    INCLUDE
    (
        [LandingAdmissionId],
        [PackageExecutionId],
        [SourceRecordIdentifier],
        [AdmissionId],
        [AdmissionNumber],
        [ValidationStatus],
        [ValidationFailureCount]
    );
GO

CREATE INDEX [IX_stg_Admission_PackageExecutionId]
    ON [stg].[Admission]
    (
        [PackageExecutionId],
        [StagingAdmissionId]
    );
GO

CREATE INDEX [IX_stg_Admission_AdmissionId]
    ON [stg].[Admission]
    (
        [AdmissionId]
    )
    INCLUDE
    (
        [BatchId],
        [SourceRecordIdentifier],
        [ProcessingOutcome]
    )
    WHERE [AdmissionId] IS NOT NULL;
GO

CREATE INDEX [IX_stg_Admission_PatientId]
    ON [stg].[Admission]
    (
        [PatientId]
    )
    INCLUDE
    (
        [BatchId],
        [AdmissionId],
        [AdmissionDateTime],
        [DischargeDateTime],
        [ProcessingOutcome]
    )
    WHERE [PatientId] IS NOT NULL;
CREATE INDEX [IX_quarantine_Admission_BatchId]
    ON [quarantine].[Admission]
    (
        [BatchId],
        [QuarantinedAt]
    )
    INCLUDE
    (
        [PackageExecutionId],
        [SourceRecordIdentifier],
        [AdmissionId],
        [AdmissionNumber],
        [QuarantineReasonCode],
        [QuarantineStatus]
    );
GO

CREATE INDEX [IX_quarantine_Admission_PackageExecutionId]
    ON [quarantine].[Admission]
    (
        [PackageExecutionId],
        [QuarantinedAt]
    );
GO

CREATE INDEX [IX_quarantine_Admission_QuarantineStatus]
    ON [quarantine].[Admission]
    (
        [QuarantineStatus]
    )
    INCLUDE
    (
        [BatchId],
        [SourceRecordIdentifier],
        [QuarantineReasonCode],
        [QuarantinedAt],
        [CorrectedAt],
        [ReplayedAt]
    );
GO

CREATE INDEX [IX_quarantine_Admission_SourceRecordIdentifier]
    ON [quarantine].[Admission]
    (
        [SourceSystemCode],
        [SourceRecordIdentifier]
    )
    INCLUDE
    (
        [BatchId],
        [AdmissionId],
        [AdmissionNumber],
        [QuarantineStatus]
    );
GO

CREATE INDEX [IX_quarantine_Admission_ReplayRequestReference]
    ON [quarantine].[Admission]
    (
        [ReplayRequestReference]
    )
    WHERE [ReplayRequestReference] IS NOT NULL;
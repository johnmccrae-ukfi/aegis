CREATE INDEX [IX_replay_ReplayRequest_OriginalBatchId]
    ON [replay].[ReplayRequest]
    (
        [OriginalBatchId],
        [RequestedAt]
    )
    INCLUDE
    (
        [ReplayScope],
        [ReplayStatus],
        [SourceObject],
        [SourceRecordIdentifier]
    );
GO

CREATE INDEX [IX_replay_ReplayRequest_DataQualityExceptionId]
    ON [replay].[ReplayRequest]
    (
        [DataQualityExceptionId]
    )
    WHERE [DataQualityExceptionId] IS NOT NULL;
GO

CREATE INDEX [IX_replay_ReplayRequest_ReplayStatus]
    ON [replay].[ReplayRequest]
    (
        [ReplayStatus]
    )
    INCLUDE
    (
        [OriginalBatchId],
        [ReplayScope],
        [RequestedAt],
        [AuthorisedAt],
        [CompletedAt]
    );
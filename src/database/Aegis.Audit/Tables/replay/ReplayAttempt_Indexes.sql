CREATE INDEX [IX_replay_ReplayAttempt_ReplayRequestId]
    ON [replay].[ReplayAttempt]
    (
        [ReplayRequestId],
        [AttemptNumber]
    )
    INCLUDE
    (
        [ReplayBatchId],
        [PackageExecutionId],
        [AttemptStatus],
        [StartedAt],
        [CompletedAt]
    );
GO

CREATE INDEX [IX_replay_ReplayAttempt_ReplayBatchId]
    ON [replay].[ReplayAttempt]
    (
        [ReplayBatchId]
    )
    INCLUDE
    (
        [ReplayRequestId],
        [AttemptNumber],
        [AttemptStatus],
        [StartedAt]
    );
GO

CREATE INDEX [IX_replay_ReplayAttempt_AttemptStatus]
    ON [replay].[ReplayAttempt]
    (
        [AttemptStatus]
    )
    INCLUDE
    (
        [ReplayRequestId],
        [ReplayBatchId],
        [StartedAt],
        [CompletedAt]
    );
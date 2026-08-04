CREATE VIEW [reporting].[AdmissionAnalysis]
AS
SELECT
    /* Analytical grain and identifiers */
    a.[CuratedAdmissionId],
    a.[AdmissionId],
    a.[AdmissionNumber],
    a.[PatientId],
    a.[PatientPathwayId],

    /* Organisation and site relationships */
    a.[OrganisationId],
    a.[SiteId],

    /* Date and time attributes */
    a.[AdmissionDateTime],
    CONVERT(date, a.[AdmissionDateTime]) AS [AdmissionDate],
    a.[DischargeDateTime],
    CONVERT(date, a.[DischargeDateTime]) AS [DischargeDate],

    /* Admission classifications */
    a.[AdmissionMethodCode],
    a.[AdmissionSourceCode],
    a.[PatientClassificationCode],
    a.[IntendedManagementCode],
    a.[AdministrativeCategoryCode],
    a.[LegalStatusCode],

    /* Discharge classifications */
    a.[DischargeMethodCode],
    a.[DischargeDestinationCode],

    /* Admission state */
    a.[AdmissionStatusCode],

    CAST(
        CASE
            WHEN a.[DischargeDateTime] IS NULL THEN 1
            ELSE 0
        END
        AS bit
    ) AS [IsOpenAdmission],

    CAST(
        CASE
            WHEN a.[DischargeDateTime] IS NOT NULL THEN 1
            ELSE 0
        END
        AS bit
    ) AS [IsDischargedAdmission],

    /* Completed length of stay */
    CAST(
        CASE
            WHEN a.[DischargeDateTime] IS NULL THEN NULL
            ELSE
                DATEDIFF(
                    MINUTE,
                    a.[AdmissionDateTime],
                    a.[DischargeDateTime]
                ) / 1440.0
        END
        AS decimal(10, 2)
    ) AS [CompletedLengthOfStayDays],

    CASE
        WHEN a.[DischargeDateTime] IS NULL
            THEN 'Open admission'
        WHEN DATEDIFF(
                 DAY,
                 a.[AdmissionDateTime],
                 a.[DischargeDateTime]
             ) = 0
            THEN 'Same day'
        WHEN DATEDIFF(
                 DAY,
                 a.[AdmissionDateTime],
                 a.[DischargeDateTime]
             ) BETWEEN 1 AND 2
            THEN '1-2 days'
        WHEN DATEDIFF(
                 DAY,
                 a.[AdmissionDateTime],
                 a.[DischargeDateTime]
             ) BETWEEN 3 AND 6
            THEN '3-6 days'
        WHEN DATEDIFF(
                 DAY,
                 a.[AdmissionDateTime],
                 a.[DischargeDateTime]
             ) BETWEEN 7 AND 13
            THEN '7-13 days'
        ELSE '14+ days'
    END AS [LengthOfStayBand],

    CASE
        WHEN a.[DischargeDateTime] IS NULL THEN 0
        WHEN DATEDIFF(
                 DAY,
                 a.[AdmissionDateTime],
                 a.[DischargeDateTime]
             ) = 0
            THEN 1
        WHEN DATEDIFF(
                 DAY,
                 a.[AdmissionDateTime],
                 a.[DischargeDateTime]
             ) BETWEEN 1 AND 2
            THEN 2
        WHEN DATEDIFF(
                 DAY,
                 a.[AdmissionDateTime],
                 a.[DischargeDateTime]
             ) BETWEEN 3 AND 6
            THEN 3
        WHEN DATEDIFF(
                 DAY,
                 a.[AdmissionDateTime],
                 a.[DischargeDateTime]
             ) BETWEEN 7 AND 13
            THEN 4
        ELSE 5
    END AS [LengthOfStayBandSort],

    /* Additive analytical flags */
    CAST(1 AS int) AS [AdmissionCount],
    CASE
        WHEN a.[DischargeDateTime] IS NULL THEN 1
        ELSE 0
    END AS [OpenAdmissionCount],
    CASE
        WHEN a.[DischargeDateTime] IS NOT NULL THEN 1
        ELSE 0
    END AS [DischargedAdmissionCount],

    /* Source-to-curated migration lineage */
    a.[StagingAdmissionId],
    a.[LandingAdmissionId],
    a.[BatchId],
    a.[PackageExecutionId],
    a.[SourceSystemCode],
    a.[SourceRecordIdentifier],
    a.[SourceRowNumber],
    a.[AcceptedAt],
    a.[CuratedAt],

    /* Source record metadata */
    a.[RecordCreatedAt],
    a.[RecordUpdatedAt],
    a.[IsDeleted]
FROM [curated].[Admission] AS a
WHERE a.[IsDeleted] = 0
  AND a.[IsCurrent] = 1;
GO
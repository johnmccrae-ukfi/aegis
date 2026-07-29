USE [Aegis_Staging];
GO

SET NOCOUNT ON;
GO

/*
    Aegis Day 4
    Accepted Admissions analytical profiling

    Purpose:
    - confirm the accepted Admissions baseline;
    - inspect date coverage;
    - inspect open/discharged status;
    - inspect analytical classification values;
    - validate organisation and site references;
    - inspect length-of-stay distribution;
    - confirm source-to-curated lineage.
*/

PRINT '1. Accepted Admissions baseline';
PRINT '--------------------------------';

SELECT
    COUNT_BIG(*) AS AdmissionCount,
    COUNT_BIG(DISTINCT AdmissionId) AS DistinctAdmissionCount,
    COUNT_BIG(DISTINCT PatientId) AS DistinctPatientCount,
    SUM(CASE WHEN DischargeDateTime IS NULL THEN 1 ELSE 0 END) AS OpenAdmissionCount,
    SUM(CASE WHEN DischargeDateTime IS NOT NULL THEN 1 ELSE 0 END) AS DischargedAdmissionCount,
    SUM(CASE WHEN IsDeleted = 1 THEN 1 ELSE 0 END) AS DeletedAdmissionCount
FROM curated.Admission;


PRINT '';
PRINT '2. Admission and discharge date coverage';
PRINT '----------------------------------------';

SELECT
    MIN(CAST(AdmissionDateTime AS date)) AS EarliestAdmissionDate,
    MAX(CAST(AdmissionDateTime AS date)) AS LatestAdmissionDate,
    MIN(CAST(DischargeDateTime AS date)) AS EarliestDischargeDate,
    MAX(CAST(DischargeDateTime AS date)) AS LatestDischargeDate
FROM curated.Admission;


PRINT '';
PRINT '3. Admission status';
PRINT '-------------------';

SELECT
    COALESCE(NULLIF(LTRIM(RTRIM(AdmissionStatusCode)), ''), '(NULL OR BLANK)')
        AS AdmissionStatusCode,
    COUNT_BIG(*) AS AdmissionCount
FROM curated.Admission
GROUP BY
    COALESCE(NULLIF(LTRIM(RTRIM(AdmissionStatusCode)), ''), '(NULL OR BLANK)')
ORDER BY
    AdmissionCount DESC,
    AdmissionStatusCode;


PRINT '';
PRINT '4. Admission method';
PRINT '-------------------';

SELECT
    COALESCE(NULLIF(LTRIM(RTRIM(AdmissionMethodCode)), ''), '(NULL OR BLANK)')
        AS AdmissionMethodCode,
    COUNT_BIG(*) AS AdmissionCount
FROM curated.Admission
GROUP BY
    COALESCE(NULLIF(LTRIM(RTRIM(AdmissionMethodCode)), ''), '(NULL OR BLANK)')
ORDER BY
    AdmissionCount DESC,
    AdmissionMethodCode;


PRINT '';
PRINT '5. Admission source';
PRINT '-------------------';

SELECT
    COALESCE(NULLIF(LTRIM(RTRIM(AdmissionSourceCode)), ''), '(NULL OR BLANK)')
        AS AdmissionSourceCode,
    COUNT_BIG(*) AS AdmissionCount
FROM curated.Admission
GROUP BY
    COALESCE(NULLIF(LTRIM(RTRIM(AdmissionSourceCode)), ''), '(NULL OR BLANK)')
ORDER BY
    AdmissionCount DESC,
    AdmissionSourceCode;


PRINT '';
PRINT '6. Patient classification';
PRINT '--------------------------';

SELECT
    COALESCE(NULLIF(LTRIM(RTRIM(PatientClassificationCode)), ''), '(NULL OR BLANK)')
        AS PatientClassificationCode,
    COUNT_BIG(*) AS AdmissionCount
FROM curated.Admission
GROUP BY
    COALESCE(NULLIF(LTRIM(RTRIM(PatientClassificationCode)), ''), '(NULL OR BLANK)')
ORDER BY
    AdmissionCount DESC,
    PatientClassificationCode;


PRINT '';
PRINT '7. Intended management';
PRINT '----------------------';

SELECT
    COALESCE(NULLIF(LTRIM(RTRIM(IntendedManagementCode)), ''), '(NULL OR BLANK)')
        AS IntendedManagementCode,
    COUNT_BIG(*) AS AdmissionCount
FROM curated.Admission
GROUP BY
    COALESCE(NULLIF(LTRIM(RTRIM(IntendedManagementCode)), ''), '(NULL OR BLANK)')
ORDER BY
    AdmissionCount DESC,
    IntendedManagementCode;


PRINT '';
PRINT '8. Administrative category';
PRINT '--------------------------';

SELECT
    COALESCE(NULLIF(LTRIM(RTRIM(AdministrativeCategoryCode)), ''), '(NULL OR BLANK)')
        AS AdministrativeCategoryCode,
    COUNT_BIG(*) AS AdmissionCount
FROM curated.Admission
GROUP BY
    COALESCE(NULLIF(LTRIM(RTRIM(AdministrativeCategoryCode)), ''), '(NULL OR BLANK)')
ORDER BY
    AdmissionCount DESC,
    AdministrativeCategoryCode;


PRINT '';
PRINT '9. Legal status';
PRINT '---------------';

SELECT
    COALESCE(NULLIF(LTRIM(RTRIM(LegalStatusCode)), ''), '(NULL OR BLANK)')
        AS LegalStatusCode,
    COUNT_BIG(*) AS AdmissionCount
FROM curated.Admission
GROUP BY
    COALESCE(NULLIF(LTRIM(RTRIM(LegalStatusCode)), ''), '(NULL OR BLANK)')
ORDER BY
    AdmissionCount DESC,
    LegalStatusCode;


PRINT '';
PRINT '10. Discharge method';
PRINT '--------------------';

SELECT
    COALESCE(NULLIF(LTRIM(RTRIM(DischargeMethodCode)), ''), '(NULL OR BLANK)')
        AS DischargeMethodCode,
    COUNT_BIG(*) AS AdmissionCount
FROM curated.Admission
GROUP BY
    COALESCE(NULLIF(LTRIM(RTRIM(DischargeMethodCode)), ''), '(NULL OR BLANK)')
ORDER BY
    AdmissionCount DESC,
    DischargeMethodCode;


PRINT '';
PRINT '11. Discharge destination';
PRINT '-------------------------';

SELECT
    COALESCE(NULLIF(LTRIM(RTRIM(DischargeDestinationCode)), ''), '(NULL OR BLANK)')
        AS DischargeDestinationCode,
    COUNT_BIG(*) AS AdmissionCount
FROM curated.Admission
GROUP BY
    COALESCE(NULLIF(LTRIM(RTRIM(DischargeDestinationCode)), ''), '(NULL OR BLANK)')
ORDER BY
    AdmissionCount DESC,
    DischargeDestinationCode;


PRINT '';
PRINT '12. Organisation and site key profile';
PRINT '-------------------------------------';

SELECT
    OrganisationId,
    SiteId,
    COUNT_BIG(*) AS AdmissionCount
FROM curated.Admission
GROUP BY
    OrganisationId,
    SiteId
ORDER BY
    OrganisationId,
    SiteId;


PRINT '';
PRINT '13. Organisation and site reference validation';
PRINT '----------------------------------------------';

SELECT
    COUNT_BIG(*) AS AdmissionCount,
    SUM(CASE WHEN o.OrganisationId IS NULL THEN 1 ELSE 0 END)
        AS UnknownOrganisationCount,
    SUM(CASE WHEN s.SiteId IS NULL THEN 1 ELSE 0 END)
        AS UnknownSiteCount,
    SUM(
        CASE
            WHEN s.SiteId IS NOT NULL
             AND s.OrganisationId <> a.OrganisationId
                THEN 1
            ELSE 0
        END
    ) AS SiteOrganisationMismatchCount
FROM curated.Admission AS a
LEFT JOIN Aegis_Source.ref.Organisation AS o
    ON o.OrganisationId = a.OrganisationId
LEFT JOIN Aegis_Source.ref.Site AS s
    ON s.SiteId = a.SiteId;


PRINT '';
PRINT '14. Organisation and site activity';
PRINT '----------------------------------';

SELECT
    o.OrganisationCode,
    o.OrganisationName,
    s.SiteCode,
    s.SiteName,
    COUNT_BIG(*) AS AdmissionCount,
    SUM(CASE WHEN a.DischargeDateTime IS NULL THEN 1 ELSE 0 END)
        AS OpenAdmissionCount,
    SUM(CASE WHEN a.DischargeDateTime IS NOT NULL THEN 1 ELSE 0 END)
        AS DischargedAdmissionCount
FROM curated.Admission AS a
INNER JOIN Aegis_Source.ref.Organisation AS o
    ON o.OrganisationId = a.OrganisationId
INNER JOIN Aegis_Source.ref.Site AS s
    ON s.SiteId = a.SiteId
   AND s.OrganisationId = a.OrganisationId
GROUP BY
    o.OrganisationCode,
    o.OrganisationName,
    s.SiteCode,
    s.SiteName
ORDER BY
    o.OrganisationCode,
    s.SiteCode;


PRINT '';
PRINT '15. Completed length-of-stay profile';
PRINT '------------------------------------';

SELECT
    COUNT_BIG(*) AS DischargedAdmissionCount,
    MIN(DATEDIFF(DAY, AdmissionDateTime, DischargeDateTime))
        AS MinimumLengthOfStayDays,
    MAX(DATEDIFF(DAY, AdmissionDateTime, DischargeDateTime))
        AS MaximumLengthOfStayDays,
    CAST(
        AVG(
            CAST(
                DATEDIFF(MINUTE, AdmissionDateTime, DischargeDateTime)
                AS decimal(18, 2)
            )
        ) / 1440.0
        AS decimal(18, 2)
    ) AS AverageLengthOfStayDays
FROM curated.Admission
WHERE DischargeDateTime IS NOT NULL;


PRINT '';
PRINT '16. Completed length-of-stay bands';
PRINT '----------------------------------';

WITH CompletedAdmissions AS
(
    SELECT
        CASE
            WHEN DATEDIFF(DAY, AdmissionDateTime, DischargeDateTime) = 0
                THEN 'Same day'
            WHEN DATEDIFF(DAY, AdmissionDateTime, DischargeDateTime)
                 BETWEEN 1 AND 2
                THEN '1-2 days'
            WHEN DATEDIFF(DAY, AdmissionDateTime, DischargeDateTime)
                 BETWEEN 3 AND 6
                THEN '3-6 days'
            WHEN DATEDIFF(DAY, AdmissionDateTime, DischargeDateTime)
                 BETWEEN 7 AND 13
                THEN '7-13 days'
            WHEN DATEDIFF(DAY, AdmissionDateTime, DischargeDateTime) >= 14
                THEN '14+ days'
            ELSE 'Invalid'
        END AS LengthOfStayBand,
        CASE
            WHEN DATEDIFF(DAY, AdmissionDateTime, DischargeDateTime) = 0
                THEN 1
            WHEN DATEDIFF(DAY, AdmissionDateTime, DischargeDateTime)
                 BETWEEN 1 AND 2
                THEN 2
            WHEN DATEDIFF(DAY, AdmissionDateTime, DischargeDateTime)
                 BETWEEN 3 AND 6
                THEN 3
            WHEN DATEDIFF(DAY, AdmissionDateTime, DischargeDateTime)
                 BETWEEN 7 AND 13
                THEN 4
            WHEN DATEDIFF(DAY, AdmissionDateTime, DischargeDateTime) >= 14
                THEN 5
            ELSE 99
        END AS LengthOfStayBandSort
    FROM curated.Admission
    WHERE DischargeDateTime IS NOT NULL
)
SELECT
    LengthOfStayBand,
    COUNT_BIG(*) AS AdmissionCount
FROM CompletedAdmissions
GROUP BY
    LengthOfStayBand,
    LengthOfStayBandSort
ORDER BY
    LengthOfStayBandSort;


PRINT '';
PRINT '17. Source-to-curated lineage';
PRINT '-----------------------------';

SELECT
    SourceSystemCode,
    BatchId,
    PackageExecutionId,
    COUNT_BIG(*) AS CuratedAdmissionCount,
    MIN(AcceptedAt) AS FirstAcceptedAt,
    MAX(AcceptedAt) AS LastAcceptedAt,
    MIN(CuratedAt) AS FirstCuratedAt,
    MAX(CuratedAt) AS LastCuratedAt
FROM curated.Admission
GROUP BY
    SourceSystemCode,
    BatchId,
    PackageExecutionId
ORDER BY
    BatchId,
    PackageExecutionId,
    SourceSystemCode;


PRINT '';
PRINT '18. Curated-row lineage completeness';
PRINT '------------------------------------';

SELECT
    COUNT_BIG(*) AS AdmissionCount,
    SUM(CASE WHEN StagingAdmissionId IS NULL THEN 1 ELSE 0 END)
        AS MissingStagingAdmissionIdCount,
    SUM(CASE WHEN LandingAdmissionId IS NULL THEN 1 ELSE 0 END)
        AS MissingLandingAdmissionIdCount,
    SUM(CASE WHEN BatchId IS NULL THEN 1 ELSE 0 END)
        AS MissingBatchIdCount,
    SUM(CASE WHEN PackageExecutionId IS NULL THEN 1 ELSE 0 END)
        AS MissingPackageExecutionIdCount,
    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(SourceSystemCode)), '') IS NULL
                THEN 1
            ELSE 0
        END
    ) AS MissingSourceSystemCodeCount,
    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(SourceRecordIdentifier)), '') IS NULL
                THEN 1
            ELSE 0
        END
    ) AS MissingSourceRecordIdentifierCount
FROM curated.Admission;
GO
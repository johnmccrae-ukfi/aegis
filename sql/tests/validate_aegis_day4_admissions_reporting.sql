USE [Aegis_Staging];
GO

SET NOCOUNT ON;
GO

/*
    Aegis Day 4
    Admissions reporting-layer validation

    Purpose:
    - validate the reporting schema and Admissions analytical view;
    - reconcile the reporting layer to the accepted curated dataset;
    - validate date coverage, status counts, lineage and reference integrity;
    - provide the SQL-side control supporting the SSAS Tabular model.

    The deployed SSAS model is independently validated using:
    src/ssas/Aegis.Analysis/validation/validate_aegis_admissions_model.dax
*/

DECLARE @Results TABLE
(
    CheckNumber int IDENTITY(1, 1) NOT NULL,
    CheckName nvarchar(200) NOT NULL,
    ExpectedValue nvarchar(200) NOT NULL,
    ActualValue nvarchar(200) NOT NULL,
    Passed bit NOT NULL
);

/* 1. Reporting schema exists */
INSERT @Results
(
    CheckName,
    ExpectedValue,
    ActualValue,
    Passed
)
SELECT
    N'Reporting schema exists',
    N'1',
    CONVERT(nvarchar(200), COUNT_BIG(*)),
    CONVERT(bit, CASE WHEN COUNT_BIG(*) = 1 THEN 1 ELSE 0 END)
FROM sys.schemas
WHERE name = N'reporting';


/* 2. Admissions reporting view exists */
INSERT @Results
(
    CheckName,
    ExpectedValue,
    ActualValue,
    Passed
)
SELECT
    N'AdmissionAnalysis view exists',
    N'1',
    CONVERT(nvarchar(200), COUNT_BIG(*)),
    CONVERT(bit, CASE WHEN COUNT_BIG(*) = 1 THEN 1 ELSE 0 END)
FROM sys.views AS v
INNER JOIN sys.schemas AS s
    ON s.schema_id = v.schema_id
WHERE
    s.name = N'reporting'
    AND v.name = N'AdmissionAnalysis';


/* 3. Reporting row count */
INSERT @Results
SELECT
    N'Reporting Admission count',
    N'1600',
    CONVERT(nvarchar(200), COUNT_BIG(*)),
    CONVERT(bit, CASE WHEN COUNT_BIG(*) = 1600 THEN 1 ELSE 0 END)
FROM reporting.AdmissionAnalysis;


/* 4. Distinct Admission count */
INSERT @Results
SELECT
    N'Distinct Admission count',
    N'1600',
    CONVERT(nvarchar(200), COUNT_BIG(DISTINCT AdmissionId)),
    CONVERT(
        bit,
        CASE
            WHEN COUNT_BIG(DISTINCT AdmissionId) = 1600 THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis;


/* 5. Distinct patient count */
INSERT @Results
SELECT
    N'Distinct patient count',
    N'708',
    CONVERT(nvarchar(200), COUNT_BIG(DISTINCT PatientId)),
    CONVERT(
        bit,
        CASE
            WHEN COUNT_BIG(DISTINCT PatientId) = 708 THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis;


/* 6. Open Admission count */
INSERT @Results
SELECT
    N'Open Admission count',
    N'192',
    CONVERT(nvarchar(200), SUM(OpenAdmissionCount)),
    CONVERT(
        bit,
        CASE
            WHEN SUM(OpenAdmissionCount) = 192 THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis;


/* 7. Discharged Admission count */
INSERT @Results
SELECT
    N'Discharged Admission count',
    N'1408',
    CONVERT(nvarchar(200), SUM(DischargedAdmissionCount)),
    CONVERT(
        bit,
        CASE
            WHEN SUM(DischargedAdmissionCount) = 1408 THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis;


/* 8. Reporting to current curated snapshot reconciliation */
INSERT @Results
SELECT
    N'Reporting rows reconcile to current curated rows',
    CONVERT
    (
        nvarchar(200),
        (
            SELECT COUNT_BIG(*)
            FROM curated.Admission
            WHERE
                IsDeleted = 0
                AND IsCurrent = 1
        )
    ),
    CONVERT(nvarchar(200), COUNT_BIG(*)),
    CONVERT
    (
        bit,
        CASE
            WHEN COUNT_BIG(*) =
            (
                SELECT COUNT_BIG(*)
                FROM curated.Admission
                WHERE
                    IsDeleted = 0
                    AND IsCurrent = 1
            )
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis;


/* 9. Admission flag reconciliation */
INSERT @Results
SELECT
    N'Admission additive flags reconcile',
    N'1600',
    CONVERT(
        nvarchar(200),
        SUM(OpenAdmissionCount) + SUM(DischargedAdmissionCount)
    ),
    CONVERT(
        bit,
        CASE
            WHEN SUM(OpenAdmissionCount)
               + SUM(DischargedAdmissionCount) = 1600
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis;


/* 10. Open Admission rules */
INSERT @Results
SELECT
    N'Open Admissions have no discharge date',
    N'0',
    CONVERT(
        nvarchar(200),
        SUM(
            CASE
                WHEN IsOpenAdmission = 1
                 AND DischargeDateTime IS NOT NULL
                    THEN 1
                ELSE 0
            END
        )
    ),
    CONVERT(
        bit,
        CASE
            WHEN SUM(
                CASE
                    WHEN IsOpenAdmission = 1
                     AND DischargeDateTime IS NOT NULL
                        THEN 1
                    ELSE 0
                END
            ) = 0
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis;


/* 11. Discharged Admission rules */
INSERT @Results
SELECT
    N'Discharged Admissions have discharge dates',
    N'0',
    CONVERT(
        nvarchar(200),
        SUM(
            CASE
                WHEN IsDischargedAdmission = 1
                 AND DischargeDateTime IS NULL
                    THEN 1
                ELSE 0
            END
        )
    ),
    CONVERT(
        bit,
        CASE
            WHEN SUM(
                CASE
                    WHEN IsDischargedAdmission = 1
                     AND DischargeDateTime IS NULL
                        THEN 1
                    ELSE 0
                END
            ) = 0
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis;


/* 12. Admission date minimum */
INSERT @Results
SELECT
    N'Earliest Admission date',
    N'2023-01-04',
    CONVERT(nvarchar(200), MIN(AdmissionDate), 23),
    CONVERT(
        bit,
        CASE
            WHEN MIN(AdmissionDate) = CONVERT(date, '2023-01-04')
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis;


/* 13. Admission date maximum */
INSERT @Results
SELECT
    N'Latest Admission date',
    N'2026-07-25',
    CONVERT(nvarchar(200), MAX(AdmissionDate), 23),
    CONVERT(
        bit,
        CASE
            WHEN MAX(AdmissionDate) = CONVERT(date, '2026-07-25')
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis;


/* 14. Discharge date minimum */
INSERT @Results
SELECT
    N'Earliest discharge date',
    N'2023-01-09',
    CONVERT(nvarchar(200), MIN(DischargeDate), 23),
    CONVERT(
        bit,
        CASE
            WHEN MIN(DischargeDate) = CONVERT(date, '2023-01-09')
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis;


/* 15. Discharge date maximum */
INSERT @Results
SELECT
    N'Latest discharge date',
    N'2026-07-19',
    CONVERT(nvarchar(200), MAX(DischargeDate), 23),
    CONVERT(
        bit,
        CASE
            WHEN MAX(DischargeDate) = CONVERT(date, '2026-07-19')
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis;


/* 16. Completed LOS minimum */
INSERT @Results
SELECT
    N'Minimum completed length of stay',
    N'0.33',
    CONVERT(
        nvarchar(200),
        CAST(MIN(CompletedLengthOfStayDays) AS decimal(10, 2))
    ),
    CONVERT(
        bit,
        CASE
            WHEN CAST(MIN(CompletedLengthOfStayDays) AS decimal(10, 2))
                 = CAST(0.33 AS decimal(10, 2))
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis
WHERE IsDischargedAdmission = 1;


/* 17. Completed LOS maximum */
INSERT @Results
SELECT
    N'Maximum completed length of stay',
    N'14.00',
    CONVERT(
        nvarchar(200),
        CAST(MAX(CompletedLengthOfStayDays) AS decimal(10, 2))
    ),
    CONVERT(
        bit,
        CASE
            WHEN CAST(MAX(CompletedLengthOfStayDays) AS decimal(10, 2))
                 <= CAST(15.00 AS decimal(10, 2))
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis
WHERE IsDischargedAdmission = 1;


/* 18. Completed LOS average */
INSERT @Results
SELECT
    N'Average completed length of stay',
    N'7.43',
    CONVERT(
        nvarchar(200),
        CAST(AVG(CompletedLengthOfStayDays) AS decimal(10, 2))
    ),
    CONVERT(
        bit,
        CASE
            WHEN CAST(AVG(CompletedLengthOfStayDays) AS decimal(10, 2))
                 = CAST(7.43 AS decimal(10, 2))
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis
WHERE IsDischargedAdmission = 1;


/* 19. Missing lineage */
INSERT @Results
SELECT
    N'Rows with incomplete lineage',
    N'0',
    CONVERT(
        nvarchar(200),
        SUM(
            CASE
                WHEN StagingAdmissionId IS NULL
                  OR LandingAdmissionId IS NULL
                  OR BatchId IS NULL
                  OR PackageExecutionId IS NULL
                  OR NULLIF(LTRIM(RTRIM(SourceSystemCode)), '') IS NULL
                  OR NULLIF(LTRIM(RTRIM(SourceRecordIdentifier)), '') IS NULL
                    THEN 1
                ELSE 0
            END
        )
    ),
    CONVERT(
        bit,
        CASE
            WHEN SUM(
                CASE
                    WHEN StagingAdmissionId IS NULL
                      OR LandingAdmissionId IS NULL
                      OR BatchId IS NULL
                      OR PackageExecutionId IS NULL
                      OR NULLIF(LTRIM(RTRIM(SourceSystemCode)), '') IS NULL
                      OR NULLIF(LTRIM(RTRIM(SourceRecordIdentifier)), '') IS NULL
                        THEN 1
                    ELSE 0
                END
            ) = 0
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis;


/* 20. Unknown organisation references */
INSERT @Results
SELECT
    N'Unknown organisation references',
    N'0',
    CONVERT(
        nvarchar(200),
        SUM(CASE WHEN o.OrganisationId IS NULL THEN 1 ELSE 0 END)
    ),
    CONVERT(
        bit,
        CASE
            WHEN SUM(
                CASE WHEN o.OrganisationId IS NULL THEN 1 ELSE 0 END
            ) = 0
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis AS a
LEFT JOIN Aegis_Source.ref.Organisation AS o
    ON o.OrganisationId = a.OrganisationId;


/* 21. Unknown site references */
INSERT @Results
SELECT
    N'Unknown site references',
    N'0',
    CONVERT(
        nvarchar(200),
        SUM(CASE WHEN s.SiteId IS NULL THEN 1 ELSE 0 END)
    ),
    CONVERT(
        bit,
        CASE
            WHEN SUM(
                CASE WHEN s.SiteId IS NULL THEN 1 ELSE 0 END
            ) = 0
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis AS a
LEFT JOIN Aegis_Source.ref.Site AS s
    ON s.SiteId = a.SiteId;


/* 22. Site-to-organisation consistency */
INSERT @Results
SELECT
    N'Site and organisation relationships are consistent',
    N'0',
    CONVERT(
        nvarchar(200),
        SUM(
            CASE
                WHEN s.SiteId IS NOT NULL
                 AND s.OrganisationId <> a.OrganisationId
                    THEN 1
                ELSE 0
            END
        )
    ),
    CONVERT(
        bit,
        CASE
            WHEN SUM(
                CASE
                    WHEN s.SiteId IS NOT NULL
                     AND s.OrganisationId <> a.OrganisationId
                        THEN 1
                    ELSE 0
                END
            ) = 0
                THEN 1
            ELSE 0
        END
    )
FROM reporting.AdmissionAnalysis AS a
LEFT JOIN Aegis_Source.ref.Site AS s
    ON s.SiteId = a.SiteId;


/* Final results */
SELECT
    CheckNumber,
    CheckName,
    ExpectedValue,
    ActualValue,
    Passed
FROM @Results
ORDER BY
    CheckNumber;

DECLARE @Passed int =
(
    SELECT COUNT(*)
    FROM @Results
    WHERE Passed = 1
);

DECLARE @Failed int =
(
    SELECT COUNT(*)
    FROM @Results
    WHERE Passed = 0
);

SELECT
    COUNT(*) AS TotalChecks,
    @Passed AS PassedChecks,
    @Failed AS FailedChecks
FROM @Results;

IF @Failed > 0
BEGIN
    THROW 51000,
        'Aegis Day 4 Admissions reporting validation failed.',
        1;
END;
GO
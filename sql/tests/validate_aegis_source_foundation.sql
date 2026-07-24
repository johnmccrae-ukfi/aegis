/*
    Aegis Source Foundation Validation

    Confirms that the initial source database objects were deployed.
*/

USE [Aegis_Source];
GO

SET NOCOUNT ON;
GO

DECLARE @ValidationResults TABLE
(
    CheckName     VARCHAR(100) NOT NULL,
    Passed        BIT          NOT NULL,
    Detail        NVARCHAR(500) NULL
);

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas schema exists',
    CASE WHEN SCHEMA_ID(N'pas') IS NOT NULL THEN 1 ELSE 0 END,
    N'Expected schema: pas';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'epr schema exists',
    CASE WHEN SCHEMA_ID(N'epr') IS NOT NULL THEN 1 ELSE 0 END,
    N'Expected schema: epr';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'ref schema exists',
    CASE WHEN SCHEMA_ID(N'ref') IS NOT NULL THEN 1 ELSE 0 END,
    N'Expected schema: ref';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.Patient exists',
    CASE WHEN OBJECT_ID(N'pas.Patient', N'U') IS NOT NULL THEN 1 ELSE 0 END,
    N'Expected table: pas.Patient';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'HospitalNumber column exists',
    CASE
        WHEN COL_LENGTH(N'pas.Patient', N'HospitalNumber') IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'Expected column: pas.Patient.HospitalNumber';

SELECT
    CheckName,
    Passed,
    Detail
FROM @ValidationResults
ORDER BY CheckName;

IF EXISTS
(
    SELECT 1
    FROM @ValidationResults
    WHERE Passed = 0
)
BEGIN
    THROW 51000, 'Aegis source foundation validation failed.', 1;
END;

PRINT 'Aegis source foundation validation passed.';
GO
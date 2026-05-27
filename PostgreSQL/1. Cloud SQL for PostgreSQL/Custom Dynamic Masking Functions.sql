CREATE ROLE edsunmaskedrole NOLOGIN;

--helper function done
CREATE OR REPLACE FUNCTION public.canviewunmasked()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT pg_has_role(current_user, 'edsunmaskedrole', 'MEMBER');
$$;



-- Basic partial mask (reusable) completed
CREATE OR REPLACE FUNCTION public.maskpartial(value text, prefixlen int, suffixlen int, mask text DEFAULT 'XXXX')
RETURNS text
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
  vlen int := COALESCE(length(value), 0);
  pre  text := CASE WHEN value IS NOT NULL THEN substr(value, 1, GREATEST(prefixlen, 0)) END;
  suf  text := CASE WHEN value IS NOT NULL THEN substr(value, GREATEST(vlen - suffixlen + 1, 1)) END;
BEGIN
  IF value IS NULL THEN
    RETURN NULL;
  END IF;
  IF vlen <= prefixlen + suffixlen THEN
    RETURN mask; -- or RETURN value if you prefer
  END IF;
  RETURN COALESCE(pre, '') || mask || COALESCE(suf, '');
END $$;
 
-- Email mask similar to SQL Server's email() completed
CREATE OR REPLACE FUNCTION public.maskemail(value text)
RETURNS text
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
  atpos int;
  namepart text;
  domainpart text;
BEGIN
  IF value IS NULL THEN
    RETURN NULL;
  END IF;
  atpos := position('@' IN value);
  IF atpos = 0 THEN
    RETURN public.maskpartial(value, 1, 1, 'XXXX');
  END IF;

  namepart := substr(value, 1, atpos - 1);
  domainpart := substr(value, atpos + 1);

  IF length(namepart) <= 2 THEN
    RETURN 'x@' || domainpart;
  END IF;

  RETURN substr(namepart, 1, 1) || 'XXXX' || substr(namepart, length(namepart)) || '@' || domainpart;
END $$;

-- Wrappers that expose original if caller is in unmaskedrole
CREATE OR REPLACE FUNCTION public.maybepartial(value text, prefixlen int, suffixlen int, mask text DEFAULT 'XXXX')
RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT CASE WHEN public.canviewunmasked() THEN $1
              ELSE public.maskpartial($1, $2, $3, $4)
         END;
$$;
 
CREATE OR REPLACE FUNCTION public.maybeemail(value text)
RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT CASE WHEN public.canviewunmasked() THEN $1
              ELSE public.maskemail($1)
         END;
$$;
 
CREATE OR REPLACE FUNCTION public.maybedefaulttimestamp(value timestamp)
RETURNS timestamp
LANGUAGE sql STABLE AS $$
  SELECT CASE WHEN public.canviewunmasked() THEN $1 ELSE NULL::timestamp END;
$$;
 
CREATE OR REPLACE FUNCTION public.maybedefaultnumeric(value numeric)
RETURNS numeric
LANGUAGE sql STABLE AS $$
  SELECT CASE WHEN public.canviewunmasked() THEN $1 ELSE NULL::numeric END;
$$;



CREATE TABLE IF NOT EXISTS public."CentralRepositoryAssociateDetailsMIG" (
    "AssociateID"            CHAR(11)                   NOT NULL,
    "AssociateFirstName"     VARCHAR(100),
    "AssociateLastName"      VARCHAR(100),
    "AssociateMiddleInitial" VARCHAR(100),
    "EMailID"                VARCHAR(200),
    "BloodGroup"              VARCHAR(10),
    "OnsiteOffshore"         CHAR(2),
    "JobCode"                 CHAR(6),
    "DateOfBirth"             TIMESTAMP,
    "DateOfJoining"           TIMESTAMP,
    "MonthsOfExp"             DECIMAL(8, 2),
    "SupervisorID"           VARCHAR(31),
    "IsActive"                CHAR(3),
    "Gender"                  CHAR(1),
    "BirthPlace"             VARCHAR(50),
    "BirthCountry"           VARCHAR(50),
    "MaritalStatus"          VARCHAR(50),
    "PerOrg"                 CHAR(3),
    "Action"                  CHAR(3),
    "ActionDt"               TIMESTAMP,
    "EffDt"                   TIMESTAMP,
    "OriginalHireDate"      TIMESTAMP,
    "Actionreason"           CHAR(3),
    "EstabID"                 VARCHAR(35),
    "HRStatus"               CHAR(1),
    "ParentHCMLocationCode"   VARCHAR(30),
    "PresentHCMLocationCode"  VARCHAR(30),
    "DeptID"                 VARCHAR(30),
    "Company"                 CHAR(3),
    "AssociateRCD"           INTEGER,
    "AssociateSeq"           INTEGER,
    "BusinessUnit"           VARCHAR(5),
    "ParentDeptID"          VARCHAR(30),
    "JobCodeAtHire"         CHAR(6),
    "AssociateTitle"         VARCHAR(10),
    "LastUpdatedDateTime"     TIMESTAMP(7)               NOT NULL,
    "PortingStatus"           CHAR(1),
    "BirthState"             VARCHAR(60),
    "HOLIDAYSCHEDULE"        VARCHAR(6),
    "AlternateId"             VARCHAR(11),
    "FLSASTATUS"             CHAR(1),
    "STDHOURS"               NUMERIC(6, 2),
    "EMPLTYPE"               CHAR(1),
    "FULLPARTTIME"          CHAR(1),
    "ContractorEndDate"     DATE,
    "Namesuffix"             VARCHAR(15),
    "NamechangeEFFDT"       TIMESTAMP,
    "EMAILFLAG"              CHAR(1),
    CONSTRAINT "PKCentralRepositoryAssociateDetailsMIG"
        PRIMARY KEY ("AssociateID")
);



CREATE VIEW public."vCentralRepositoryAssociateDetailsMIG"
--WITH (securitybarrier = true) 
AS
SELECT
    "AssociateID", -- If you want this masked too, change to maybepartial("AssociateID"::text, 2, 2, 'XXXX')
    public.maybepartial("AssociateFirstName"::text,     2, 2, 'XXXX') AS "AssociateFirstName",
    public.maybepartial("AssociateLastName"::text,      2, 2, 'XXXX') AS "AssociateLastName",
    public.maybepartial("AssociateMiddleInitial"::text, 2, 2, 'XXXX') AS "AssociateMiddleInitial",
    public.maybeemail("EMailID"::text)                              AS "EMailID",
    public.maybepartial("BloodGroup"::text,            2, 2, 'XXXX') AS "BloodGroup",
    "OnsiteOffshore",
    "JobCode",
    public.maybedefaulttimestamp("DateOfBirth")                     AS "DateOfBirth",
    public.maybedefaulttimestamp("DateOfJoining")                   AS "DateOfJoining",
    public.maybedefaultnumeric("MonthsOfExp")                       AS "MonthsOfExp",
    "SupervisorID",
    "IsActive",
    public.maybepartial("Gender"::text, 0, 0, 'XXXX')                AS "Gender",
    public.maybepartial("BirthPlace"::text,    2, 2, 'XXXX')        AS "BirthPlace",
    public.maybepartial("BirthCountry"::text,  2, 2, 'XXXX')        AS "BirthCountry",
    public.maybepartial("MaritalStatus"::text, 2, 2, 'XXXX')        AS "MaritalStatus",
    "PerOrg",
    "Action",
    "ActionDt",
    "EffDt",
    "OriginalHireDate",
    "Actionreason",
    "EstabID",
    "HRStatus",
    "ParentHCMLocationCode",
    "PresentHCMLocationCode",
    "DeptID",
    "Company",
    "AssociateRCD",
    "AssociateSeq",
    "BusinessUnit",
    "ParentDeptID",
    "JobCodeAtHire",
    public.maybepartial("AssociateTitle"::text, 2, 2, 'XXXX')       AS "AssociateTitle",
    "LastUpdatedDateTime",
    "PortingStatus",
    public.maybepartial("BirthState"::text, 2, 2, 'XXXX')           AS "BirthState",
    "HOLIDAYSCHEDULE",
    "AlternateId",
    "FLSASTATUS",
    "STDHOURS",
    "EMPLTYPE",
    "FULLPARTTIME",
    "ContractorEndDate",
    public.maybepartial("Namesuffix"::text, 2, 2, 'XXXX')           AS "Namesuffix",
    public.maybedefaulttimestamp("NamechangeEFFDT")               AS "NamechangeEFFDT",
    "EMAILFLAG"
FROM public."CentralRepositoryAssociateDetailsMIG";



INSERT INTO public."CentralRepositoryAssociateDetailsMIG" (
    "AssociateID", "AssociateFirstName", "AssociateLastName", "AssociateMiddleInitial",
    "EMailID", "BloodGroup", "OnsiteOffshore", "JobCode", "DateOfBirth",
    "DateOfJoining", "MonthsOfExp", "SupervisorID", "IsActive", "Gender",
    "BirthPlace", "BirthCountry", "MaritalStatus", "PerOrg", "Action",
    "ActionDt", "EffDt", "OriginalHireDate", "Actionreason", "EstabID",
    "HRStatus", "ParentHCMLocationCode", "PresentHCMLocationCode", "DeptID",
    "Company", "AssociateRCD", "AssociateSeq", "BusinessUnit", "ParentDeptID",
    "JobCodeAtHire", "AssociateTitle", "LastUpdatedDateTime", "PortingStatus",
    "BirthState", "HOLIDAYSCHEDULE", "AlternateId", "FLSASTATUS", "STDHOURS",
    "EMPLTYPE", "FULLPARTTIME", "ContractorEndDate", "Namesuffix",
    "NamechangeEFFDT", "EMAILFLAG"
) VALUES
('A0000000001', 'SRIHIMA', 'SESHA', 'V', 'srihima.s@example.com', 'O+', 'OF', 'DEV001',
'1995-01-15 00:00', '2020-08-01 10:30', 74.50, 'SUP001', 'YES', 'F', 'Chennai',
'India', 'Single', 'ORG', 'HRE', '2024-03-05 09:00', '2024-03-05 09:00',
'2020-08-01 10:30', 'H01', 'EST123', 'A', 'LOC001', 'LOC002', 'D001', 'C01',
123, 1, 'BU01', 'PD001', 'DEV000', 'Engineer',
'2025-12-31 12:34:56.7890123', 'Y', 'TN', 'H001', 'ALT00000001', 'E', 40.00,
'F', 'F', '2026-12-31', 'Jr', '2024-10-10 00:00', 'Y'),

('A0000000002', 'RAMESH', 'KUMAR', 'S', 'r.kumar@example.org', 'B-', 'ON', 'QA002',
'1990-11-30 00:00', '2018-01-10 14:10', 96.00, 'SUP002', 'YES', 'M', 'Hyderabad',
'India', 'Married', 'ORG', 'TRN', '2023-01-01 12:00', '2023-01-01 12:00',
'2018-01-10 14:10', 'T01', 'EST999', 'A', 'LOC010', 'LOC020', 'D009', 'C02',
456, 2, 'BU99', 'PD999', 'QA0002', 'SrEng',
'2025-12-30 08:00:00.0000000', 'N', 'TS', 'H002', 'ALT00000002', 'N', 45.50,
'P', 'P', NULL, NULL, NULL, 'N');



select * from public."vCentralRepositoryAssociateDetailsMIG"
revoke edsunmaskedrole from postgres
grant edsunmaskedrole to postgres




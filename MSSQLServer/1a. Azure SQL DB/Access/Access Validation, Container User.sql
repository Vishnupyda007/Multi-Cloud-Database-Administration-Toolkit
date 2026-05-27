-- ============================================================

-- Azure SQL DB — Access & Permission Diagnostic Script

-- Run this in the TARGET database (azsql1CAssistant_4139)

-- as an admin or Azure AD admin

-- ============================================================
 
-- -------------------------------------------------------

-- 1. Check if the user exists as a contained database user

-- -------------------------------------------------------

SELECT

    dp.name                     AS database_user,

    dp.type_desc                AS user_type,

    dp.authentication_type_desc AS auth_type,

    dp.default_schema_name      AS default_schema,

    dp.create_date,

    dp.modify_date

FROM sys.database_principals dp

WHERE dp.type IN ('E', 'X', 'S', 'U')   -- E=Azure AD user, X=Azure AD group, S=SQL user, U=Windows user

  AND dp.name = 'SIICSSaSqlDbTgtNp@cognizant.com';
 
-- -------------------------------------------------------

-- 2. Check role memberships for the user

-- -------------------------------------------------------

SELECT

    dp.name                     AS database_user,

    rp.name                     AS role_name

FROM sys.database_role_members drm

JOIN sys.database_principals dp ON dp.principal_id = drm.member_principal_id

JOIN sys.database_principals rp ON rp.principal_id = drm.role_principal_id

WHERE dp.name = 'SIICSSaSqlDbTgtNp@cognizant.com';
 
-- -------------------------------------------------------

-- 3. Check explicit object-level permissions granted

-- -------------------------------------------------------

SELECT

    dp.name                     AS grantee,

    perm.class_desc             AS object_class,

    OBJECT_NAME(perm.major_id)  AS object_name,

    perm.permission_name,

    perm.state_desc             AS permission_state   -- GRANT / DENY / REVOKE

FROM sys.database_permissions perm

JOIN sys.database_principals dp ON dp.principal_id = perm.grantee_principal_id

WHERE dp.name = 'SIICSSaSqlDbTgtNp@cognizant.com';
 
-- -------------------------------------------------------

-- 4. Check if user exists at SERVER level (master db)

--    Run this in master database

-- -------------------------------------------------------

SELECT

    sp.name                     AS server_login,

    sp.type_desc                AS login_type,

    sp.is_disabled,

    sp.create_date,

    sp.modify_date

FROM sys.server_principals sp

WHERE sp.name = 'SIICSSaSqlDbTgtNp@cognizant.com';
 
-- -------------------------------------------------------

-- 5. Check Azure AD admin configured on the server

--    Run this in master database

-- -------------------------------------------------------

SELECT

    dp.name                     AS aad_admin_user,

    dp.type_desc                AS type,

    dp.authentication_type_desc AS auth_type

FROM sys.database_principals dp

WHERE dp.type IN ('E', 'X')

  AND dp.name NOT LIKE '##%';
 
-- -------------------------------------------------------

-- 6. Check firewall rules (server-level)

--    Run this in master database

-- -------------------------------------------------------

SELECT

    name                        AS rule_name,

    start_ip_address,

    end_ip_address,

    create_date,

    modify_date

FROM sys.firewall_rules

ORDER BY start_ip_address;
 
-- -------------------------------------------------------

-- 7. Quick permission summary — what can this user do?

-- -------------------------------------------------------

SELECT

    perm.permission_name,

    perm.state_desc,

    perm.class_desc,

    CASE perm.class

        WHEN 0 THEN 'Database'

        WHEN 1 THEN OBJECT_NAME(perm.major_id)

        WHEN 3 THEN SCHEMA_NAME(perm.major_id)

        ELSE CAST(perm.major_id AS VARCHAR)

    END                         AS object_name

FROM sys.database_permissions perm

JOIN sys.database_principals dp ON dp.principal_id = perm.grantee_principal_id

WHERE dp.name = 'SIICSSaSqlDbTgtNp@cognizant.com'
 
UNION ALL
 
-- Permissions inherited via role membership

SELECT

    perm.permission_name,

    perm.state_desc,

    perm.class_desc,

    CASE perm.class

        WHEN 0 THEN 'Database (via role: ' + rp.name + ')'

        WHEN 1 THEN OBJECT_NAME(perm.major_id) + ' (via role: ' + rp.name + ')'

        WHEN 3 THEN SCHEMA_NAME(perm.major_id) + ' (via role: ' + rp.name + ')'

        ELSE CAST(perm.major_id AS VARCHAR)

    END                         AS object_name

FROM sys.database_permissions perm

JOIN sys.database_principals rp  ON rp.principal_id = perm.grantee_principal_id

JOIN sys.database_role_members drm ON drm.role_principal_id = rp.principal_id

JOIN sys.database_principals dp  ON dp.principal_id = drm.member_principal_id

WHERE dp.name = 'SIICSSaSqlDbTgtNp@cognizant.com';
 



-------------------------------------------------


-- ============================================================
-- Orphan User Detection — Azure SQL DB
-- Run in each database you want to check
-- ============================================================

-- -------------------------------------------------------
-- 1. SQL Auth orphans — user exists but no server login
--    (less common in Azure SQL but still possible)
-- -------------------------------------------------------
SELECT
    dp.name                         AS orphan_user,
    dp.type_desc                    AS user_type,
    dp.authentication_type_desc     AS auth_type,
    dp.create_date,
    dp.default_schema_name,
    'No matching server login'      AS reason
FROM sys.database_principals dp
WHERE dp.type = 'S'                             -- SQL authenticated user
  AND dp.authentication_type = 1               -- SQL auth
  AND dp.sid NOT IN (
        SELECT sid
        FROM sys.server_principals
        WHERE type = 'S'
  )
  AND dp.name NOT IN ('dbo','guest','INFORMATION_SCHEMA','sys')
  AND dp.name NOT LIKE '##%'

UNION ALL

-- -------------------------------------------------------
-- 2. Azure AD users — no longer active in tenant
--    These show as external but AAD account may be deleted,
--    disabled, or UPN renamed
-- -------------------------------------------------------
SELECT
    dp.name                                         AS orphan_user,
    dp.type_desc                                    AS user_type,
    dp.authentication_type_desc                     AS auth_type,
    dp.create_date,
    dp.default_schema_name,
    'Azure AD user — verify still active in tenant' AS reason
FROM sys.database_principals dp
WHERE dp.type = 'E'                             -- External (AAD) user
  AND dp.authentication_type = 2               -- External auth
  AND dp.name NOT LIKE '##%'
  AND dp.name NOT IN ('dbo','guest')

UNION ALL

-- -------------------------------------------------------
-- 3. Azure AD group members — group may have been deleted
-- -------------------------------------------------------
SELECT
    dp.name                                             AS orphan_user,
    dp.type_desc                                        AS user_type,
    dp.authentication_type_desc                         AS auth_type,
    dp.create_date,
    dp.default_schema_name,
    'Azure AD group — verify group still exists in tenant' AS reason
FROM sys.database_principals dp
WHERE dp.type = 'X'                             -- External (AAD) group
  AND dp.authentication_type = 2
  AND dp.name NOT LIKE '##%'

UNION ALL

-- -------------------------------------------------------
-- 4. Users with no role membership and no permissions
--    Ghost users — exist but can't do anything useful
-- -------------------------------------------------------
SELECT
    dp.name                                         AS orphan_user,
    dp.type_desc                                    AS user_type,
    dp.authentication_type_desc                     AS auth_type,
    dp.create_date,
    dp.default_schema_name,
    'No roles and no object permissions assigned'   AS reason
FROM sys.database_principals dp
WHERE dp.type IN ('S','E','X')
  AND dp.name NOT IN ('dbo','guest','INFORMATION_SCHEMA','sys','public')
  AND dp.name NOT LIKE '##%'
  AND dp.principal_id NOT IN (
        SELECT member_principal_id
        FROM sys.database_role_members
  )
  AND dp.principal_id NOT IN (
        SELECT grantee_principal_id
        FROM sys.database_permissions
        WHERE permission_name <> 'CONNECT'
  )

ORDER BY reason, orphan_user;

-- -------------------------------------------------------
-- 5. Full user inventory — all users with their
--    roles and auth type in one view
-- -------------------------------------------------------
SELECT
    dp.name                         AS database_user,
    dp.type_desc                    AS user_type,
    dp.authentication_type_desc     AS auth_type,
    dp.create_date,
    dp.default_schema_name,
    STRING_AGG(rp.name, ', ')
        WITHIN GROUP (ORDER BY rp.name) AS roles_assigned
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm
    ON drm.member_principal_id = dp.principal_id
LEFT JOIN sys.database_principals rp
    ON rp.principal_id = drm.role_principal_id
WHERE dp.type IN ('S','E','X')
  AND dp.name NOT IN ('dbo','guest','INFORMATION_SCHEMA','sys','public')
  AND dp.name NOT LIKE '##%'
GROUP BY
    dp.name,
    dp.type_desc,
    dp.authentication_type_desc,
    dp.create_date,
    dp.default_schema_name
ORDER BY dp.type_desc, dp.name;





------------------Contained User------------

Great question. Let me explain both clearly.

---

### Why the user is NOT in master db — and that's fine for Azure SQL

In **on-premises SQL Server**, the traditional flow is:

```
Server Login (master db)  →  mapped to  →  Database User
```

But **Azure SQL Database changed this model**. Microsoft introduced **contained database users** specifically for Azure SQL, and it's now the **recommended approach**.

---

### What is a Contained Database User?

A contained database user is a user that **lives entirely inside a single database** with no dependency on a server-level login in `master`.

```
Traditional SQL Server:           Azure SQL (Contained):
─────────────────────             ──────────────────────
master db                         master db
  └── Login (server level)          (no login needed here)
        │
        └── mapped to               Target Database
              Database User           └── User (self-contained)
                                            └── auth handled directly
```

The user, their authentication, and their permissions are all **packaged inside the database itself** — hence "contained".

---

### Why Azure SQL requires it for Azure AD users

| Aspect | Traditional Login | Contained DB User |
|---|---|---|
| Lives in | `master` database | Target database only |
| Auth handled by | SQL Server engine | The database itself |
| Azure AD support | Limited | ✅ Full support |
| Works when DB moves servers | ❌ Login breaks | ✅ Travels with the DB |
| Required for Azure AD (`FROM EXTERNAL PROVIDER`) | ❌ No | ✅ Yes |

Azure AD authentication (`FROM EXTERNAL PROVIDER`) **only works with contained users** — Microsoft never implemented Azure AD at the server login level for Azure SQL. So even if you're an Azure AD admin, unless you're created as a contained user inside that specific database, the connection is rejected.

---

### Why your user is not in master db — explained

Your user `SIICSSaSqlDbTgtNp@cognizant.com` being **absent from master** is completely expected and correct for Azure SQL. The connection string targets `azsql1CAssistant_4139` directly — so SQL Server skips `master` entirely and looks for a contained user straight in that database.

The error you're hitting is because the user likely **doesn't exist in `azsql1CAssistant_4139` as a contained user** either. Fix:

```sql
-- Connect to azsql1CAssistant_4139 as Azure AD admin and run:
CREATE USER [SIICSSaSqlDbTgtNp@cognizant.com] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [SIICSSaSqlDbTgtNp@cognizant.com];
ALTER ROLE db_datawriter ADD MEMBER [SIICSSaSqlDbTgtNp@cognizant.com];
```

`FROM EXTERNAL PROVIDER` is the keyword that tells Azure SQL this is an **Azure AD identity**, not a SQL password user. Without it, the user won't authenticate via Azure AD.

---

### In short

> A contained database user is Azure SQL's way of saying: *"This user belongs to this database, authenticates via Azure AD, and doesn't need anything in master."* It's not a workaround — it's the intended design for Azure SQL + Azure AD.
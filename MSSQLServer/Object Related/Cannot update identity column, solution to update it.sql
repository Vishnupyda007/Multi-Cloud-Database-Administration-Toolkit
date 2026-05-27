Msg 8102, Level 16, State 1, Line 4
Cannot update identity column 'MailTemplateID'.





You're trying to INSERT or UPDATE a value into `MailTemplateID` which is an `IDENTITY` column. SQL Server blocks this by default.

---

## Fix — Use `SET IDENTITY_INSERT`

### If you're doing an INSERT:
```sql
SET IDENTITY_INSERT [mas].[Tbl_MailTemplate] ON;

INSERT INTO [mas].[Tbl_MailTemplate] 
    ([MailTemplateID], [TemplateName], [AttachmentApplicable], [IsTwoWay], [IsActive], ...)
VALUES 
    (5, 'TemplateName', 1, 0, 1, ...);  -- your specific ID value

SET IDENTITY_INSERT [mas].[Tbl_MailTemplate] OFF;
```

### If you're doing an UPDATE on the identity column:
```sql
-- You CANNOT update an identity column directly even with IDENTITY_INSERT ON.
-- Instead: insert a new row with the desired ID, copy data, delete the old row.

SET IDENTITY_INSERT [mas].[Tbl_MailTemplate] ON;

INSERT INTO [mas].[Tbl_MailTemplate]
    ([MailTemplateID], [TemplateName], [AttachmentApplicable], [IsTwoWay], 
     [IsActive], [Remarks], [CreatedBy], [CreatedDate], [ModifiedBy], 
     [ModifiedDate], [Order_Id], [StatusMapped], [IsCFmailer], [IsDirectLink])
SELECT 
    <new_id>,   -- the new ID you want
    [TemplateName], [AttachmentApplicable], [IsTwoWay], 
    [IsActive], [Remarks], [CreatedBy], [CreatedDate], [ModifiedBy], 
    [ModifiedDate], [Order_Id], [StatusMapped], [IsCFmailer], [IsDirectLink]
FROM [mas].[Tbl_MailTemplate]
WHERE [MailTemplateID] = <old_id>;  -- the row you want to "rename"

SET IDENTITY_INSERT [mas].[Tbl_MailTemplate] OFF;

-- Then delete the old row (handle FK dependencies first)
DELETE FROM [mas].[Tbl_MailTemplate] WHERE [MailTemplateID] = <old_id>;
```

---

## Important Rules

| Rule | Detail |
|---|---|
| `IDENTITY_INSERT ON` allows only **INSERT**, not UPDATE | You can never UPDATE an identity column |
| Only **one table per session** can have `IDENTITY_INSERT ON` at a time | Always turn it OFF after use |
| After bulk inserts, reseed if needed | `DBCC CHECKIDENT('[mas].[Tbl_MailTemplate]', RESEED)` |
| FK on `StatusMapped` | If deleting old row, ensure no child FK violations first |

---

**Most likely you just need to remove `MailTemplateID` from your INSERT column list** and let SQL Server auto-generate it — share your INSERT/UPDATE statement if you want me to fix it directly.






This is a classic **identity gap** issue — SQL Server skipped 42 and jumped to 43. This commonly happens due to:

- A **rolled back transaction** (INSERT attempted then rolled back — ID is consumed and lost)
- A **server restart** (SQL Server 2012+ pre-caches identity values in blocks of 1000, lost on restart)
- A **failed INSERT**
- `DELETE` of row 42 previously

---

## Fix — Just reseed the identity back to 41, then your next insert will get 42

```sql
-- Step 1: Check current state
SELECT MAX(MailTemplateID) FROM [mas].[Tbl_MailTemplate];
-- If 43 is a real row with data, handle it first (see below)

-- Step 2: Reseed to 41 so next INSERT gets 42
DBCC CHECKIDENT ('[mas].[Tbl_MailTemplate]', RESEED, 41);

-- Step 3: Verify
DBCC CHECKIDENT ('[mas].[Tbl_MailTemplate]', NORESEED);
-- Should show: current identity value = 41, current column value = 43 (or whatever max is)
```

---

## But what about the existing row 43?

**Scenario A — Row 43 is junk / inserted by mistake**
```sql
-- Just delete it, then reseed
DELETE FROM [mas].[Tbl_MailTemplate] WHERE MailTemplateID = 43;
DBCC CHECKIDENT ('[mas].[Tbl_MailTemplate]', RESEED, 41);
-- Next INSERT will get 42 ✅
```

**Scenario B — Row 43 has valid data but should be 42**
```sql
-- Use the INSERT+DELETE approach from before
SET IDENTITY_INSERT [mas].[Tbl_MailTemplate] ON;

INSERT INTO [mas].[Tbl_MailTemplate]
    ([MailTemplateID], [TemplateName], [AttachmentApplicable], [IsTwoWay],
     [IsActive], [Remarks], [CreatedBy], [CreatedDate], [ModifiedBy],
     [ModifiedDate], [Order_Id], [StatusMapped], [IsCFmailer], [IsDirectLink])
SELECT 42, [TemplateName], [AttachmentApplicable], [IsTwoWay],
     [IsActive], [Remarks], [CreatedBy], [CreatedDate], [ModifiedBy],
     [ModifiedDate], [Order_Id], [StatusMapped], [IsCFmailer], [IsDirectLink]
FROM [mas].[Tbl_MailTemplate] WHERE [MailTemplateID] = 43;

SET IDENTITY_INSERT [mas].[Tbl_MailTemplate] OFF;

DELETE FROM [mas].[Tbl_MailTemplate] WHERE MailTemplateID = 43;

-- Reseed so next auto-insert continues from 42
DBCC CHECKIDENT ('[mas].[Tbl_MailTemplate]', RESEED, 42);
-- Next INSERT will get 43 ✅
```

---

## Prevent identity gaps in future (SQL Server 2012+)

The cache-on-restart gap is a known issue. Fix it with a trace flag or table option:

```sql
-- Option 1: Disable identity cache for this table (SQL Server 2017+)
ALTER DATABASE SCOPED CONFIGURATION SET IDENTITY_CACHE = OFF;

-- Option 2: Use SEQUENCE instead of IDENTITY for new tables 
-- (sequences don't cache by default)
```
The errors you’re getting are likely due to **PostgreSQL syntax rules and constraints**. Let’s break down each statement:

---

### ✅ **1. Rename Column**
Your syntax is correct, but ensure:
- The table exists.
- The column exists.
- You have privileges.

Correct syntax:
```sql
ALTER TABLE EDS_STG_PROV."EDS_ETL_Test_MCContractCustomerProject"
RENAME COLUMN contractdetailid_2 TO ContractDetailId;
```

**Tip:** If the table or schema name has uppercase letters, you must use **double quotes**.

---

### ✅ **2. Add Primary Key**
You cannot just `ADD PRIMARY KEY column_name` without specifying a constraint name and ensuring:
- The column is **NOT NULL**.
- No duplicate values exist.

Correct syntax:
```sql
ALTER TABLE EDS_STG_PROV."EDS_ETL_Test_MCContractCustomerProject"
ADD CONSTRAINT pk_customerproject PRIMARY KEY (CustomerProjectId);
```

If duplicates exist, you’ll get an error. Check first:
```sql
SELECT CustomerProjectId, COUNT(*) 
FROM EDS_STG_PROV."EDS_ETL_Test_MCContractCustomerProject"
GROUP BY CustomerProjectId
HAVING COUNT(*) > 1;
```

---

### ✅ **3. Add Primary Key on Another Table**
Same rule applies:
```sql
ALTER TABLE EDS_STG_PROV."EDS_ETL_Test_MCUploadedFile"
ADD CONSTRAINT pk_fileupload PRIMARY KEY (FileUploadId);
```

---

### ✅ **Common Reasons for Errors**
- Column has **NULLs** → Fix with `UPDATE` and `ALTER COLUMN SET NOT NULL`.
- Column has **duplicates** → Remove duplicates or choose a different key.
- Table already has a primary key → Drop it first:
```sql
ALTER TABLE EDS_STG_PROV."EDS_ETL_Test_MCContractCustomerProject"
DROP CONSTRAINT IF EXISTS pk_customerproject;
```

---

🔥 Do you want me to give you **a complete script that checks for duplicates, fixes NULLs, and then safely adds primary keys for both tables**? Or should I **give you a version that also renames columns and handles uppercase names automatically**?
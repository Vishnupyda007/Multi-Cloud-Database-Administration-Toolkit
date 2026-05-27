Alter table [EDS_CURR_STG].[Prism_ActualsCRS_STG_History]

Alter column BilledHours DECIMAL(10,7);

Msg 8115, Level 16, State 6, Line 1

Arithmetic overflow error converting real to data type numeric.

how to check the culprit data


---------


Excellent question. This is a classic and very understandable error when changing data types. The error message is telling you exactly what's wrong, but you need to know how to interpret it.

Let's break down why it's happening and how to find the exact data causing the problem.

### The Root Cause of the Error

The error `Arithmetic overflow error converting real to data type numeric` happens because at least one value in your `BilledHours` column is too large to fit into the new data type you've defined: **`DECIMAL(10, 7)`**.

Here’s the key to understanding why:

*   `DECIMAL(p, s)`
    *   `p` = **Precision**: The *total* number of digits that can be stored, both to the left and right of the decimal point. In your case, this is **10**.
    *   `s` = **Scale**: The number of digits stored to the *right* of the decimal point. In your case, this is **7**.

This means the number of digits available for the *left* of the decimal point is `p - s`.

In your case, this is `10 - 7 = 3`.

So, `DECIMAL(10, 7)` can only store numbers with a **maximum of 3 digits before the decimal point**. It can hold values like `999.1234567` or `-999.1234567`, but it **cannot** hold `1000.0` or larger.

Your `BilledHours` column, which is currently a `real` (floating-point) type, contains at least one value that is **1000 or greater**, causing the overflow.

---

### How to Find the Culprit Data

Here are a few queries you can run to pinpoint the exact rows that are causing the `ALTER TABLE` statement to fail.

#### Method 1: Direct Check for Values Too Large

This is the most straightforward method. Since we know the problem is with numbers that have more than 3 digits to the left of the decimal, we can query for any values greater than or equal to 1000.

```sql
SELECT
    BilledHours
FROM
    [EDS_CURR_STG].[Prism_ActualsCRS_STG_History]
WHERE
    BilledHours >= 1000;
```
This will immediately show you all the values that are too large to fit.

#### Method 2: Using `TRY_CONVERT` (Recommended)

This is a more robust method. The `TRY_CONVERT` function attempts to convert a value to a specified data type. If it succeeds, it returns the converted value. If it fails, it returns `NULL` instead of throwing an error. This is perfect for finding data that won't convert properly.

```sql
SELECT
    BilledHours
FROM
    [EDS_CURR_STG].[Prism_ActualsCRS_STG_History]
WHERE
    TRY_CONVERT(DECIMAL(10, 7), BilledHours) IS NULL
    AND BilledHours IS NOT NULL; -- This ensures we ignore existing NULLs
```

This query will show you every `BilledHours` value that cannot be successfully converted to `DECIMAL(10, 7)`. This is superior because it will also catch any non-numeric or corrupted data if any existed, though the error message points specifically to an overflow issue.

---

### How to Fix the Problem

Once you have identified the culprit data, you have two main paths to a solution. The correct path depends on your business requirements.

#### Option 1: The Data is Incorrect and Needs to be Cleaned

If values like `1000` or more are invalid for `BilledHours`, you need to update them to a correct value.

**Before running an update, always wrap it in a transaction so you can roll back if needed.**

```sql
BEGIN TRANSACTION;

-- Review the data you are about to change
SELECT BilledHours FROM [EDS_CURR_STG].[Prism_ActualsCRS_STG_History] WHERE BilledHours >= 1000;

-- Example: Update the incorrect values (replace with your own business logic)
UPDATE [EDS_CURR_STG].[Prism_ActualsCRS_STG_History]
SET
    BilledHours = 999.9999999 -- Or NULL, or a correct value
WHERE
    BilledHours >= 1000;

-- Verify the change
SELECT BilledHours FROM [EDS_CURR_STG].[Prism_ActualsCRS_STG_History] WHERE BilledHours >= 1000;
-- This should now return 0 rows.

-- If satisfied, commit the transaction. Otherwise, roll it back.
COMMIT TRANSACTION;
-- ROLLBACK TRANSACTION;
```

After cleaning the data, you can run your `ALTER COLUMN` statement again, and it should succeed.

#### Option 2: The Data is Correct and the Data Type is Wrong

If it's perfectly valid for `BilledHours` to be `1000` or greater, then your chosen data type `DECIMAL(10, 7)` is simply too small. You need to increase the precision.

For example, to allow for up to 5 digits before the decimal point, you would need a total precision of `5 (left) + 7 (right) = 12`.

You could change your `ALTER` statement to use `DECIMAL(12, 7)`:

```sql
-- This allows for numbers up to 99,999.9999999
ALTER TABLE [EDS_CURR_STG].[Prism_ActualsCRS_STG_History]
ALTER COLUMN BilledHours DECIMAL(12, 7);
```

Or, if you need even more room, you can increase the precision further. For example, `DECIMAL(15, 7)` would allow for 8 digits before the decimal.

**This is the most likely solution if your `BilledHours` represents a large accumulation of time.** Choose a precision that safely accommodates your largest possible value.
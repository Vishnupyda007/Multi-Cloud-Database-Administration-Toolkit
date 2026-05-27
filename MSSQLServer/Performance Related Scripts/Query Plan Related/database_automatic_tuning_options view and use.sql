SELECT * 
FROM sys.database_automatic_tuning_options 



The query:

```sql
SELECT * 
FROM sys.database_automatic_tuning_options;
```

returns the **automatic tuning options** for the current database in SQL Server. The columns `desired_state`, `actual_state`, and `reason` are represented by **numeric codes**, and here's what those values mean:

---

### ?? `desired_state` and `actual_state` Values

| Value | Meaning       |
|-------|---------------|
| 0     | OFF           |
| 1     | ON            |
| 2     | DEFAULT       |

- **`0 (OFF)`**: The feature is disabled.
- **`1 (ON)`**: The feature is enabled.
- **`2 (DEFAULT)`**: The database inherits the setting from the server-level configuration.

---

### ?? `reason` Values

| Value | Meaning                                                                 |
|-------|-------------------------------------------------------------------------|
| 0     | Option explicitly configured at the database level                      |
| 1     | Inherited from server-level configuration                               |
| 2     | Overridden due to server-level policy or constraints                    |

So, if you see:

- `desired_state = 1`: You want the feature to be **ON**.
- `desired_state = 2`: You want the feature to follow the **server default**.
- `reason = 2`: The setting is being **overridden** by a server-level policy, even if the database requested something else.

---

### ? Example Interpretation

If a row shows:

- `desired_state = 2`
- `actual_state = 0`
- `reason = 2`

It means:
- The database is set to use the **default** setting.
- But the feature is currently **OFF**.
- And this is because the **server-level policy** has overridden the default.

Would you like help modifying these settings or checking the server-level configuration too?
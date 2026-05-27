To check if **CLR integration** is enabled in SQL Server (including when working with SSIS packages that might use CLR), you can query the `sys.configurations` view:

```sql
SELECT name, value, value_in_use, description
FROM sys.configurations
WHERE name = 'clr enabled';
```

### ✅ Explanation:
- `value` = configured setting (0 = disabled, 1 = enabled)
- `value_in_use` = currently active setting
- If `value_in_use = 1`, CLR integration is enabled.

---

### For SSIS Context:
- SSIS itself does **not require CLR** for most operations, but if your SSIS package calls **SQL CLR assemblies** (custom .NET code deployed in SQL Server), then `clr enabled` must be set to `1`.
- To enable CLR (if you have permissions):
```sql
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;
```

---

✅ Do you want me to also give you:
- **A query to check if any CLR assemblies are currently loaded in the database**?
- Or **a script to list all SSIS-related CLR assemblies deployed in SQL Server**?
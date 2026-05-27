To enable **Database Mail** in **SQL Server Managed Instance (MI)**, follow these steps:

---

### ✅ **1. Configure Network Access**
Ensure your Managed Instance can reach your mail server:
- Open **outbound port 25** (or **587** for secure SMTP) in your **Network Security Group (NSG)**.
- This allows the Managed Instance to send emails externally.

---

### ✅ **2. Enable Database Mail XPs**
Run the following T-SQL to enable the extended stored procedures for Database Mail:

```sql
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Database Mail XPs', 1;
RECONFIGURE;
```

---

### ✅ **3. Create a Database Mail Account**
Replace placeholders with your actual mail server and credentials:

```sql
EXEC msdb.dbo.sysmail_add_account_sp
    @account_name = 'MyMailAccount',
    @description = 'Mail account for sending alerts',
    @email_address = 'your-email@example.com',
    @display_name = 'SQL MI Mailer',
    @mailserver_name = 'smtp.yourserver.com',
    @username = 'your-email@example.com',
    @password = 'yourPassword';
```

---

### ✅ **4. Create a Mail Profile**
```sql
EXEC msdb.dbo.sysmail_add_profile_sp
    @profile_name = 'AzureManagedInstance_dbmail_profile',
    @description = 'Profile for SQL MI alerts';
```

> ⚠️ The profile name **must be** `AzureManagedInstance_dbmail_profile` if you want to use it with SQL Agent jobs [1](https://techcommunity.microsoft.com/blog/azuresqlblog/sending-emails-in-azure-sql-managed-instance/386235).

---

### ✅ **5. Link Account to Profile**
```sql
EXEC msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'AzureManagedInstance_dbmail_profile',
    @account_name = 'MyMailAccount',
    @sequence_number = 1;
```

---

### ✅ **6. Test Email Sending**
```sql
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'AzureManagedInstance_dbmail_profile',
    @recipients = 'recipient@example.com',
    @subject = 'Test Email from SQL MI',
    @body = 'This is a test email sent from SQL Server Managed Instance.';
```

---

Let me know if you'd like help setting this up with **SendGrid**, **Office 365**, or another SMTP provider! 😊

[1](https://techcommunity.microsoft.com/blog/azuresqlblog/sending-emails-in-azure-sql-managed-instance/386235): [Microsoft Tech Community – Sending emails in Azure SQL Managed Instance](https://techcommunity.microsoft.com/blog/azuresqlblog/sending-emails-in-azure-sql-managed-instance/386235)
How do I set up database mail for Azure SQL DB Managed Instance
johnmccormack.it
DB mail configuration on Azure managed instance
stackoverflow.com
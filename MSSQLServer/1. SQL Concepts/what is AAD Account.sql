**Prompt [what AAD Account | Try in Copilot Chat](https://m365.cloud.microsoft/chat/entity1-d870f6cd-4aa5-4d42-9626-ab690c041429/eyJpZCI6IlZYTmxjbFl4ZkdoMGRIQnpPaTh2YzNWaWMzUnlZWFJsTFdsdWRDNXZabVpwWTJVdVkyOXRMM3hQU1VRNlkyUTNOVEZqTkRrdFpEWTVNeTAwWVRneExUZ3paamN0TmpNMVpHUTJZamxoWXpjMGZHWmxPR0k0Tmpsa0xXUmtOakl0TkdaalpDMWhOV0kwTFRoak5HVmhORFUzTUdNNE1ud3lNREkxTFRBNExUQTNWREV6T2pBNU9qRTJMall3T0RZM05EUmEiLCJzY2VuYXJpbyI6InNoYXJlTGlua1ZpYVJpY2hDb3B5IiwicHJvcGVydGllcyI6eyJwcm9tcHRTb3VyY2UiOiJ1c2VyIiwiY2xpY2tUaW1lc3RhbXAiOiIyMDI1LTA4LTA3VDEzOjA5OjE2LjY1N1oifSwiY2hhdFR5cGUiOiJ3ZWIiLCJ2ZXJzaW9uIjoxLjF9)**
what AAD Account
**Response**
An **AAD account** (now called **Microsoft Entra ID account**) used in **Azure SQL Managed Instance (SQL MI)** refers to a user or group identity managed through Microsoft Entra ID (formerly Azure Active Directory). These accounts can be used for **authentication and authorization** in SQL MI, including for **replication scenarios**, but with specific setup requirements.

---

### 🔐 What Is an AAD Account in SQL MI?

An **AAD account** is:
- A **userPrincipalName** (e.g., `user@domain.com`) or
- A **group name** (e.g., `DB-Readers`) from Microsoft Entra ID

These accounts are used to create **contained users** at the database level in SQL MI:
```sql
CREATE USER [user@domain.com] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [user@domain.com];
```
This allows the user to authenticate using Entra ID credentials[1](https://hardstahl.se/posts/sql-managed-instance-ad-integration/).

---

### ✅ Supported Authentication Modes for AAD Accounts

1. **Active Directory - Password**
   - Uses Entra ID username and password.
   - Connection string includes `Authentication=Active Directory Password`.

2. **Active Directory - Integrated**
   - Uses seamless SSO via Azure AD Connect.
   - Requires domain-joined machine and Kerberos setup.

3. **Active Directory - Universal with MFA**
   - For users with Multi-Factor Authentication enabled.
   - Requires SSMS v18.6+ or Azure Data Studio.

---

### 🧩 Using AAD Accounts in Replication

While **SQL Authentication** is the default for replication agents, **AAD accounts** can be used if:

- You configure the SQL MI with an **Active Directory admin**.
- You create **contained users** from Entra ID.
- You use **SSMS v19.1+** to configure replication.
- You ensure **encrypted connections** (TLS 1.2 or 1.3) are used[2](https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/replication-transactional-overview?view=azuresql).

However, replication agents like `sp_addpushsubscription_agent` still require **explicit credentials**, and **AAD tokens** are not natively supported in all replication agent configurations. So, **SQL Authentication is still recommended** for replication setup unless you're using **SQL Server 2022 with Azure Arc**[3](https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/replication-between-two-instances-configure-tutorial?view=azuresql).

---

### ⚠️ Important Notes

- You must **assign an Active Directory admin** in SQL MI before creating AAD users.
- If the AAD admin is removed, contained users will **lose access**.
- AAD accounts are **not service accounts** like Windows domain accounts.
- You cannot use AAD accounts in replication agents unless the agent supports token-based authentication.

---

Would you like help creating a contained AAD user in your SQL MI or configuring replication with SQL Authentication and AAD integration?
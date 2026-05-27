**Prompt [Would you like help creating a contained AAD user... | Try in Copilot Chat](https://m365.cloud.microsoft/chat/entity1-d870f6cd-4aa5-4d42-9626-ab690c041429/eyJpZCI6IlZYTmxjbFl4ZkdoMGRIQnpPaTh2YzNWaWMzUnlZWFJsTFdsdWRDNXZabVpwWTJVdVkyOXRMM3hQU1VRNlkyUTNOVEZqTkRrdFpEWTVNeTAwWVRneExUZ3paamN0TmpNMVpHUTJZamxoWXpjMGZHVXdNVEJtWVdJMExUSmxaVEF0TkdZNU1DMWlZemd3TFdWallUZzJPR0l4TVRZMk0zd3lNREkxTFRBNExUQTNWREV6T2pBNU9qVTVMalExTlRVd09UWmEiLCJzY2VuYXJpbyI6InNoYXJlTGlua1ZpYVJpY2hDb3B5IiwicHJvcGVydGllcyI6eyJwcm9tcHRTb3VyY2UiOiJ1c2VyIiwiY2xpY2tUaW1lc3RhbXAiOiIyMDI1LTA4LTA3VDEzOjA5OjU5LjUwNVoifSwiY2hhdFR5cGUiOiJ3ZWIiLCJ2ZXJzaW9uIjoxLjF9)**
Would you like help creating a contained AAD user in your SQL MI
**Response**
Great! Here's a **step-by-step guide** to help you create a **contained Microsoft Entra (AAD) user** in your **Azure SQL Managed Instance (SQL MI)**:

---

### ✅ **Pre-requisites**
1. **Azure SQL MI must have an Active Directory admin configured**:
   - Go to the **Azure portal** → your SQL MI → **Active Directory admin** → set an Entra ID user or group as admin.

2. **You must be logged in using an Entra ID account** with sufficient privileges (like the AD admin).

---

### 🛠️ **Steps to Create a Contained AAD User**

#### 1. **Connect to SQL MI using SSMS**
- Use **SSMS v18.6+** or **Azure Data Studio**.
- Choose **Authentication: Active Directory - Universal with MFA**.
- Login with your Entra ID credentials.

#### 2. **Create the Contained User**
Run this T-SQL in the **target database** (not master):

```sql
-- Replace with your Entra ID user
CREATE USER [user@yourdomain.com] FROM EXTERNAL PROVIDER;
```

#### 3. **Assign Roles or Permissions**
You can assign built-in roles like `db_datareader`, `db_owner`, etc.:

```sql
ALTER ROLE db_datareader ADD MEMBER [user@yourdomain.com];
-- or for full access
ALTER ROLE db_owner ADD MEMBER [user@yourdomain.com];
```

---

### 🧪 **Verify Access**
Ask the user to connect using:
- **Authentication**: Active Directory - Universal with MFA
- **Database**: The one where the user was created

They should be able to log in and access based on the roles assigned.

---

Would you like help automating this with a script or deploying it across multiple databases in your SQL MI?
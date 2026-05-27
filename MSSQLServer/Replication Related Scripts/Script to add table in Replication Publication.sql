--Step-1:

EXEC sp_addarticle
@publication = N'Practice_Replication',
@article =N'CentralRepository_Associate_Skills_History',
@source_object =N'CentralRepository_Associate_Skills_History',
@force_invalidate_snapshot=1


------OR --Best One--------------

--Step-1:

USE [YourPublicationDatabase]
GO

EXEC sp_addarticle 
    @publication = N'YourPublicationName',
    @article = N'YourTableName',
    @source_owner = N'dbo',
    @source_object = N'YourTableName',
    @type = N'logbased',
    @description = null,
    @creation_script = null,
    @pre_creation_cmd = N'drop',
    @schema_option = 0x000000000803509F,
    @identityrangemanagementoption = N'manual',
    @destination_table = N'YourTableName',
    @destination_owner = N'dbo',
    @force_invalidate_snapshot=1; --Optional

--Step-2:

EXEC sp_refreshsubscriptions @publication = N'Practice_Replication'

--Step-3:

-- Run the snapshot Agent.



---------------------------

To add an article (i.e., a table, stored procedure, or other database object) to an existing **Transactional Replication Publication** in SQL Server, you can use the **`sp_addarticle`** system stored procedure. Here's a general example of how to do it:

### ? SQL Server Query to Add an Article to a Transactional Publication

```sql
USE [YourPublicationDatabase]
GO

EXEC sp_addarticle 
    @publication = N'YourPublicationName',
    @article = N'YourTableName',
    @source_owner = N'dbo',
    @source_object = N'YourTableName',
    @type = N'logbased',
    @description = null,
    @creation_script = null,
    @pre_creation_cmd = N'drop',
    @schema_option = 0x000000000803509F,  --------not mandatory
    @identityrangemanagementoption = N'manual',
    @destination_table = N'YourTableName',
    @destination_owner = N'dbo',
    @force_invalidate_snapshot = 1;
```

### ?? Key Parameters Explained:
- `@publication`: Name of your existing publication.
- `@article`: Name of the article (usually the same as the table name).
- `@source_object`: The actual table or object name in the database.
- `@type`: For transactional replication, use `'logbased'`.
- `@pre_creation_cmd`: What to do if the object exists on the subscriber (`drop`, `delete`, `truncate`, `none`).
- `@schema_option`: Controls how the schema is scripted. The value above is a common default.
- `@identityrangemanagementoption`: Use `'manual'` unless you're using identity range management.

### ??? After Adding the Article
1. **Reinitialize the subscription** (if needed) or Keep Anonymous and Immediate sync off.
2. **Start the Snapshot Agent** to generate a new snapshot that includes the new article.

The parameter @force_invalidate_snapshot = 1 in the sp_addarticle stored procedure is used to invalidate the existing snapshot for the publication when a new article is added.


You're telling SQL Server:

“Yes, I understand that adding this article will make the current snapshot outdated or incomplete, and I want to force the system to mark the current snapshot as invalid so that a new snapshot will be generated.”

?? Why It's Important:
Transactional replication uses a snapshot to initialize subscribers. If you add a new article (like a table), the snapshot must include it. If you don’t invalidate the old snapshot, the new article might not be included in the replication process.

? When to Use It:
When you're adding new articles to an existing publication.
When you want to ensure subscribers get the updated schema/data.
When you're okay with reinitializing subscriptions if needed.
?? Important Note:
After using this, you should:

Run the Snapshot Agent to generate a new snapshot.
Reinitialize subscriptions if required.


References:
https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-addarticle-transact-sql?view=sql-server-ver16
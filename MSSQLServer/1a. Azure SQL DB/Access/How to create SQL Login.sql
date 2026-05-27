-- Step 1: Connect to the 'master' database
USE master;
GO
 
-- Step 2: Create the server-level login
CREATE LOGIN [MyServerLogin] WITH PASSWORD = N'a_Very_Strong_P@ssword123!';
GO
 
-- Step 3: Set its default database
ALTER LOGIN [MyServerLogin] WITH DEFAULT_DATABASE = [YourDatabaseName];
GO

-- Step 4: Connect to your specific database
USE [YourDatabaseName];
GO
 
-- Step 5: Create a user and map it to the server login
CREATE USER [MyServerLogin] FROM LOGIN [MyServerLogin];
GO
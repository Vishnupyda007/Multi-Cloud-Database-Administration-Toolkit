CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'DEliteDataEncNonProd!5'
GO
 
CREATE CERTIFICATE DELiteCertificate WITH SUBJECT = 'Protect DELiteData'
GO
 
CREATE SYMMETRIC KEY DELiteSymmetricKey WITH
    KEY_SOURCE = 'DAEncryption',
    ALGORITHM = AES_256, 
    IDENTITY_VALUE = 'DEliteDataEncNonProd!5' --Use a strong password.This has to match.
    ENCRYPTION BY CERTIFICATE DELiteCertificate;
GO
 
 
GRANT ALTER ANY SYMMETRIC KEY TO [delite_read]
GRANT CONTROL ON CERTIFICATE::DELiteCertificate TO [delite_read]
GO



--------------------------------------


-- Step 1: Create a Database Master Key (if not already created)
USE master;
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword@123';  -- Use a secure password
GO

-- Step 2: Create a Certificate to protect the DEK
CREATE CERTIFICATE TDECert
WITH SUBJECT = 'TDE Certificate';
GO

-- Step 3: Backup the Certificate and Private Key (IMPORTANT for recovery)
BACKUP CERTIFICATE TDECert
TO FILE = 'C:\TDECert_Backup\TDECert.cer'
WITH PRIVATE KEY (
    FILE = 'C:\TDECert_Backup\TDECert_PrivateKey.pvk',
    ENCRYPTION BY PASSWORD = 'AnotherStrongPassword@456'  -- Use a secure password
);
GO

-- Step 4: Enable TDE on the target database
USE TEST;  -- Replace with your actual database name
GO
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDECert;
GO

-- Step 5: Set encryption ON
ALTER DATABASE TEST
SET ENCRYPTION ON;
GO
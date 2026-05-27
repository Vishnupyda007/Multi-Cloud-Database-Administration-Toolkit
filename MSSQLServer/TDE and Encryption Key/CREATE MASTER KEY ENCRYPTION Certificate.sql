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
 
 
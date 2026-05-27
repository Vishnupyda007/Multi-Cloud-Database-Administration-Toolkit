USE Master
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD ='StrongPassword'

--Step2:
------use the below query if the Encryption key /Certificate is already available or moved to required server from other Server

CREATE CERTIFICATE DB_Encrypt_Cert

FROM FILE = 'E:\MSSQL\DB_Encrypt_Cert.cer'

WITH PRIVATE KEY(

FILE = 'E:\MSSQL\DB_Encrypt_Cert.prvk',

DECRYPTION BY PASSWORD = '********************************'

)
 

 
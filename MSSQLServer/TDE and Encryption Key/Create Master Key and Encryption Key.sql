----Step-1-------------
USE master
go

CREATE MASTER KEY ENCRYPTION BY PASSWORD ='Centr@lRepo$itory@123'


------if u have existing Encryption key in DB of other Server, take that Encryption key as Backup and move it to desired Server path

CREATE CERTIFICATE CRS_Prod_Cert
FROM FILE = 'E:\TDE_dontdelete\CRS_Prod_Cert.cer'
WITH PRIVATE KEY(
FILE = 'E:\TDE_dontdelete\CRS_Prod_Cert.prvk',
DECRYPTION BY PASSWORD = 'Centr@lRepo$itory@123'
)
 

 
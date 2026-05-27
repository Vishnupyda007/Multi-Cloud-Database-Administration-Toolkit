USE Master
go
BACKUP CERTIFICATE CRS_Prod_Cert
TO FILE = 'G:\DBA_Ops\CRS_Prod_Cert.cer'
WITH PRIVATE KEY(
FILE = 'G:\DBA_Ops\CRS_Prod_Cert.prvk',
ENCRYPTION BY PASSWORD = 'Centr@lRepo$itory@123'
)
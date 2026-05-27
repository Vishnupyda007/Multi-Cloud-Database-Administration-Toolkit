USE [master]
GO
DROP CREDENTIAL [
https://ctssqlmiprod.blob.core.windows.net/sqlmidbbkp]
GO
create CREDENTIAL [
https://ctssqlmiprod.blob.core.windows.net/sqlmidbbkp]
WITH IDENTITY='SHARED ACCESS SIGNATURE',
SECRET = 'sv=2022-11-02&ss=b&srt=sco&sp=rwlactf&se=2024-06-13T17:03:19Z&st=2024-05-13T09:03:19Z&spr=https&sig=RI2IzHiVU79CUgQ%2F8W3qISUa9djKbLKnoiB7IsZGiko%3D'
GO
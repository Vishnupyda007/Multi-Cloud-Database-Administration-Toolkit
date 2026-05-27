select name,is_trustworthy_on from sys.databases;
 
 
--- Script to enable trustworthy parameter all DBs--
 
 
DECLARE @command varchar(1000)
 
SELECT @command = 'IF ''?'' NOT IN(''master'', ''model'', ''msdb'', ''tempdb'')
 
BEGIN
 
USE ?
 
EXEC(''ALTER DATABASE ? set TRUSTWORTHY ON '')
 
END '
 
EXEC sp_MSforeachdb @command
 
select name,is_trustworthy_on from sys.databases;
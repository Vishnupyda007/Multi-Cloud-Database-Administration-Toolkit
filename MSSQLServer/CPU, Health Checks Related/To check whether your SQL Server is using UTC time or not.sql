--To check whether your SQL Server is using UTC time or not, you can run the following query:

SELECT SYSDATETIMEOFFSET() AS ServerDateTimeOffset;


--🔍 What This Does:
--SYSDATETIMEOFFSET() returns the current date and time along with the time zone offset from UTC.
--If the offset is +00:00, then your server is using UTC time.
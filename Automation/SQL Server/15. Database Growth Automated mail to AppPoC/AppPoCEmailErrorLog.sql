 CREATE TABLE dbo.AppPoCEmailErrorLog (
     ErrorLogID INT IDENTITY(1,1) PRIMARY KEY,
     AppPoC NVARCHAR(300),
     AppName NVARCHAR(300),
     ErrorMessage NVARCHAR(4000),
     ErrorDateTime DATETIME DEFAULT GETDATE()
 );
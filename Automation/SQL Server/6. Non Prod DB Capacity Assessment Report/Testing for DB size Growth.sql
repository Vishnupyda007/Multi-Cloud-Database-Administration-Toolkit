select ServerName,DBName,TotalDatabaseSizeGB,PercentageOfTotalGBUsed,Datetime from [MI_SIT_DB_Capacity_Report]
where PercentageOfTotalGBUsed <> '' or TotalDatabaseSizeGB <> '' and Datetime>=GETDATE()


select ServerName,DBName,TotalDatabaseSizeGB,PercentageOfTotalGBUsed,Datetime from [MI_SIT_DB_Capacity_Daily_STG]
where PercentageOfTotalGBUsed <> '' or TotalDatabaseSizeGB <> '' and Datetime>=GETDATE()



------half worked--------------

select a.ServerName,a.DBName,a.TotalDatabaseSizeGB,b.TotalDatabaseSizeGB as TotalDatabaseSizeGB_OneDayAgo,
((ROUND(CAST(a.TotalDatabaseSizeGB AS FLOAT), 3)) - (ROUND(CAST(b.TotalDatabaseSizeGB AS FLOAT), 3))) AS TotalDBSizeChange,
    ROUND(CAST(a.PercentageOfTotalGBUsed AS FLOAT), 3) AS PercentageOfTotalGBUsed,
    ROUND(CAST(b.PercentageOfTotalGBUsed AS FLOAT), 3) AS PercentageOfTotalGBUsed_OneDayAgo,
    ((ROUND(CAST(a.PercentageOfTotalGBUsed AS FLOAT), 3)) - (ROUND(CAST(b.PercentageOfTotalGBUsed AS FLOAT), 3)))AS PercentageOfTotalGBUsedChange,a.Datetime from [MI_SIT_DB_Capacity_Report] a  left outer join [MI_SIT_DB_Capacity_Daily_STG] b on a.DBName=b.DBName and a.ServerName=b.ServerName and a.Name=b.Name 
	 where a.PercentageOfTotalGBUsed <> '' or a.TotalDatabaseSizeGB <> '' and a.Datetime>=GETDATE() and 
	 CAST(b.Datetime AS DATE)=DATEADD(DAY, -1,GETDATE())




--------------------------Working-------------------------


SELECT 
    a.ServerName,
    a.DBName,
    (ROUND(CAST(a.TotalDatabaseSizeGB AS FLOAT), 4)) as TotalDatabaseSizeGB,
    (ROUND(CAST(b.TotalDatabaseSizeGB AS FLOAT),4)) AS TotalDatabaseSizeGB_OneWeekAgo,
    FORMAT(ROUND(CAST(a.TotalDatabaseSizeGB AS FLOAT), 4) - ROUND(CAST(b.TotalDatabaseSizeGB AS FLOAT), 4), 'N4') AS TotalDBSizeChange,
    ROUND(CAST(a.PercentageOfTotalGBUsed AS FLOAT), 4) AS PercentageOfTotalGBUsed,
    ROUND(CAST(b.PercentageOfTotalGBUsed AS FLOAT), 4) AS PercentageOfTotalGBUsed_OneWeekAgo,
    FORMAT(ROUND(CAST(a.PercentageOfTotalGBUsed AS FLOAT), 4) - ROUND(CAST(b.PercentageOfTotalGBUsed AS FLOAT), 4), 'N4') AS PercentageOfTotalGBUsedChange,
    a.Datetime
FROM 
    [MI_SIT_DB_Capacity_Report] a
LEFT JOIN 
    (SELECT 
         ServerName, DBName, Name, TotalDatabaseSizeGB, PercentageOfTotalGBUsed, Datetime
     FROM 
         [MI_SIT_DB_Capacity_Daily_STG]
     WHERE 
         CAST(Datetime AS DATE) = DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
    ) b
ON 
    a.DBName = b.DBName 
    AND a.ServerName = b.ServerName 
    AND a.Name = b.Name
WHERE 
    (a.PercentageOfTotalGBUsed <> '' OR a.TotalDatabaseSizeGB <> '')
    --AND a.Datetime >= CAST(GETDATE() AS DATE)
ORDER BY 
    a.ServerName, a.DBName;
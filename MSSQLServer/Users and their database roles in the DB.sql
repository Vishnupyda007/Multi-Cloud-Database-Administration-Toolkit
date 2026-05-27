SELECT r.name role_principal_name, 
       m.name AS member_principal_name
  FROM sys.database_role_members rm 
  JOIN sys.database_principals r 
       ON rm.role_principal_id = r.principal_id
  JOIN sys.database_principals m 
       ON rm.member_principal_id = m.principal_id
WHERE r.name='db_datareader' and m.type IN ('X','E')
-- m.type IN ('S', 'U', 'G', 'C', 'K') -- Types: SQL User, Windows User, Windows Group, Certificate, Asymmetric Key
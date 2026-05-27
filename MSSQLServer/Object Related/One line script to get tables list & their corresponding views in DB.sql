select * from INFORMATION_SCHEMA.VIEW_TABLE_USAGE where VIEW_NAME in ( 'vw_CentralRepository_Active_Associate_Details',
'vw_CentralRepository_Allocation', 
'vw_CentralRepository_Associate_Details',
'vw_CentralRepository_Contacts',
'vw_CentralRepository_Country',
'vw_CentralRepository_Current_ProjectManager',
'vw_CentralRepository_Department',
'vw_CentralRepository_DepartmentVerticalMapping')

--where TABLE_NAME ='tble_Name'
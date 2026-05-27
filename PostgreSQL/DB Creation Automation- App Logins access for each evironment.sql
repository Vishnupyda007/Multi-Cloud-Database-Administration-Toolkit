--access for App Login and App GSA--------

Note: Each App will have one prod GSA and one non Prod GSA

once a AppLogin or GSA is created,please tag admin login to their Account:

grant AppLogin to postgres with admin option;
grant AppGSA to postgres with admin option;


--
1. Every time new db is created in  Nonprod, need to execute below script as well:

grant all on database AppDB to "npgke-devops-serviceacc@cb0104074a-citnonprod-gc.iam";


All the below scripts should run inside the AppDB:
1. in Dev---
grant all on database AppDb to AppLogin;
grant all on database AppDb to AppGSA;
grant db_owner to Applogin;
grant db_owner to AppGSA;


2. in SIT---

grant temp,connect on Database AppDB to Applogin;
grant temp,connect on Database AppDB to AppGSA;
ALTER DEFAULT PRIVILEGES
FOR ROLE "npgke-devops-serviceacc@cb0104074a-citnonprod-gc.iam"
GRANT EXECUTE ON ROUTINES TO AppLogin;
ALTER DEFAULT PRIVILEGES
FOR ROLE "npgke-devops-serviceacc@cb0104074a-citnonprod-gc.iam"
GRANT EXECUTE ON ROUTINES TO AppGSA;
grant db_datareader,db_datawriter to AppLogin;
grant db_datareader,db_datawriter to AppGSA;


3. in UAT---


grant temp,connect on Database AppDB to Applogin;
grant temp,connect on Database AppDB to AppGSA;

ALTER DEFAULT PRIVILEGES
FOR ROLE "npgke-devops-serviceacc@cb0104074a-citnonprod-gc.iam"
GRANT EXECUTE ON ROUTINES TO AppGSA;
grant db_datareader to AppLogin;
grant db_datareader,db_datawriter to AppGSA;


4. in PT:

grant temp,connect on Database AppDB to Applogin;
grant temp,connect on Database AppDB to AppGSA;
ALTER DEFAULT PRIVILEGES
FOR ROLE "npgke-devops-serviceacc@cb0104074a-citnonprod-gc.iam"
GRANT EXECUTE ON ROUTINES TO AppGSA;
grant db_datareader,db_datawriter to AppLogin;
grant db_datareader,db_datawriter to AppGSA;


-------------------

5. in Prod: SQL Logins not allowed in Prod

1. Every time new db is created in  prod, need to execute below script as well:

grant all on database AppDB to "prodgke-devops-serviceacc@cb0228600a-citprod-gc.iam";

grant temp,connect on Database AppDB to AppGSA;
ALTER DEFAULT PRIVILEGES
FOR ROLE "prodgke-devops-serviceacc@cb0228600a-citprod-gc.iam"
GRANT EXECUTE ON ROUTINES TO AppGSA;
grant db_datareader,db_datawriter to AppGSA;


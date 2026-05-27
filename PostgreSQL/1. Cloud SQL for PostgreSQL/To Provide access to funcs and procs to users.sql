GRANT db_datareader, db_datawriter TO "clientdrift-5043-np-sa@cb0104074a-citnonprod-gc.iam";

GRANT "clientdrift-5043-np-sa@cb0104074a-citnonprod-gc.iam" TO postgres WITH ADMIN OPTION;

grant connect,temp on database "OneC_5043" to "clientdrift-5043-np-sa@cb0104074a-citnonprod-gc.iam";

GRANT USAGE ON SCHEMA public TO "clientdrift-5043-np-sa@cb0104074a-citnonprod-gc.iam";
GRANT EXECUTE ON ALL ROUTINES IN SCHEMA public TO "clientdrift-5043-np-sa@cb0104074a-citnonprod-gc.iam";

ALTER DEFAULT PRIVILEGES
FOR ROLE "npgke-devops-serviceacc@cb0104074a-citnonprod-gc.iam","OneC_5043"
IN SCHEMA public
GRANT EXECUTE ON ROUTINES TO "clientdrift-5043-np-sa@cb0104074a-citnonprod-gc.iam";
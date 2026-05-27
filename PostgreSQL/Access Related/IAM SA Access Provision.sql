CREATE ROLE "some-iam-user@your-project.iam" WITH LOGIN;


ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT SELECT, USAGE ON SEQUENCES TO "csagenticaiapp-smp-4652-np-sa@cb0104074a-citnonprod-gc.iam";

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT EXECUTE ON FUNCTIONS TO "csagenticaiapp-smp-4652-np-sa@cb0104074a-citnonprod-gc.iam";

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT USAGE ON TYPES TO "csagenticaiapp-smp-4652-np-sa@cb0104074a-citnonprod-gc.iam";


GRANT connect ON DATABASE "GKEPOC" TO "npgke-devops-serviceacc@cb0104074a-citnonprod-gc.iam";


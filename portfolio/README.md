# Multi-Cloud Database Administration Toolkit — Portfolio Edition

A curated portfolio-ready version of my DBA toolkit showcasing production-ready scripts, troubleshooting playbooks, and runnable demos. This branch presents the highlights I use when sharing my work on a resume or with hiring managers.

## Highlights for resume
- Maintained 100+ T-SQL scripts for operational DB administration: backups, replication troubleshooting, index maintenance, Query Store analysis.
- Implemented a reusable, parameterized Query Store plan lookup (MSSQLServer/QueryStore/QueryStore_PlanLookup_Parameterized.sql).
- Packaged an MSSQL Docker demo so reviewers can run core examples locally from demos/mssql.
- Consolidated and documented the canonical whoisactive implementation.

## How this branch differs
- README and demos added for quick evaluation.
- Small, non-destructive edits: parameterized Query Store snippets and added safe headers to edited files.
- Created /portfolio and /demos folders with runnable examples.

## Run the demo (quick)
1. Clone and checkout portfolio branch:
   git clone https://github.com/Vishnupyda007/Multi-Cloud-Database-Administration-Toolkit.git
   cd Multi-Cloud-Database-Administration-Toolkit
   git checkout portfolio/cleaned

2. Run MSSQL demo (requires Docker):
   cd demos/mssql
   docker compose up -d
   # Wait ~30s then run the example script from the host:
   docker exec -it mssql-demo /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong!Passw0rd' -i /scripts/demo_querystore_lookup.sql

3. Tear down:
   docker compose down

## Next steps / open issues
See the linked issues in this PR for remaining TODOs (whoisactive parsing edge cases, applock handling, extra demos, CI polishing).

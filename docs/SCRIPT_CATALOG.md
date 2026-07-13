# Script Catalog & Index

## Overview

This document provides a searchable index of all scripts in the Multi-Cloud Database Administration Toolkit.

---

## Quick Search

### By Platform
- [AWS Scripts](#aws-scripts)
- [Azure Scripts](#azure-scripts)
- [GCP Scripts](#gcp-scripts)
- [SQL Server Scripts](#sql-server-scripts)
- [PostgreSQL Scripts](#postgresql-scripts)

### By Category
- [Backup & Recovery](#backup--recovery)
- [Performance Tuning](#performance-tuning)
- [Monitoring](#monitoring)
- [Administration](#administration)
- [Replication](#replication)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

---

## AWS Scripts

### Backup & Recovery
| Script | Type | Complexity | Purpose | Location |
|--------|------|-----------|---------|----------|
| RDS Automated Backup Setup | Bash/CLI | Simple | Configure automated backups | `AWS/RDS/backup-management/` |
| RDS Snapshot Export | Bash | Simple | Export snapshots to S3 | `AWS/RDS/backup-management/` |
| RDS Point-in-Time Recovery | Bash | Medium | Restore to specific point in time | `AWS/RDS/backup-management/` |
| Aurora Backup Strategy | Bash | Medium | Aurora-specific backup config | `AWS/Aurora/` |

### Performance Tuning
| Script | Type | Complexity | Purpose | Location |
|--------|------|-----------|---------|----------|
| RDS Parameter Group Optimizer | Bash/Python | Medium | Optimize database parameters | `AWS/RDS/performance-tuning/` |
| Query Performance Analysis | SQL | Medium | Analyze slow queries | `AWS/RDS/performance-tuning/` |
| Index Optimization | SQL | Advanced | Build and maintain indexes | `AWS/RDS/performance-tuning/` |

### Monitoring
| Script | Type | Complexity | Purpose | Location |
|--------|------|-----------|---------|----------|
| CloudWatch Metrics Dashboard | CloudFormation | Simple | Setup monitoring dashboards | `AWS/RDS/monitoring/` |
| Enhanced Monitoring Setup | CLI | Simple | Enable enhanced RDS monitoring | `AWS/RDS/monitoring/` |
| Custom Alerts Configuration | CloudFormation | Medium | Create custom CloudWatch alarms | `AWS/RDS/monitoring/` |

---

## Azure Scripts

### Backup & Recovery
| Script | Type | Complexity | Purpose | Location |
|--------|------|-----------|---------|----------|
| SQL DB Automated Backup | PowerShell | Simple | Configure Azure SQL backups | `Azure/SQL-Database/backup-recovery/` |
| Restore from Backup Point | T-SQL/PowerShell | Medium | Restore database from backup | `Azure/SQL-Database/backup-recovery/` |
| Geo-Replication Setup | PowerShell | Medium | Configure active geo-replication | `Azure/SQL-Database/backup-recovery/` |
| CosmosDB Backup | PowerShell | Simple | Configure CosmosDB backups | `Azure/CosmosDB/` |

### Elastic Pools
| Script | Type | Complexity | Purpose | Location |
|--------|------|-----------|---------|----------|
| Create Elastic Pool | PowerShell | Simple | Create new elastic pool | `Azure/SQL-Database/elastic-pools/` |
| Move Database to Pool | PowerShell | Simple | Migrate database to elastic pool | `Azure/SQL-Database/elastic-pools/` |
| Monitor Pool Performance | T-SQL | Medium | Monitor pool resource usage | `Azure/SQL-Database/elastic-pools/` |

### Managed Instance
| Script | Type | Complexity | Purpose | Location |
|--------|------|-----------|---------|----------|
| MI Creation Template | ARM Template | Simple | Deploy managed instance | `Azure/SQL-Database/managed-instances/` |
| MI Failover Setup | PowerShell | Medium | Configure MI failover groups | `Azure/SQL-Database/managed-instances/` |

---

## GCP Scripts

### Cloud SQL
| Script | Type | Complexity | Purpose | Location |
|--------|------|-----------|---------|----------|
| Cloud SQL Backup Config | gcloud/Bash | Simple | Setup automated backups | `GCP/Cloud-SQL/backup-recovery/` |
| Point-in-Time Recovery | gcloud/Bash | Medium | Restore to specific point | `GCP/Cloud-SQL/backup-recovery/` |
| Replication Setup | gcloud/Bash | Medium | Configure read replicas | `GCP/Cloud-SQL/replication/` |
| High Availability Config | gcloud/Bash | Medium | Enable HA regional failover | `GCP/Cloud-SQL/backup-recovery/` |

### BigQuery
| Script | Type | Complexity | Purpose | Location |
|--------|------|-----------|---------|----------|
| Dataset Management | bq CLI/Python | Simple | Create and manage datasets | `GCP/BigQuery/` |
| Export Datasets | bq CLI | Simple | Export data to Cloud Storage | `GCP/BigQuery/` |
| Query Optimization | SQL | Medium | Optimize BigQuery queries | `GCP/BigQuery/` |

### Firestore
| Script | Type | Complexity | Purpose | Location |
|--------|------|-----------|---------|----------|
| Firestore Backup | gcloud/Bash | Simple | Create Firestore backups | `GCP/Firestore/` |
| Data Export | gcloud/Bash | Simple | Export Firestore data | `GCP/Firestore/` |

---

## SQL Server Scripts

### Administration
| Script | Type | Complexity | Purpose |
|--------|------|-----------|----------|
| User & Login Management | T-SQL | Simple | Create users, roles, permissions |
| Database Creation | T-SQL | Simple | Create new databases |
| Server Configuration | T-SQL | Simple | Configure server settings |

### Backup & Recovery
| Script | Type | Complexity | Purpose |
|--------|------|-----------|----------|
| Full Database Backup | T-SQL | Simple | Create full backup |
| Transaction Log Backup | T-SQL | Simple | Backup transaction logs |
| Restore Procedure | T-SQL | Medium | Restore from backup |
| Point-in-Time Recovery | T-SQL | Advanced | Time-based recovery |

### Performance
| Script | Type | Complexity | Purpose |
|--------|------|-----------|----------|
| Query Analysis | T-SQL | Medium | Find slow queries |
| Index Maintenance | T-SQL | Medium | Rebuild and reorganize indexes |
| Statistics Update | T-SQL | Simple | Update table statistics |
| Execution Plans | T-SQL | Advanced | Analyze query plans |

### Monitoring
| Script | Type | Complexity | Purpose |
|--------|------|-----------|----------|
| Server Health Check | T-SQL | Simple | Monitor server health |
| Resource Utilization | T-SQL | Simple | Check CPU, memory, disk |
| Active Sessions | T-SQL | Simple | List active connections |
| Error Log Analysis | T-SQL | Medium | Review SQL Server errors |

### Replication
| Script | Type | Complexity | Purpose |
|--------|------|-----------|----------|
| Setup Replication | T-SQL | Advanced | Configure transactional replication |
| Monitor Replication | T-SQL | Medium | Monitor replication status |
| Failover Procedures | T-SQL | Advanced | Manual failover steps |

---

## PostgreSQL Scripts

### Administration
| Script | Type | Complexity | Purpose |
|--------|------|-----------|----------|
| Role Management | PL/pgSQL | Simple | Create roles and permissions |
| Database Setup | PL/pgSQL | Simple | Create databases |
| Configuration | PL/pgSQL | Simple | Tune postgresql.conf |

### Performance
| Script | Type | Complexity | Purpose |
|--------|------|-----------|----------|
| Query Analysis | PL/pgSQL | Medium | Find slow queries |
| Index Optimization | PL/pgSQL | Medium | Build and maintain indexes |
| VACUUM & ANALYZE | PL/pgSQL | Simple | Maintain database |
| Statistics Analysis | PL/pgSQL | Medium | Tune table statistics |

### Replication
| Script | Type | Complexity | Purpose |
|--------|------|-----------|----------|
| Streaming Replication Setup | PL/pgSQL | Advanced | Configure logical/physical replication |
| Monitor Replication Lag | PL/pgSQL | Medium | Monitor replica status |
| Failover Procedures | Bash | Advanced | Perform failover |

### Troubleshooting
| Script | Type | Complexity | Purpose |
|--------|------|-----------|----------|
| Connection Analysis | PL/pgSQL | Simple | Debug connection issues |
| Bloat Analysis | PL/pgSQL | Medium | Analyze table bloat |
| Lock Investigation | PL/pgSQL | Medium | Find blocking locks |

---

## Backup & Recovery

### All Platforms
| Script | Platform | Frequency | Purpose |
|--------|----------|-----------|----------|
| Automated Backup Setup | AWS | Continuous | Enable auto backups |
| Backup Retention Policy | Azure | Daily | Manage backup lifecycle |
| Cross-Region Backup | GCP | Daily | Replicate backups to another region |
| Backup Verification | All | Weekly | Verify backup integrity |
| Disaster Recovery Test | All | Monthly | Test recovery procedures |

---

## Performance Tuning

### All Platforms
| Category | Scripts | Focus |
|----------|---------|-------|
| Query Analysis | slowlog, execution plans | Find bottlenecks |
| Index Management | create, rebuild, drop | Optimize access |
| Parameter Tuning | memory, workers, cache | Configure for workload |
| Resource Management | CPU, memory, disk | Right-size instances |

---

## Monitoring

### All Platforms
| Component | Metric | Alert Threshold |
|-----------|--------|------------------|
| CPU | % Used | >80% |
| Memory | % Available | <20% |
| Disk | % Used | >80% |
| Connections | Active | Platform-specific |
| Replication Lag | Seconds | >30s |
| Backup Status | Success Rate | <100% |

---

## Script Metadata

Each script should include:

```
┌─────────────────────────────────┐
│ Script Name                     │
├─────────────────────────────────┤
│ Platform: AWS/Azure/GCP/OnPrem  │
│ Category: Backup/Performance... │
│ Language: SQL/PowerShell/Bash   │
│ Complexity: Simple/Medium/Adv   │
│ Prerequisites: ...              │
│ Parameters: ...                 │
│ Expected Output: ...            │
│ Version: 1.0                    │
│ Updated: 2026-07-13             │
│ Status: Production-Ready        │
└─────────────────────────────────┘
```

---

## Scripts by Complexity

### Simple (Beginner)
- Database creation
- User management
- Backup setup
- Basic monitoring
- Health checks

### Medium (Intermediate)
- Query optimization
- Index management
- Performance analysis
- Replication setup
- Custom monitoring

### Advanced (Expert)
- Complex migrations
- Disaster recovery procedures
- Failover automation
- Performance tuning
- Custom solutions

---

## How to Use This Catalog

1. **Find by Platform:** Look for your cloud provider section
2. **Find by Category:** Use the quick search links
3. **Find by Complexity:** Choose scripts matching your skill level
4. **Find by Purpose:** Search the tables for your use case
5. **Check Prerequisites:** Review requirements before running
6. **Review Documentation:** Read the script's README file
7. **Test First:** Always test in non-production environment

---

## Adding New Scripts

When contributing new scripts:
1. Update this catalog with metadata
2. Include script header with version/status
3. Create README in category folder
4. Update `scripts.json` metadata file
5. Add entry to CHANGELOG.md

---

**Last Updated:** 2026-07-13  
**Total Scripts:** 130+  
**Platforms:** 5 (AWS, Azure, GCP, SQL Server, PostgreSQL)  
**Categories:** 8 (Backup, Performance, Monitoring, Admin, Replication, Security, Troubleshooting, Migration)
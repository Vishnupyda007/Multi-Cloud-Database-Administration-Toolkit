# GCP Database Scripts

Comprehensive database administration scripts for Google Cloud Platform (GCP).

## 📋 Table of Contents

- [Overview](#overview)
- [Cloud SQL Scripts](#cloud-sql-scripts)
- [BigQuery Scripts](#bigquery-scripts)
- [Firestore Scripts](#firestore-scripts)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Best Practices](#best-practices)

---

## Overview

This folder contains scripts for managing various GCP database services:

| Service | Type | Scripts |
|---------|------|---------|
| **Cloud SQL** | RDBMS | Backup, Restore, Monitoring |
| **BigQuery** | Data Warehouse | Export, Import, Queries |
| **Firestore** | NoSQL | Backup, Restore, Export |
| **Datastore** | NoSQL | Document database operations |

---

## Cloud SQL Scripts

### Directory Structure
```
CloudSQL/
├── backup-cloudsql.sh         # Automated backup
├── restore-cloudsql.sh        # Restore procedure
├── export-cloudsql.sh         # Export to Cloud Storage
├── monitoring-cloudsql.sql    # Performance queries
└── README.md                  # Documentation
```

### Usage

```bash
# Create backup
./backup-cloudsql.sh --instance "myinstance" --region "us-central1"

# Restore from backup
./restore-cloudsql.sh --instance "myinstance" --backup-id "backup123"

# Export to Cloud Storage
./export-cloudsql.sh --instance "myinstance" --database "mydb" \
  --bucket "gs://mybackups"
```

---

## BigQuery Scripts

### Directory Structure
```
BigQuery/
├── export-bigquery.sh         # Export datasets
├── dataset-management.sh      # Dataset operations
├── optimization-queries.sql   # Performance optimization
├── bq-queries.sql             # Useful BigQuery queries
└── README.md                  # Documentation
```

### Usage

```bash
# Export table to Cloud Storage
./export-bigquery.sh --project "my-project" --dataset "my_dataset" \
  --table "my_table" --bucket "gs://mybackups"

# Manage datasets
./dataset-management.sh --action "create" --dataset "new_dataset" \
  --project "my-project"

# Run optimization queries
bq query --use_legacy_sql=false < optimization-queries.sql
```

---

## Firestore Scripts

### Directory Structure
```
Firestore/
├── backup-firestore.sh        # Firestore backup
├── restore-firestore.sh       # Restore from backup
├── export-firestore.sh        # Export data
└── README.md                  # Documentation
```

### Usage

```bash
# Create backup
./backup-firestore.sh --project "my-project"

# Restore from backup
./restore-firestore.sh --project "my-project" --backup-id "backup123"

# Export data
./export-firestore.sh --project "my-project" \
  --bucket "gs://mybackups/firestore"
```

---

## Deployment Manager Templates

### Directory Structure
```
Deployment-Manager/
├── deployment.yaml            # Deployment configuration
├── resources.yaml             # Resource definitions
└── README.md                  # Documentation
```

### Usage

```bash
# Create deployment
gcloud deployment-manager deployments create my-deployment \
  --config deployment.yaml

# Update deployment
gcloud deployment-manager deployments update my-deployment \
  --config deployment.yaml

# Delete deployment
gcloud deployment-manager deployments delete my-deployment
```

---

## Prerequisites

### GCP Setup

```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash

# Initialize SDK
gcloud init

# Verify installation
gcloud --version
```

### Required Permissions

Your GCP user needs these roles:

- **Cloud SQL**: Cloud SQL Admin
- **BigQuery**: BigQuery Admin
- **Firestore**: Firestore Service Agent
- **Cloud Storage**: Storage Admin
- **Service Accounts**: Service Account User

### Tools Required

- Google Cloud SDK (gcloud)
- Bash 4.0+
- Node.js 14+ (for JavaScript scripts)
- Python 3.7+ (for Python scripts)
- bq CLI (included with Cloud SDK)

---

## Quick Start

### 1. Configure GCP SDK

```bash
# Initialize gcloud
gcloud init

# Set default project
gcloud config set project MY_PROJECT_ID

# Authenticate
gcloud auth login

# Verify
gcloud config list
```

### 2. Enable Required APIs

```bash
# Enable Cloud SQL API
gcloud services enable sqladmin.googleapis.com

# Enable BigQuery API
gcloud services enable bigquery.googleapis.com

# Enable Firestore API
gcloud services enable firestore.googleapis.com
```

### 3. Run Your First Script

```bash
# Example: Backup Cloud SQL
./CloudSQL/backup-cloudsql.sh --instance "myinstance"

# Monitor backup
gcloud sql backups list --instance "myinstance"
```

---

## Best Practices

### Security

- ✅ Use Cloud IAM roles for access control
- ✅ Enable Cloud SQL Auth proxy
- ✅ Use Cloud SQL client certificates
- ✅ Enable Cloud SQL SSL/TLS
- ✅ Use Cloud KMS for encryption
- ✅ Enable audit logging
- ✅ Use VPC Service Controls

### Performance

- ✅ Choose appropriate machine types
- ✅ Use read replicas for scaling
- ✅ Enable automated backups
- ✅ Monitor CPU and memory usage
- ✅ Optimize queries
- ✅ Use connection pooling
- ✅ Configure slow query logs

### Cost Optimization

- ✅ Use committed use discounts (CUD)
- ✅ Use Cloud SQL HA where needed
- ✅ Archive old BigQuery data to Cloud Storage
- ✅ Monitor and delete unused resources
- ✅ Right-size machine types
- ✅ Use Firestore autoscaling carefully

### Disaster Recovery

- ✅ Enable automated backups
- ✅ Use Cloud SQL HA (High Availability)
- ✅ Cross-region backups
- ✅ Regular restore testing
- ✅ Document RTO and RPO
- ✅ Create disaster recovery playbooks
- ✅ Use Cloud SQL replicas

---

## Troubleshooting

### Common Issues

**Issue: gcloud command not found**
```bash
# Solution: Reinstall Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

**Issue: Permission denied**
```bash
# Solution: Check project and permissions
gcloud config list
gcloud projects get-iam-policy PROJECT_ID
```

**Issue: Cloud SQL connection fails**
```bash
# Solution: Verify instance and firewall
gcloud sql instances describe INSTANCE_ID
gcloud sql connect INSTANCE_ID --user=root
```

**Issue: BigQuery API not enabled**
```bash
# Solution: Enable the API
gcloud services enable bigquery.googleapis.com
```

---

## Support

- 📖 [Cloud SQL Documentation](https://cloud.google.com/sql/docs)
- 📖 [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- 📖 [Firestore Documentation](https://cloud.google.com/firestore/docs)
- 📖 [gcloud CLI Reference](https://cloud.google.com/sdk/gcloud/reference)
- 💬 [GCP Support](https://cloud.google.com/support/)

---

**Last Updated:** 2026-05-27
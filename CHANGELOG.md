# Changelog

All notable changes to this project will be documented in this file.

## Format

This project follows [Keep a Changelog](https://keepachangelog.com/) conventions.

---

## [Unreleased]

### Added
- Comprehensive documentation structure in `/docs`
- Architecture documentation (`ARCHITECTURE.md`)
- Prerequisites guide (`PREREQUISITES.md`)
- Script catalog and index (`SCRIPT_CATALOG.md`)
- Quick start guides for all platforms
- Script metadata index (`scripts.json`)
- GitHub security workflow (pre-commit hooks)
- Changelog (this file)

### Planned
- AWS RDS backup automation scripts
- Azure SQL automated backup scripts
- GCP Cloud SQL backup scripts
- PostgreSQL migration from MSSQL scripts
- Advanced replication scripts
- Performance tuning automation

---

## [1.0] - 2026-07-13

### Initial Release

**Repository Created:** 2026-05-27

### Added
- Core repository structure
- README.md with comprehensive overview
- SECURITY.md with security guidelines
- CONTRIBUTING.md with contribution guidelines
- GETTING-STARTED.md for new users
- AWS folder with placeholder
- Azure folder with README and PowerShell examples
- GCP folder with README and shell examples
- MSSQLServer folder with 100+ T-SQL scripts
- PostgreSQL folder with 20+ SQL and helper scripts
- Automation folder for cross-platform scripts
- Learnings folder for educational resources
- .env.example for environment setup
- .gitignore for security

### Platforms Supported
- AWS (RDS, Aurora)
- Azure (SQL Database, CosmosDB, PostgreSQL)
- GCP (Cloud SQL, BigQuery, Firestore)
- Microsoft SQL Server 2016+
- PostgreSQL 10+

### Categories Included
- Backup & Recovery (20+ scripts)
- Performance Tuning (15+ scripts)
- Monitoring (10+ scripts)
- Administration (15+ scripts)
- Replication (5+ scripts)
- Security (10+ scripts)
- Troubleshooting (25+ scripts)
- Migration (5+ scripts)

---

## Version History

| Version | Date | Status | Changes |
|---------|------|--------|----------|
| 1.0 | 2026-07-13 | Released | Initial release |
| 0.9 | 2026-07-01 | Beta | Pre-release testing |
| 0.1 | 2026-05-27 | Alpha | Initial setup |

---

## Deprecated

### Scripts to be Removed
- `MSSQLServer/Azure_New_test.ps1` (test file, not production-ready)
- Duplicate backup scripts (consolidating into single implementation)

### Status: DEPRECATED
The following files are no longer maintained:
- `MSSQLServer/Azure_New_test.ps1`
- `PostgreSQL/PostgreSQLScripts` (moved to subdirectories)

---

## Known Issues

### Current
- AWS, Azure, and GCP folders contain mostly placeholders and READMEs
- MSSQLServer scripts not fully organized by category
- PostgreSQL scripts mixed in root directory
- No GitHub Actions workflows for testing

### Planned Fixes
- [x] Create documentation structure
- [ ] Organize all scripts by category
- [ ] Add GitHub Actions workflows
- [ ] Create platform-specific quick starts
- [ ] Add script validation and testing

---

## Migration Guide

For users upgrading from earlier versions:

### From Alpha (0.1) to Beta (0.9)
- No breaking changes
- New documentation added

### From Beta (0.9) to Release (1.0)
- Scripts reorganized (check `docs/SCRIPT_CATALOG.md`)
- New documentation structure (`docs/` folder)
- `scripts.json` metadata file added

---

## Contributing

When making changes:

1. Update this CHANGELOG.md
2. Use format: `## [version] - YYYY-MM-DD`
3. Add to appropriate section (Added/Changed/Fixed/Removed/Deprecated/Security)
4. Include PR reference: `(#123)`
5. Update version in `scripts.json`

See [CONTRIBUTING.md](./CONTRIBUTING.md) for full guidelines.

---

## Release Schedule

- **v1.0** (2026-07-13): Documentation & structure
- **v1.1** (2026-08-15): AWS RDS scripts
- **v1.2** (2026-09-15): Azure SQL scripts
- **v1.3** (2026-10-15): GCP Cloud SQL scripts
- **v2.0** (2026-12-15): Full feature release

---

## Support

- 📖 Documentation: See `/docs` folder
- 🐛 Issues: Open GitHub issue
- 💬 Discussions: Start GitHub discussion
- 🤝 Contributing: See [CONTRIBUTING.md](./CONTRIBUTING.md)
- 📧 Contact: Check repository for contact info

---

**Last Updated:** 2026-07-13
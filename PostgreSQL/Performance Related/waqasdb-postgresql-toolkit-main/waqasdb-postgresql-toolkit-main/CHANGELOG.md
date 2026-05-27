
# Changelog

All notable changes to this project will be documented here.

## [0.1.0] - 2026-02-21

### Added
- Lab 01: Bloat Analysis & Recovery
  - 11 SQL scripts for complete bloat lifecycle
  - pgstattuple analysis (tuple-level bloat measurement)
  - pg_freespacemap analysis (216,704 pages inspected)
  - VACUUM vs VACUUM FULL comparison
  - Autovacuum per-table tuning
  - Re-run workload with tuned settings
  - Results: 50% storage recovery (1,693 MB → 847 MB)
  - Results: Tuned autovacuum ran 3x vs 1x default
- Diagnostic toolkit (reusable audit queries)
- Client deliverable templates
- Case study: Bloat 50% recovery
- Emergency runbook
- Project documentation with structure and values

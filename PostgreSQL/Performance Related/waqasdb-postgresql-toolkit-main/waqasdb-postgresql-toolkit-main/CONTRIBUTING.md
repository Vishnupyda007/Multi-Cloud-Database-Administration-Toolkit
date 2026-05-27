cat > CONTRIBUTING.md << 'EOF'
# Contributing to PostgreSQL Performance Toolkit

بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ

## Our Values

1. **Itqān (إتقان)** — Every contribution must be tested and documented
2. **Amānah (أمانة)** — All benchmarks must be real and reproducible
3. **Nafa'a (نفع)** — Contributions should benefit the community

## How to Contribute

### Report Issues
- Describe the problem clearly
- Include PostgreSQL version and OS
- Share error messages or unexpected results

### Submit a Lab
- Follow the existing folder structure
- Include README.md with full documentation
- Provide reproducible scripts
- Include your actual results in results/
- Test on PostgreSQL 14+

### Folder Structure for New Labs
XX-lab-name/   
├── README.md   
├── scripts/   
│ ├── 01-setup.sql   
│ ├── 02-workload.sql   
│ └── 03-measure.sql   
├── results/   
│ └── results.csv   
└── images/   
└── summary.png   


### Code Standards

- All SQL files start with a header comment block
- Include progress messages with RAISE NOTICE or \echo
- Use timing for performance-sensitive scripts
- Never hardcode credentials
- Include cleanup instructions
- Test scripts before submitting

### Commit Messages
feat: Add WAL monitoring lab   
fix: Correct bloat calculation formula   
docs: Update README with new results   


## Questions?

📩 consulting@waqasdb.com   
🌐 waqasdb.com

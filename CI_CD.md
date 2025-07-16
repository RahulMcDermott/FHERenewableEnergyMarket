# CI/CD Documentation

## Continuous Integration and Deployment Pipeline

This document describes the automated CI/CD pipeline for the Private Renewable Energy Market project.

---

## Table of Contents

1. [Overview](#overview)
2. [GitHub Actions Workflows](#github-actions-workflows)
3. [Code Quality Tools](#code-quality-tools)
4. [Coverage Reporting](#coverage-reporting)
5. [Security Scanning](#security-scanning)
6. [Setup Instructions](#setup-instructions)
7. [Troubleshooting](#troubleshooting)

---

## Overview

### CI/CD Pipeline Features

✅ **Automated Testing** - Tests run on every push and pull request
✅ **Multiple Node.js Versions** - Tests on Node.js 18.x and 20.x
✅ **Code Quality Checks** - Solhint and Prettier integration
✅ **Coverage Reporting** - Codecov integration
✅ **Gas Reporting** - Automatic gas usage analysis
✅ **Security Audits** - Dependency vulnerability scanning
✅ **Build Verification** - Contract compilation checks

### Trigger Conditions

The CI/CD pipeline runs automatically on:

- **Push to main branch**
- **Push to develop branch**
- **All pull requests** to main or develop
- Manual workflow dispatch (optional)

---

## GitHub Actions Workflows

### Main Workflow: `.github/workflows/test.yml`

The main CI/CD workflow consists of 6 parallel jobs:

#### 1. **Test Job** (`test`)

Runs comprehensive test suite on multiple Node.js versions.

```yaml
strategy:
  matrix:
    node-version: [18.x, 20.x]
```

**Steps:**
1. Checkout repository
2. Setup Node.js (18.x or 20.x)
3. Install dependencies (`npm ci`)
4. Check dependency vulnerabilities
5. Compile contracts
6. Run Solhint linter
7. Execute test suite
8. Generate coverage report (Node 20.x only)
9. Upload coverage to Codecov
10. Archive test results

**Artifacts Generated:**
- `test-results-18.x/` - Test results for Node.js 18.x
- `test-results-20.x/` - Test results for Node.js 20.x
- `coverage/` - Coverage reports

#### 2. **Lint Job** (`lint`)

Performs code quality checks.

**Steps:**
1. Checkout repository
2. Setup Node.js 20.x
3. Install dependencies
4. Run Solhint (Solidity linter)
5. Check code formatting (Prettier)

**Tools Used:**
- **Solhint** - Solidity code linter
- **Prettier** - Code formatter

#### 3. **Build Job** (`build`)

Compiles contracts and archives artifacts.

**Steps:**
1. Checkout repository
2. Setup Node.js 20.x
3. Install dependencies
4. Compile contracts
5. Archive compilation artifacts

**Artifacts Generated:**
- `compiled-contracts/` - Compiled contract artifacts and cache

#### 4. **Gas Report Job** (`gas-report`)

Generates gas usage reports and posts to PR.

**Steps:**
1. Checkout repository
2. Setup Node.js 20.x
3. Install dependencies
4. Compile contracts
5. Generate gas report
6. Upload gas report artifact
7. Comment on PR with gas usage (if applicable)

**Artifacts Generated:**
- `gas-report.txt` - Gas usage analysis

#### 5. **Security Job** (`security`)

Scans for security vulnerabilities.

**Steps:**
1. Checkout repository
2. Setup Node.js 20.x
3. Install dependencies
4. Run npm audit
5. Generate security audit report
6. Upload audit results

**Artifacts Generated:**
- `security-audit/audit-report.json` - Security scan results

#### 6. **Success Job** (`success`)

Final check ensuring all jobs passed.

**Dependencies:** Requires all previous jobs to complete

**Steps:**
1. Check test job status
2. Check build job status
3. Report overall pipeline status

---

## Code Quality Tools

### Solhint - Solidity Linter

Configuration: `.solhint.json`

**Rules Enforced:**
- Compiler version constraints
- Function visibility requirements
- Naming conventions (camelCase, snake_case)
- Code complexity limits (max 8)
- Maximum line length (120 characters)
- Maximum states count (15)
- Security best practices
- Style guidelines

**Usage:**

```bash
# Run linter
npm run lint:sol

# Auto-fix issues
npm run lint:fix
```

**Example Output:**
```
contracts/PrivateRenewableEnergyMarket.sol
  45:5  warning  Line length must be no more than 120  max-line-length
  78:9  error    Explicitly mark visibility in function  func-visibility

✖ 2 problems (1 error, 1 warning)
```

### Prettier - Code Formatter

Configuration: `.prettierrc.json`

**Settings:**
- **Solidity files**: 120 char width, 4 space tabs, double quotes
- **JavaScript files**: 100 char width, 2 space tabs, semicolons

**Usage:**

```bash
# Format all files
npm run format

# Check formatting
npm run format:check
```

**Files Formatted:**
- `contracts/**/*.sol` - All Solidity contracts
- `test/**/*.js` - All test files
- `scripts/**/*.js` - All deployment scripts

---

## Coverage Reporting

### Codecov Integration

Configuration: `codecov.yml`

**Coverage Targets:**
- **Project Coverage**: 80% (minimum)
- **Patch Coverage**: 75% (minimum)
- **Threshold**: 5% decrease allowed

**Features:**
- Automatic coverage reports on PRs
- Visual coverage diff
- Line-by-line coverage annotations
- GitHub checks integration

**Setup:**

1. **Add Codecov Token to GitHub Secrets:**
   - Go to repository Settings → Secrets → Actions
   - Add secret: `CODECOV_TOKEN`
   - Value: Get from https://codecov.io

2. **Badge for README:**
```markdown
[![codecov](https://codecov.io/gh/YOUR_ORG/YOUR_REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_ORG/YOUR_REPO)
```

**Manual Coverage Generation:**

```bash
npm run coverage
```

**Output Locations:**
- `coverage/` - HTML coverage report
- `coverage/lcov.info` - LCOV format (for Codecov)

---

## Security Scanning

### npm audit

**Runs Automatically:**
- On every push and PR
- With both moderate and high severity thresholds

**Manual Security Check:**

```bash
# Check for vulnerabilities
npm audit

# Auto-fix vulnerabilities
npm audit fix

# View detailed report
npm audit --json > audit-report.json
```

**Severity Levels:**
- `low` - Continue on error
- `moderate` - Warning only
- `high` - Fails security job
- `critical` - Fails security job

---

## Setup Instructions

### Initial Setup

#### 1. Enable GitHub Actions

GitHub Actions are enabled by default. Ensure they're not disabled:
1. Go to repository Settings → Actions → General
2. Select "Allow all actions and reusable workflows"
3. Click "Save"

#### 2. Configure Secrets

Add these secrets to your repository:

**Required:**
- `CODECOV_TOKEN` - From https://codecov.io

**Optional:**
- `SLACK_WEBHOOK` - For notifications
- `DISCORD_WEBHOOK` - For notifications

**How to Add Secrets:**
1. Navigate to repository Settings
2. Click "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Add name and value
5. Click "Add secret"

#### 3. Install Dependencies Locally

```bash
npm install
```

This installs:
- Hardhat and plugins
- Solhint
- Prettier
- Testing dependencies

#### 4. Verify Local Setup

```bash
# Test compilation
npm run compile

# Run tests
npm test

# Run linters
npm run lint

# Check formatting
npm run format:check
```

### Branch Protection Rules

**Recommended Settings:**

1. Go to repository Settings → Branches
2. Add rule for `main` branch:
   - ✅ Require pull request reviews
   - ✅ Require status checks to pass:
     - Test on Node.js 18.x
     - Test on Node.js 20.x
     - Code Quality Checks
     - Build and Compile
     - Gas Usage Report
   - ✅ Require conversation resolution
   - ✅ Do not allow bypassing

---

## Workflow Status Badges

Add these badges to your README.md:

### CI Status
```markdown
![CI](https://github.com/YOUR_ORG/YOUR_REPO/workflows/Continuous%20Integration/badge.svg)
```

### Coverage
```markdown
[![codecov](https://codecov.io/gh/YOUR_ORG/YOUR_REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_ORG/YOUR_REPO)
```

### License
```markdown
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
```

### Node Version
```markdown
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen)](https://nodejs.org/)
```

---

## Troubleshooting

### Common Issues

#### Issue: "Tests failing in CI but pass locally"

**Possible Causes:**
- Environment variable differences
- Node.js version mismatch
- Dependency version conflicts

**Solution:**
```bash
# Test with specific Node version
nvm use 18
npm test

# Clean install
rm -rf node_modules package-lock.json
npm install
npm test
```

#### Issue: "Solhint errors in CI"

**Solution:**
```bash
# Run locally first
npm run lint:sol

# Auto-fix
npm run lint:fix

# Check specific file
npx solhint contracts/YourContract.sol
```

#### Issue: "Coverage upload fails"

**Solution:**
1. Verify CODECOV_TOKEN is set in GitHub secrets
2. Check codecov.yml syntax
3. Review Codecov dashboard for errors

#### Issue: "npm audit fails with vulnerabilities"

**Solution:**
```bash
# Review audit report
npm audit

# Attempt auto-fix
npm audit fix

# Force fix (may have breaking changes)
npm audit fix --force

# Update specific package
npm update package-name
```

#### Issue: "Gas report not commenting on PR"

**Possible Causes:**
- Missing GitHub token permissions
- PR from forked repository

**Solution:**
1. Ensure workflow has `write` permission for PRs
2. Check Actions permissions in repository settings

---

## Continuous Deployment (Future)

### Planned Features

🔜 **Automatic Testnet Deployment**
- Deploy to Sepolia on merge to develop
- Verify contracts automatically

🔜 **Release Automation**
- Semantic versioning
- Automated changelog generation
- GitHub releases

🔜 **Documentation Deployment**
- Auto-generate and deploy documentation
- Deploy to GitHub Pages

### Testnet Deployment Workflow

**Future workflow** (`.github/workflows/deploy.yml`):

```yaml
name: Deploy to Testnet

on:
  push:
    branches: [develop]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm run deploy
        env:
          PRIVATE_KEY: ${{ secrets.DEPLOYER_PRIVATE_KEY }}
          SEPOLIA_RPC_URL: ${{ secrets.SEPOLIA_RPC_URL }}
```

---

## Metrics and Reporting

### Pipeline Performance

Average execution times:
- **Test Job**: ~3-5 minutes
- **Lint Job**: ~1-2 minutes
- **Build Job**: ~2-3 minutes
- **Gas Report**: ~3-4 minutes
- **Security**: ~1-2 minutes

**Total Pipeline Time**: ~5-7 minutes

### Success Rates

Target success rates:
- **Main Branch**: 100% (required)
- **Develop Branch**: >95%
- **Pull Requests**: >90%

---

## Best Practices

### For Developers

1. **Run tests locally** before pushing
   ```bash
   npm test
   ```

2. **Check linting** before committing
   ```bash
   npm run lint
   ```

3. **Format code** before pushing
   ```bash
   npm run format
   ```

4. **Review coverage** for new code
   ```bash
   npm run coverage
   ```

5. **Check gas usage** for optimizations
   ```bash
   npm run test:gas
   ```

### For Reviewers

1. Wait for all CI checks to pass
2. Review coverage reports
3. Check gas usage changes
4. Verify no security issues
5. Ensure code is formatted correctly

---

## Support and Resources

### Documentation
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Codecov Documentation](https://docs.codecov.com/)
- [Solhint Rules](https://github.com/protofire/solhint/blob/master/docs/rules.md)
- [Prettier Docs](https://prettier.io/docs/en/)

### Tools
- [Hardhat](https://hardhat.org/)
- [Solhint](https://github.com/protofire/solhint)
- [Prettier](https://prettier.io/)
- [Codecov](https://codecov.io/)

---

**Last Updated:** January 2025
**Pipeline Version:** 1.0.0
**Maintained By:** Development Team

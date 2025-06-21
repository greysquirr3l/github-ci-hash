# GitHub CI Hash Updater

[![Go Report Card](https://goreportcard.com/badge/github.com/greysquirr3l/github-ci-hash)](https://goreportcard.com/report/github.com/greysquirr3l/github-ci-hash)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive Go tool for managing GitHub Actions in your CI/CD workflows. This tool automatically checks for updates, resolves the latest stable releases, fetches commit SHAs, and updates your workflow files with proper SHA pinning for enhanced security.

## Features

- 🔍 **Check for Updates**: Scan all workflow files and identify actions with available updates
- 🔄 **Update with Confirmation**: Update actions to latest versions with user confirmation
- 🔒 **SHA Verification**: Verify all actions are properly pinned to commit SHAs
- 🎯 **Selective Updates**: Update all workflows or target specific workflow files
- 📊 **Detailed Reports**: Comprehensive summaries of action status and available updates
- 🛡️ **Security Focused**: Follows OSSF security best practices with SHA pinning

## Installation

### From Source

```bash
go install github.com/greysquirr3l/github-ci-hash@latest
```

### Build Locally

```bash
git clone https://github.com/greysquirr3l/github-ci-hash.git
cd github-ci-hash
go build -o github-ci-hash .
```

### Using Makefile

```bash
# Build the tool
make build

# Check for action updates
make ci-hash-check

# Update actions with confirmation prompts
make ci-hash-update

# Verify all actions are pinned to SHAs
make ci-hash-verify
```

## Usage

```bash
# Check for updates without applying
github-ci-hash check

# Update all workflows (with confirmation)
github-ci-hash update

# Update specific workflow file
github-ci-hash update ci.yml

# Verify all actions are pinned to SHAs
github-ci-hash verify
```

## Authentication

For higher API rate limits, set a GitHub token:

```bash
export GITHUB_TOKEN="your_github_token"
# or
export GH_TOKEN="your_github_token"
```

Without authentication, you'll hit GitHub's rate limits faster but the tool will still work for smaller projects.

## Dependency Graph Integration

The tool can leverage GitHub's dependency graph APIs when authenticated:

1. **Automated Detection**: Automatically discovers all GitHub Actions in your workflows
2. **Latest Release Fetching**: Uses GitHub API to get the latest stable releases
3. **SHA Resolution**: Resolves tags and branches to commit SHAs
4. **Special Handling**: Proper handling for complex actions like CodeQL bundles

## Security Benefits

- **SHA Pinning**: Ensures all actions are pinned to specific commit SHAs
- **Supply Chain Security**: Prevents attacks via compromised action tags
- **OSSF Compliance**: Follows OpenSSF Scorecard security recommendations
- **Verification**: Built-in verification to ensure proper pinning

## Example Output

```bash
🔍 Scanning workflow files...
Checking for action updates...

📁 .github/workflows/ci.yml:
  🔍 Checking actions/checkout... ✅ Up to date (v4.2.2)
  🔍 Checking step-security/harden-runner... 🔄 Update available: v2.12.0 → v2.12.1
  🔍 Checking actions/setup-go... ✅ Up to date (v5.5.0)

📊 Summary:
📈 Total: 15 actions
✅ Up to date: 13
🔄 Need updates: 2
```

## Integration Options

### Pre-commit Hook

Add to `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: local
    hooks:
      - id: github-ci-hash-check
        name: Check GitHub Actions are up to date
        entry: make ci-hash-verify
        language: system
        pass_filenames: false
```

### GitHub Workflow

Create `.github/workflows/action-updates.yml`:

```yaml
name: Check Action Updates
on:
  schedule:
    - cron: '0 0 * * 1' # Weekly on Monday
  workflow_dispatch:

jobs:
  check-updates:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.24'
      - name: Check for action updates
        run: make ci-hash-check
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Advanced Features

### Special Action Handling

- **CodeQL Actions**: Automatically handles CodeQL bundle versioning
- **Sub-actions**: Properly resolves SHAs for sub-actions like `github/codeql-action/upload-sarif`
- **Version Normalization**: Handles different version formats consistently

### Error Handling

- **Retry Logic**: Built-in retry with exponential backoff for API calls
- **Graceful Degradation**: Works with or without authentication
- **Detailed Error Messages**: Clear error reporting for troubleshooting

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

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
- 🔧 **Pre-commit Hooks**: Install Git hooks for automated linting, testing, and SHA verification
- 🟢 **Smart Authentication**: Multiple token sources with visual status indicators
- 💾 **Atomic Updates**: Backup and rollback capabilities for safe workflow updates
- 🎨 **Rich Output**: Colored terminal output with emojis and progress indicators

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

# Install pre-commit hooks for automated checks
github-ci-hash install-hooks

# Show version information
github-ci-hash version
```

## Authentication

The tool supports multiple authentication methods with visual status indicators:

```bash
# Set GitHub token via environment variables
export GITHUB_TOKEN="your_github_token"
# or
export GH_TOKEN="your_github_token"

# Or authenticate with GitHub CLI
gh auth login
```

**Status Indicators:**

- 🟢 **Authenticated**: Higher rate limits, full functionality
- 🟡 **Unauthenticated**: Basic functionality, lower rate limits

The tool will automatically detect and use available authentication methods, displaying the current status with colored indicators.

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
� GitHub API: Authenticated via GITHUB_TOKEN (higher rate limits available)
�🔍 Scanning workflow files...
Checking for action updates...

📁 .github/workflows/ci.yml:
  🔍 Checking actions/checkout... ✅ Up to date (v4.2.2)
  🔍 Checking step-security/harden-runner... 🔄 Update available: v2.12.0 → v2.12.1
  🔍 Checking actions/setup-go... ✅ Up to date (v5.5.0)

📁 .github/workflows/release.yml:
  � Checking actions/checkout... ✅ Up to date (v4.2.2)
  🔍 Checking golangci/golangci-lint-action... 🔄 Update available: v8.0.0 → v8.1.0

�📊 Summary:

� .github/workflows/ci.yml:
  actions/checkout: ✅ Up to date (v4.2.2)
  step-security/harden-runner: 🔄 Update available (v2.12.1)
  actions/setup-go: ✅ Up to date (v5.5.0)

📁 .github/workflows/release.yml:
  actions/checkout: ✅ Up to date (v4.2.2)
  golangci/golangci-lint-action: 🔄 Update available (v8.1.0)

�📈 Total: 23 actions
✅ Up to date: 7
🔄 Need updates: 16
```

## Integration Options

### Pre-commit Hooks

Install automated Git hooks for your repository:

```bash
# Install hooks that run on commit and push
github-ci-hash install-hooks
```

This installs:

- **Pre-commit hook**: Runs linting, tests, and SHA verification
- **Pre-push hook**: Checks for GitHub Action updates

The hooks ensure code quality and security compliance automatically.

### Pre-commit Framework

Add to `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: local
    hooks:
      - id: github-ci-hash-verify
        name: Verify GitHub Actions are pinned to SHAs
        entry: github-ci-hash verify
        language: system
        pass_filenames: false
      - id: github-ci-hash-check
        name: Check GitHub Actions are up to date
        entry: github-ci-hash check
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
      - uses: actions/checkout@4afd733a84b1f43292c63897423277bb7f4313a9 # v4.2.2
      - uses: actions/setup-go@41dfa10bad2bb2ae585af6ee5bb4d7d973ad74ed # v5.5.0
        with:
          go-version: '1.24'
      - name: Check for action updates
        run: go run . check
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Makefile Integration

The project includes Makefile targets for easy integration:

```bash
# Check for updates
make ci-hash-check

# Update actions
make ci-hash-update

# Verify SHA pinning
make ci-hash-verify

# Install pre-commit hooks
make install-hooks
```

## Advanced Features

### Smart Authentication

- **Multiple token sources**: GITHUB_TOKEN, GH_TOKEN, or gh CLI integration
- **Visual status indicators**: 🟢 Authenticated / 🟡 Unauthenticated
- **Automatic fallback**: Graceful degradation when authentication is unavailable

### Atomic Updates

- **Backup creation**: Automatic backup before making changes
- **Rollback on failure**: Restore from backup if updates fail
- **Idempotent operations**: Safe to run multiple times without side effects

### Special Action Handling

- **CodeQL Actions**: Automatically handles CodeQL bundle versioning
- **Sub-actions**: Properly resolves SHAs for sub-actions like `github/codeql-action/upload-sarif`
- **Version Normalization**: Handles different version formats consistently

### Developer Experience

- **Rich terminal output**: Colored text, emojis, and progress indicators
- **Detailed error messages**: Clear error reporting for troubleshooting
- **Interactive confirmations**: Safe updates with user confirmation prompts
- **Pre-commit hooks**: Automated quality and security checks

### Error Handling

- **Retry Logic**: Built-in retry with exponential backoff for API calls
- **Graceful Degradation**: Works with or without authentication
- **Comprehensive Logging**: Detailed output for debugging and monitoring

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

.PHONY: build clean test lint install check update verify help version tag release pre-release bump-patch bump-minor bump-major status

# Build variables
BINARY_NAME=github-ci-hash
BUILD_DIR=build
GO_MODULE=github.com/greysquirr3l/github-ci-hash

# Version management
VERSION_FILE=VERSION
VERSION=$(shell cat $(VERSION_FILE) 2>/dev/null || echo "0.1.0")
GIT_COMMIT=$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
LDFLAGS=-ldflags "-X main.Version=$(VERSION) -X main.GitCommit=$(GIT_COMMIT) -X main.BuildTime=$(BUILD_TIME) -w -s"

# Git status check
GIT_STATUS=$(shell git status --porcelain)
GIT_BRANCH=$(shell git symbolic-ref --short HEAD 2>/dev/null || echo "unknown")

# Default target
all: build

# Build the binary
build:
	@echo "Building $(BINARY_NAME) v$(VERSION)..."
	@mkdir -p $(BUILD_DIR)
	go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) .

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	go clean

# Run tests
test:
	@echo "Running tests..."
	go test -v ./...

# Run tests with coverage
test-coverage:
	@echo "Running tests with coverage..."
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

# Lint the code
lint:
	@echo "Running linter..."
	golangci-lint run

# Install dependencies
install:
	@echo "Installing dependencies..."
	go mod tidy
	go mod download

# Install the binary globally
install-binary: build
	@echo "Installing $(BINARY_NAME) globally..."
	go install .

# Format code
fmt:
	@echo "Formatting code..."
	go fmt ./...

# Run security checks
security:
	@echo "Running security checks..."
	gosec ./...

# Check for action updates (using the built tool)
ci-hash-check: build
	@echo "Checking for GitHub Action updates..."
	./$(BUILD_DIR)/$(BINARY_NAME) check

# Update GitHub Actions (using the built tool)
ci-hash-update: build
	@echo "Updating GitHub Actions..."
	./$(BUILD_DIR)/$(BINARY_NAME) update

# Verify GitHub Actions are pinned to SHAs (using the built tool)
ci-hash-verify: build
	@echo "Verifying GitHub Actions are pinned to SHAs..."
	./$(BUILD_DIR)/$(BINARY_NAME) verify

# Development setup
dev-setup:
	@echo "Setting up development environment..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest

# Run all checks
check: lint test security

# Release build (with optimizations)
release: clean
	@echo "Building release binaries v$(VERSION)..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 .
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-amd64 .
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-arm64 .
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-windows-amd64.exe .

# ============================================================================
# ENHANCED VERSION MANAGEMENT
# ============================================================================

# Show current version information
version: build
	@echo "=== Version Information ==="
	@./$(BUILD_DIR)/$(BINARY_NAME) version 2>/dev/null || echo "Binary not available"
	@echo ""
	@echo "Current Version: $(VERSION)"
	@echo "Git Commit: $(GIT_COMMIT)"
	@echo "Git Branch: $(GIT_BRANCH)"
	@echo "Build Time: $(BUILD_TIME)"

# Show git and version status
status:
	@echo "=== Project Status ==="
	@echo "Version: $(VERSION)"
	@echo "Git Branch: $(GIT_BRANCH)"
	@echo "Git Commit: $(GIT_COMMIT)"
	@echo ""
	@if [ -n "$(GIT_STATUS)" ]; then \
		echo "❌ Working directory has uncommitted changes:"; \
		git status --short; \
	else \
		echo "✅ Working directory is clean"; \
	fi
	@echo ""
	@echo "Recent commits:"
	@git log --oneline -5 2>/dev/null || echo "No git history available"

# Bump patch version (0.1.0 -> 0.1.1)
bump-patch:
	@echo "Bumping patch version..."
	@$(eval CURRENT_VERSION := $(shell cat $(VERSION_FILE)))
	@$(eval NEW_VERSION := $(shell echo $(CURRENT_VERSION) | awk -F. '{$$3++; print $$1"."$$2"."$$3}'))
	@echo $(NEW_VERSION) > $(VERSION_FILE)
	@echo "Version bumped: $(CURRENT_VERSION) -> $(NEW_VERSION)"

# Bump minor version (0.1.0 -> 0.2.0)
bump-minor:
	@echo "Bumping minor version..."
	@$(eval CURRENT_VERSION := $(shell cat $(VERSION_FILE)))
	@$(eval NEW_VERSION := $(shell echo $(CURRENT_VERSION) | awk -F. '{$$2++; $$3=0; print $$1"."$$2"."$$3}'))
	@echo $(NEW_VERSION) > $(VERSION_FILE)
	@echo "Version bumped: $(CURRENT_VERSION) -> $(NEW_VERSION)"

# Bump major version (0.1.0 -> 1.0.0)
bump-major:
	@echo "Bumping major version..."
	@$(eval CURRENT_VERSION := $(shell cat $(VERSION_FILE)))
	@$(eval NEW_VERSION := $(shell echo $(CURRENT_VERSION) | awk -F. '{$$1++; $$2=0; $$3=0; print $$1"."$$2"."$$3}'))
	@echo $(NEW_VERSION) > $(VERSION_FILE)
	@echo "Version bumped: $(CURRENT_VERSION) -> $(NEW_VERSION)"

# Set specific version
version-set:
	@if [ -z "$(V)" ]; then \
		echo "❌ Error: Please specify version with V=x.y.z"; \
		echo "Example: make version-set V=1.2.3"; \
		exit 1; \
	fi
	@echo "Setting version to $(V)..."
	@echo $(V) > $(VERSION_FILE)
	@echo "Version set to: $(V)"

# ============================================================================
# RELEASE MANAGEMENT
# ============================================================================

# Check if git working directory is clean
git-status:
	@if [ -n "$(GIT_STATUS)" ]; then \
		echo "❌ Error: Working directory has uncommitted changes:"; \
		git status --short; \
		echo ""; \
		echo "Please commit or stash changes before releasing."; \
		exit 1; \
	else \
		echo "✅ Working directory is clean"; \
	fi

# Create and commit git tag for current version
tag-version: git-status
	@echo "Creating git tag for v$(VERSION)..."
	@if git tag -l | grep -q "^v$(VERSION)$$"; then \
		echo "❌ Error: Tag v$(VERSION) already exists"; \
		exit 1; \
	fi
	@git add $(VERSION_FILE)
	@git commit -m "Release v$(VERSION)" || echo "No changes to commit"
	@git tag -a v$(VERSION) -m "Release v$(VERSION)"
	@echo "✅ Created tag v$(VERSION)"

# Push git tag to origin
push-tag:
	@echo "Pushing tag v$(VERSION) to origin..."
	@git push origin v$(VERSION)
	@git push origin $(GIT_BRANCH)
	@echo "✅ Tag v$(VERSION) pushed to origin"

# Show release preparation steps
prepare-release:
	@echo "=== Release Preparation Checklist ==="
	@echo ""
	@echo "Current version: $(VERSION)"
	@echo "Git branch: $(GIT_BRANCH)"
	@echo ""
	@echo "Steps to release:"
	@echo "1. Run tests: make check"
	@echo "2. Update version: make bump-patch (or bump-minor/bump-major)"
	@echo "3. Commit and tag: make tag-version"
	@echo "4. Push tag: make push-tag"
	@echo ""
	@echo "Or use shortcuts:"
	@echo "- make release-patch  # for patch releases"
	@echo "- make release-minor  # for minor releases"
	@echo "- make release-major  # for major releases"

# Complete tag and push workflow
tag-release: tag-version push-tag
	@echo ""
	@echo "🚀 Release v$(VERSION) completed!"
	@echo ""
	@echo "Next steps:"
	@echo "- GitHub Actions will automatically create release binaries"
	@echo "- Check the release at: https://github.com/greysquirr3l/github-ci-hash/releases"

# Release patch version (bump + tag + push)
release-patch: check bump-patch tag-release
	@echo "🎉 Patch release v$(VERSION) completed!"

# Release minor version (bump + tag + push)
release-minor: check bump-minor tag-release
	@echo "🎉 Minor release v$(VERSION) completed!"

# Release major version (bump + tag + push)
release-major: check bump-major tag-release
	@echo "🎉 Major release v$(VERSION) completed!"

# ============================================================================
# CHANGELOG MANAGEMENT
# ============================================================================

# Generate changelog (requires git history)
changelog:
	@echo "# Changelog" > CHANGELOG.md
	@echo "" >> CHANGELOG.md
	@echo "All notable changes to this project will be documented in this file." >> CHANGELOG.md
	@echo "" >> CHANGELOG.md
	@git tag -l --sort=-version:refname | head -20 | while read tag; do \
		if [ -n "$$tag" ]; then \
			echo "## [$$tag] - $$(git log -1 --format=%ai $$tag | cut -d' ' -f1)" >> CHANGELOG.md; \
			echo "" >> CHANGELOG.md; \
			git log --format="- %s" $$(git describe --tags --abbrev=0 $$tag^)..$$tag 2>/dev/null >> CHANGELOG.md || \
			git log --format="- %s" $$tag 2>/dev/null | head -10 >> CHANGELOG.md; \
			echo "" >> CHANGELOG.md; \
		fi; \
	done
	@echo "✅ CHANGELOG.md generated"

# Show what will be included in next release
next-release:
	@echo "=== Changes since last release ==="
	@$(eval LAST_TAG := $(shell git describe --tags --abbrev=0 2>/dev/null || echo ""))
	@if [ -n "$(LAST_TAG)" ]; then \
		echo "Since $(LAST_TAG):"; \
		echo ""; \
		git log --format="- %s (%h)" $(LAST_TAG)..HEAD; \
	else \
		echo "No previous releases found"; \
		echo "All commits:"; \
		git log --format="- %s (%h)" --max-count=10; \
	fi

# Help
help:
	@echo "Available targets:"
	@echo ""
	@echo "Build targets:"
	@echo "  build         - Build the binary with version info"
	@echo "  clean         - Clean build artifacts"
	@echo "  release       - Build release binaries for multiple platforms"
	@echo ""
	@echo "Development targets:"
	@echo "  test          - Run tests"
	@echo "  test-coverage - Run tests with coverage report"
	@echo "  lint          - Run linter"
	@echo "  fmt           - Format code"
	@echo "  security      - Run security checks"
	@echo "  check         - Run all checks (lint, test, security)"
	@echo "  dev-setup     - Set up development environment"
	@echo ""
	@echo "Versioning targets:"
	@echo "  version       - Show current version info"
	@echo "  version-patch - Bump patch version (x.y.Z)"
	@echo "  version-minor - Bump minor version (x.Y.0)"
	@echo "  version-major - Bump major version (X.0.0)"
	@echo "  version-set V=x.y.z - Set specific version"
	@echo ""
	@echo "Release targets:"
	@echo "  git-status    - Check if git working directory is clean"
	@echo "  tag-version   - Create and commit git tag for current version"
	@echo "  push-tag      - Push git tag to origin"
	@echo "  prepare-release - Show release preparation steps"
	@echo "  tag-release   - Complete tag and push workflow"
	@echo "  release-patch - Bump patch version and release"
	@echo "  release-minor - Bump minor version and release"
	@echo "  release-major - Bump major version and release"
	@echo ""
	@echo "Tool targets:"
	@echo "  install       - Install dependencies"
	@echo "  install-binary- Install binary globally"
	@echo "  ci-hash-check - Check for GitHub Action updates"
	@echo "  ci-hash-update- Update GitHub Actions"
	@echo "  ci-hash-verify- Verify GitHub Actions are pinned to SHAs"
	@echo ""
	@echo "Examples:"
	@echo "  make version-patch    # Bump from 0.1.0 to 0.1.1"
	@echo "  make release-minor    # Bump to 0.2.0 and create release"
	@echo "  make version-set V=1.0.0  # Set version to 1.0.0"

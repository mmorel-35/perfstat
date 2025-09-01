# perfstat CI/CD Implementation Summary

## Overview

This document summarizes the complete GitHub Actions CI/CD implementation for the perfstat project, a Go library providing bindings to IBM AIX's libperfstat library.

## Challenge Analysis

The perfstat project presented unique CI/CD challenges:

1. **AIX-specific architecture**: Library only works on IBM AIX systems with ppc64 architecture
2. **CGO dependency**: Requires CGO compilation with libperfstat library linking
3. **Cross-platform development**: Developers need to work on non-AIX systems
4. **Build constraints**: Extensive use of `//go:build aix` tags for platform-specific code
5. **C integration**: Contains C source files (`c_helpers.c`, `c_helpers.h`) requiring compilation

## Solution Architecture

### Two-Tier CI/CD Strategy

#### Tier 1: Universal CI Pipeline (`.github/workflows/ci.yml`)
Runs on GitHub-hosted runners for broad compatibility:

- **Multi-platform validation**: Linux, macOS, Windows
- **Go version matrix**: 1.19, 1.20, 1.21
- **Non-AIX builds**: Uses `!aix` build tags for cross-platform development
- **Code quality**: Linting, security scanning, documentation validation
- **Build validation**: Ensures AIX code structure is correct without compilation

#### Tier 2: AIX-Native Pipeline (`.github/workflows/aix.yml`)
Runs on self-hosted AIX runners for full functionality:

- **Native compilation**: Full CGO builds with libperfstat
- **Runtime testing**: Actual perfstat API validation
- **Example verification**: Builds and tests all example programs
- **Conditional execution**: Triggered by `[aix]` commit messages or manual dispatch

## Key Components

### 1. Main CI Pipeline Features

**Linting Job**
```yaml
- Uses golangci-lint with custom configuration
- Excludes AIX-specific code with --build-tags=!aix
- Validates code style, imports, and basic correctness
```

**Cross-Platform Build Matrix**
```yaml
- Tests Go 1.19, 1.20, 1.21
- Validates Linux, macOS, Windows compatibility
- Uses CGO_ENABLED=0 for non-AIX targets
- Builds main package (examples excluded due to AIX dependency)
```

**AIX Simulation Job**
```yaml
- Validates build tag consistency
- Checks CGO directive format
- Verifies C header structure
- Ensures Go module cleanliness
```

### 2. AIX-Specific Pipeline Features

**Environment Validation**
```yaml
- Checks for AIX system tools (xlc compiler)
- Validates libperfstat installation
- Verifies Go AIX/ppc64 support
```

**Native Build and Test**
```yaml
- CGO_ENABLED=1 compilation
- Full example program builds
- Runtime execution validation
- Performance testing capabilities
```

### 3. Developer Tools

**Local Validation Script (`scripts/validate.sh`)**
```bash
Features:
- Pre-commit validation
- Build tag consistency checking
- CGO configuration verification
- Documentation generation
- Module dependency validation
- Color-coded output with status indicators
```

**Linting Configuration (`.golangci.yml`)**
```yaml
- AIX-aware build tag exclusions
- CGO-specific rule adjustments
- Security scanning integration
- Custom rule set for system libraries
```

### 4. Build Tag Management

**Consistent Build Tag Strategy**
- AIX-specific files: `//go:build aix` + `// +build aix`
- Cross-platform stubs: `//go:build !aix` + `// +build !aix`
- Type definitions: No build tags (universally available)

**Validation Logic**
- Files with CGO/libperfstat imports must have `aix` tags
- Files with `!aix` tags cannot use CGO
- Type definition files excluded from tag requirements

## Usage Instructions

### For Developers

**Local Development**
```bash
# Install validation tools
./scripts/validate.sh  # Will guide through setup

# Pre-commit validation
./scripts/validate.sh

# Cross-platform development
CGO_ENABLED=0 go build -tags='!aix' .
```

**AIX Development**
```bash
# Native AIX build
CGO_ENABLED=1 go build -tags=aix .

# Run tests
go test -tags=aix .

# Build examples
cd examples && go build *.go
```

### For CI/CD

**Automatic Triggers**
- Push to main/master: Runs universal CI
- Pull requests: Runs universal CI
- Commit with `[aix]`: Also runs AIX-specific CI

**Manual Triggers**
- Workflow dispatch: Can manually trigger AIX builds
- Self-hosted runner management: AIX systems need runner setup

## Technical Achievements

### 1. Cross-Platform Compatibility
- Enables development on non-AIX systems
- Maintains code quality across platforms
- Provides immediate feedback for most changes

### 2. AIX Integration
- Full native compilation and testing
- Runtime validation of perfstat functionality
- Example program verification

### 3. Developer Experience
- Local validation tools
- Clear documentation and setup guides
- Color-coded feedback and error reporting

### 4. Code Quality
- Comprehensive linting and security scanning
- Build tag consistency enforcement
- Documentation generation and validation

## Self-Hosted Runner Setup

For full AIX functionality, configure self-hosted runners:

```bash
# On AIX system
1. Install Go 1.19+ for AIX/ppc64
2. Install libperfstat development packages
3. Set up GitHub Actions runner
4. Configure with 'aix' and 'ppc64' labels
```

## Maintenance

### Adding New Features
1. Follow existing build tag patterns
2. Add appropriate CGO directives for AIX code
3. Update type definitions in `types_*.go` files
4. Run local validation before committing

### Updating Dependencies
1. Use `go mod tidy` to update dependencies
2. Validate with `./scripts/validate.sh`
3. Test on AIX systems for libperfstat compatibility

This implementation provides a robust, scalable CI/CD solution that handles the unique requirements of AIX-specific Go development while maintaining accessibility for cross-platform development teams.
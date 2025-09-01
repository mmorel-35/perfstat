# perfstat

[![CI](https://github.com/mmorel-35/perfstat/actions/workflows/ci.yml/badge.svg)](https://github.com/mmorel-35/perfstat/actions/workflows/ci.yml)
[![AIX Build](https://github.com/mmorel-35/perfstat/actions/workflows/aix.yml/badge.svg)](https://github.com/mmorel-35/perfstat/actions/workflows/aix.yml)

Go interface to IBM AIX libperfstat library for system performance statistics.

## Overview

This package provides Go bindings for IBM AIX's libperfstat library, allowing Go programs running on AIX to access detailed system performance statistics including CPU, memory, disk, network, and process information.

## Requirements

### Runtime Requirements
- IBM AIX operating system (7.1 or later recommended)
- `bos.perf.libperfstat` package installed
- Go 1.19 or later

To check if libperfstat is installed:
```bash
lslpp -L bos.perf.libperfstat
```

### Build Requirements
- CGO enabled (`CGO_ENABLED=1`)
- AIX/ppc64 target architecture
- Access to AIX system headers and libperfstat library

## Installation

```bash
go get github.com/power-devops/perfstat
```

## Usage

```go
package main

import (
    "fmt"
    "github.com/power-devops/perfstat"
)

func main() {
    // Get CPU statistics
    cpu, err := perfstat.CpuTotalStat()
    if err != nil {
        panic(err)
    }
    
    fmt.Printf("CPU Description: %s\n", cpu.Description)
    fmt.Printf("CPU MHz: %d\n", cpu.ProcessorHz)
    fmt.Printf("CPU Count: %d\n", cpu.NCpusCfg)
}
```

## Examples

See the `examples/` directory for complete working examples demonstrating various perfstat capabilities.

## Development and CI/CD

### GitHub Actions Workflows

This project includes comprehensive CI/CD pipelines:

#### Main CI Pipeline (`.github/workflows/ci.yml`)
- **Linting**: Uses golangci-lint with AIX-aware configuration
- **Cross-platform Build**: Tests compilation on multiple Go versions and platforms
- **AIX Simulation**: Validates AIX-specific build tags and CGO configuration
- **Documentation**: Generates and validates package documentation
- **Security**: Runs security scans with Gosec

#### AIX-Specific Pipeline (`.github/workflows/aix.yml`)
- **Native AIX Build**: Compiles and tests on actual AIX systems (requires self-hosted runners)
- **Full Testing**: Runs complete test suite with AIX runtime
- **Example Validation**: Builds and tests all example programs

### Build Tags and Architecture Support

The codebase uses Go build tags to handle platform-specific code:

- **AIX builds** (`//go:build aix`): Full functionality with CGO and libperfstat
- **Non-AIX builds** (`//go:build !aix`): Stub implementations for cross-platform compatibility

### Local Development

#### Building for AIX
```bash
CGO_ENABLED=1 GOOS=aix GOARCH=ppc64 go build
```

#### Testing on AIX
```bash
go test -tags=aix ./...
```

#### Cross-platform Development
```bash
# Build stubs for development on non-AIX systems
CGO_ENABLED=0 go build -tags='!aix' .
```

### Contributing

1. **Code Style**: Follow standard Go formatting (`gofmt`, `goimports`)
2. **Build Tags**: Ensure AIX-specific code uses appropriate build tags
3. **CGO**: Properly configure CGO directives for libperfstat linking
4. **Testing**: Add tests for new functionality (AIX environment required for full testing)
5. **Documentation**: Update documentation for new features

### Setting up AIX Runners

For full CI/CD functionality, configure self-hosted AIX runners:

1. Set up AIX system with Go and build tools
2. Install GitHub Actions runner
3. Configure runner with `aix` and `ppc64` labels
4. Ensure libperfstat development packages are installed

To trigger AIX-specific builds, include `[aix]` in your commit message or manually dispatch the workflow.

## License

See [LICENSE](LICENSE) file for details.

## Documentation

For detailed IBM AIX libperfstat documentation:
- [AIX Performance Tools](https://www.ibm.com/support/knowledgecenter/ssw_aix_72/performancetools/idprftools_perfstat.html)
- [libperfstat API Reference](https://www.ibm.com/support/knowledgecenter/en/ssw_aix_72/p_bostechref/perfstat.html)
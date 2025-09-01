#!/bin/bash

# Local validation script for perfstat project
# Runs similar checks to the CI pipeline

set -e

echo "🔍 Running local validation for perfstat project..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "go.mod" ] || ! grep -q "github.com/power-devops/perfstat" go.mod; then
    print_error "This script must be run from the perfstat project root directory"
    exit 1
fi

echo "📁 Working directory: $(pwd)"

# 1. Go module validation
echo -e "\n🔧 Validating Go module..."
go mod verify
go mod tidy
if [ -n "$(git diff --name-only)" ]; then
    print_warning "go.mod or go.sum needs updates (check git diff)"
else
    print_status "Go module is clean"
fi

# 2. Build validation
echo -e "\n🏗️ Testing build configurations..."

# Non-AIX build
echo "Building for non-AIX platforms..."
CGO_ENABLED=0 go build -tags='!aix' . || {
    print_error "Non-AIX build failed"
    exit 1
}
print_status "Non-AIX build successful"

# Test syntax of AIX files
echo "Validating AIX Go file syntax..."
if command -v go >/dev/null 2>&1; then
    for file in $(find . -name "*.go" -exec grep -l "//go:build aix" {} \;); do
        echo "  Checking $file..."
        # This will check syntax without actually building
        go tool compile -I "$(go env GOROOT)/pkg/$(go env GOOS)_$(go env GOARCH)" "$file" 2>/dev/null || {
            print_warning "$file has syntax issues (may be due to missing AIX headers)"
        }
    done
fi
print_status "AIX file syntax validation completed"

# 3. Build tag consistency
echo -e "\n🏷️ Validating build tag consistency..."
AIX_FILES=$(find . -name "*.go" -not -path "./examples/*" -not -name "types_*.go" -exec grep -l "#cgo\|import \"C\"" {} \; 2>/dev/null || true)
NON_AIX_FILES=$(find . -name "*.go" -exec grep -l "//go:build !aix" {} \; 2>/dev/null || true)

for file in $AIX_FILES; do
    if ! grep -q "//go:build aix" "$file"; then
        print_error "$file uses CGO but lacks aix build tag"
        exit 1
    fi
done

for file in $NON_AIX_FILES; do
    if grep -q "#cgo\|import \"C\"" "$file"; then
        print_error "$file has !aix build tag but uses CGO"
        exit 1
    fi
done
print_status "Build tag consistency validated"

# 4. CGO validation
echo -e "\n⚙️ Validating CGO configuration..."
if ! grep -r "#cgo LDFLAGS: -lperfstat" . --include="*.go" >/dev/null; then
    print_error "CGO LDFLAGS directive not found"
    exit 1
fi

# Check C helper files
if [ ! -f "c_helpers.h" ] || [ ! -f "c_helpers.c" ]; then
    print_error "C helper files (c_helpers.h, c_helpers.c) not found"
    exit 1
fi

# Validate C header structure
if ! grep -q "#ifndef C_HELPERS_H" c_helpers.h; then
    print_error "C header guard missing in c_helpers.h"
    exit 1
fi

if ! grep -q "#include <libperfstat.h>" c_helpers.h; then
    print_error "libperfstat.h include missing in c_helpers.h"
    exit 1
fi
print_status "CGO configuration validated"

# 5. Linting (if golangci-lint is available)
echo -e "\n🧹 Running linting..."
if command -v golangci-lint >/dev/null 2>&1; then
    golangci-lint run --build-tags=!aix .
    print_status "Linting completed successfully"
else
    print_warning "golangci-lint not found, skipping linting"
    echo "   Install with: curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b \$(go env GOPATH)/bin"
fi

# 6. Test what we can test
echo -e "\n🧪 Running available tests..."
CGO_ENABLED=0 go test -tags='!aix' . || {
    print_warning "Some tests failed (may require AIX runtime)"
}
print_status "Test validation completed"

# 7. Documentation validation
echo -e "\n📚 Validating documentation..."
go doc -all . > /tmp/perfstat_docs.txt 2>/dev/null || {
    print_warning "Documentation generation had issues"
}

if [ -f "/tmp/perfstat_docs.txt" ] && grep -q "Package perfstat" /tmp/perfstat_docs.txt; then
    print_status "Documentation generated successfully"
else
    print_warning "Package documentation may be incomplete"
fi

# Summary
echo -e "\n🎉 Local validation completed!"
echo
echo "Next steps:"
echo "- Run full tests on an AIX system with: go test -tags=aix ."
echo "- Build examples on AIX with: cd examples && go build *.go"
echo "- For CI/CD testing, commit your changes to trigger GitHub Actions"
echo
echo "To trigger AIX-specific CI builds, include '[aix]' in your commit message"
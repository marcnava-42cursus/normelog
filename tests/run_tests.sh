#!/usr/bin/env bash
# Test runner for normelog BATS tests

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

cd "$(dirname "$0")/.."

# Check if BATS is installed
if ! command -v bats >/dev/null 2>&1; then
  echo -e "${RED}Error: BATS is not installed${NC}"
  echo ""
  echo "To install BATS:"
  echo "  # Using package manager:"
  echo "  sudo apt-get install bats  # Debian/Ubuntu"
  echo "  brew install bats-core     # macOS"
  echo ""
  echo "  # Or from source:"
  echo "  git clone https://github.com/bats-core/bats-core.git"
  echo "  cd bats-core"
  echo "  sudo ./install.sh /usr/local"
  exit 1
fi

echo -e "${GREEN}Running normelog test suite...${NC}"
echo ""

# Run unit tests
echo -e "${YELLOW}=== Unit Tests ===${NC}"
if bats tests/unit/*.bats; then
  echo -e "${GREEN}Unit tests passed${NC}"
else
  echo -e "${RED}Unit tests failed${NC}"
  exit 1
fi

echo ""

# Run integration tests
echo -e "${YELLOW}=== Integration Tests ===${NC}"
if bats tests/integration/*.bats; then
  echo -e "${GREEN}Integration tests passed${NC}"
else
  echo -e "${RED}Integration tests failed${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}All tests passed!${NC}"

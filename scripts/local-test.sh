#!/bin/bash
#
# Local Testing Script for SDLC Metrics Demo
# Tests both C and Python applications locally before Jenkins deployment
#

set -e  # Exit on error

echo "=== SDLC Metrics Demo - Local Testing ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "Checking prerequisites..."

command -v gcc >/dev/null 2>&1 || { echo -e "${RED}Error: gcc is not installed${NC}" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo -e "${RED}Error: python3 is not installed${NC}" >&2; exit 1; }
command -v make >/dev/null 2>&1 || { echo -e "${RED}Error: make is not installed${NC}" >&2; exit 1; }

echo -e "${GREEN}[PASS] All prerequisites found${NC}"
echo ""

# Create test results directory
mkdir -p test-results

# Test C Application
echo "=== Testing C Application ==="
echo "Building C application..."
make clean
make all

echo "Running C tests..."
make test

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[PASS] C tests passed${NC}"
else
    echo -e "${RED}[FAIL] C tests failed${NC}"
    exit 1
fi
echo ""

# Test Python Application
echo "=== Testing Python Application ==="
echo "Installing Python dependencies..."
pip3 install --user -r requirements.txt --quiet

echo "Running Python tests..."
pytest tests/python/ --junitxml=test-results/pytest-results.xml --verbose

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[PASS] Python tests passed${NC}"
else
    echo -e "${RED}[FAIL] Python tests failed${NC}"
    exit 1
fi
echo ""

# Code quality checks
echo "=== Code Quality Checks ==="
echo "Running flake8..."
flake8 src/python/ --max-line-length=120 --statistics || echo -e "${YELLOW}[WARN] Flake8 warnings found${NC}"
echo ""

# Display test results summary
echo "=== Test Results Summary ==="
if [ -f test-results/c-test-results.xml ]; then
    echo -e "${GREEN}[PASS] C test results: test-results/c-test-results.xml${NC}"
fi

if [ -f test-results/pytest-results.xml ]; then
    echo -e "${GREEN}[PASS] Python test results: test-results/pytest-results.xml${NC}"
fi
echo ""

# Optional: Build Docker image
read -p "Build Docker image? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "=== Building Docker Image ==="
    docker build -t sdlc-demo-app:local .
    echo -e "${GREEN}[PASS] Docker image built: sdlc-demo-app:local${NC}"
    echo ""
    echo "To run the Docker container:"
    echo "  docker run -p 5000:5000 sdlc-demo-app:local"
fi

echo ""
echo -e "${GREEN}=== All Local Tests Completed Successfully ===${NC}"
echo "Ready for Jenkins deployment!"

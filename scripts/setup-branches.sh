#!/bin/bash
#
# Branch Setup Script for SDLC Metrics Demo
# Creates two branches: clean (starting point) and complete (fully instrumented)
#

set -e

echo "=== SDLC Metrics Demo - Branch Setup ==="
echo ""

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo "Error: Not in a git repository. Please run 'git init' first."
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: ${CURRENT_BRANCH}"
echo ""

# Confirm setup
read -p "This will create 'clean' and 'complete' branches. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "Step 1: Creating 'complete' branch with full CloudBees instrumentation..."

# Create complete branch from current state
git checkout -b complete 2>/dev/null || git checkout complete

# Ensure Jenkinsfile is the complete version
if [ -f Jenkinsfile ]; then
    echo "  - Jenkinsfile: Full CloudBees instrumentation (already present)"
else
    echo "  - Error: Jenkinsfile not found"
    exit 1
fi

git add -A
git commit -m "Complete: Full SDLC metrics instrumentation

- All CloudBees Unify integration steps
- Test result publishing (junit)
- Security scanning (Trivy, SonarQube)
- Artifact registration (registerBuildArtifactMetadata)
- Complete pipeline stages" || echo "  - No changes to commit (already up to date)"

echo "[PASS] Complete branch ready"
echo ""

echo "Step 2: Creating 'clean' branch without CloudBees instrumentation..."

# Create clean branch
git checkout -b clean 2>/dev/null || git checkout clean

# Replace Jenkinsfile with clean version
if [ -f Jenkinsfile.clean ]; then
    cp Jenkinsfile.clean Jenkinsfile
    git add Jenkinsfile
    git commit -m "Clean: Basic CI/CD pipeline without CloudBees instrumentation

- Basic build and test stages
- No CloudBees-specific steps
- TODO comments marking where to add instrumentation
- Starting point for following the adoption guide" || echo "  - Jenkinsfile already configured"
else
    echo "  - Error: Jenkinsfile.clean not found"
    exit 1
fi

echo "[PASS] Clean branch ready"
echo ""

echo "Step 3: Setting 'clean' as default branch..."
git checkout clean
echo ""

echo "=== Branch Setup Complete ==="
echo ""
echo "Available branches:"
git branch -a | grep -E "clean|complete"
echo ""
echo "Branch descriptions:"
echo "  clean    : Starting point - basic CI/CD without CloudBees instrumentation"
echo "  complete : Fully instrumented - all SDLC metrics integration"
echo ""
echo "Current branch: clean"
echo ""
echo "Next steps:"
echo "  1. Push both branches to your Git server:"
echo "       git push -u origin clean"
echo "       git push -u origin complete"
echo ""
echo "  2. Follow the adoption guide starting from the 'clean' branch"
echo "  3. Add CloudBees instrumentation step-by-step"
echo "  4. Compare with 'complete' branch when needed"
echo ""
echo "To switch branches:"
echo "  git checkout clean     # Start fresh"
echo "  git checkout complete  # View complete implementation"

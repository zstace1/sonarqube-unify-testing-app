# Repository Setup and Branch Guide

This repository uses a **two-branch approach** to support the CloudBees Professional Services adoption journey guide: "Populating SDLC Metrics with Jenkins and CI"

## Two Branches Explained

### Branch: `clean`
**Purpose:** Starting point for consultants following the adoption guide

**Contents:**
- Working C and Python applications
- Unit tests that generate JUnit XML
- Basic Jenkinsfile with NO CloudBees instrumentation
- TODO comments marking where to add each integration point
- Dockerfile, Makefile, all supporting files

**Use this branch to:**
- Follow the adoption guide step-by-step
- Add CloudBees integration incrementally
- Watch each dashboard populate as you add instrumentation
- Learn exactly what each step does

### Branch: `complete`
**Purpose:** Fully instrumented reference implementation

**Contents:**
- Same applications as `clean` branch
- Complete Jenkinsfile with ALL CloudBees instrumentation
- All SDLC metrics integration points implemented
- Working example of every dashboard population

**Use this branch to:**
- Compare your work with the complete implementation
- Troubleshoot when something doesn't work
- See the final target state
- Copy specific integration patterns

## Initial Setup

### Step 1: Clone and Initialize Repository

```bash
# Clone the repository
git clone https://github.com/YOUR_ORG/sdlc-metrics-jenkins-demo.git
cd sdlc-metrics-jenkins-demo

# Initialize git (if this is a fresh copy)
git init

# Add all files
git add .
git commit -m "Initial commit: SDLC metrics demo base"

# Run the branch setup script
./scripts/setup-branches.sh
```

The script will:
1. Create the `complete` branch with full instrumentation
2. Create the `clean` branch without CloudBees steps
3. Set `clean` as the current branch

### Step 2: Push to Your Git Server

```bash
# Add your Git remote
git remote add origin https://github.com/YOUR_ORG/sdlc-metrics-jenkins-demo.git

# Push both branches
git push -u origin clean
git push -u origin complete

# Set clean as default branch (optional, do this in GitHub/GitLab UI)
```

### Step 3: Configure Jenkins

Create two Jenkins Multibranch Pipeline jobs:

**Job 1: sdlc-metrics-demo-clean**
- Branch source: Your Git repository
- Branch discovery: Discover branches (filter: `clean`)
- Use this to follow along with the guide

**Job 2: sdlc-metrics-demo-complete** (Optional)
- Branch source: Your Git repository
- Branch discovery: Discover branches (filter: `complete`)
- Use this as a reference when troubleshooting

## Following the Adoption Guide

### Workflow Overview

1. **Start on `clean` branch** - Basic pipeline with no CloudBees integration
2. **Follow guide section-by-section** - Add one integration point at a time
3. **Commit after each section** - Save your progress incrementally
4. **Verify dashboard** - Check that each metric type populates
5. **Compare with `complete`** - If stuck, diff against complete branch

### Incremental Development Path

The adoption guide walks through adding instrumentation in this order:

#### Section 1: CI Insights (Already Working)
**What:** CloudBees Platform Insights plugin connection
**Result:** Jenkins operational metrics appear in CI Insights dashboard
**No code changes needed** - Plugin installation is sufficient

#### Section 2: Test Insights
**What to add:** `junit` step after test execution

```groovy
// In "Run C Unit Tests" stage, post section:
post {
    always {
        junit testResults: '**/test-results/c-test-results.xml', allowEmptyResults: true
    }
}

// In "Run Python Unit Tests" stage, post section:
post {
    always {
        junit testResults: '**/test-results/pytest-results.xml', allowEmptyResults: true
    }
}
```

**Verify:** Test Insights dashboard shows C and Python test suites
**Commit:** `git commit -m "Add test result publishing for Test Insights"`

#### Section 3: Security Insights - SCA with Trivy
**What to add:** New stage for Trivy filesystem scanning

```groovy
stage('SCA Security Scan - Trivy') {
    steps {
        echo "Running Trivy security scan..."
        sh '''
            # Install and run Trivy
            # ... (see complete Jenkinsfile for full implementation)
        '''
    }
    post {
        always {
            script {
                if (fileExists("${TEST_RESULTS_DIR}/trivy-fs-report.sarif")) {
                    registerSecurityScan(
                        artifacts: "${TEST_RESULTS_DIR}/trivy-fs-report.sarif",
                        format: "sarif",
                        scanner: "Trivy",
                        archive: true
                    )
                }
            }
        }
    }
}
```

**Verify:** Security Insights shows filesystem vulnerabilities
**Commit:** `git commit -m "Add Trivy SCA scanning for Security Insights"`

#### Section 4: Security Insights - SAST with SonarQube (Optional)
**What to add:** SonarQube analysis and export stage

```groovy
stage('SAST Security Scan - SonarQube') {
    // ... see complete Jenkinsfile
}
```

**Verify:** Security Insights shows code quality issues
**Commit:** `git commit -m "Add SonarQube SAST scanning"`

#### Section 5: Container Security Scanning
**What to add:** Trivy image scanning after Docker build

```groovy
stage('Scan Docker Image') {
    steps {
        sh """
            trivy image --format sarif --output trivy-image-report.sarif ${DOCKER_IMAGE}
        """
    }
    post {
        always {
            registerSecurityScan(
                artifacts: "trivy-image-report.sarif",
                format: "sarif",
                scanner: "Trivy",
                archive: true
            )
        }
    }
}
```

**Verify:** Security Insights shows container vulnerabilities
**Commit:** `git commit -m "Add Docker image security scanning"`

#### Section 6: Build Artifact Registration
**What to add:** `registerBuildArtifactMetadata` step after Docker push

```groovy
// In "Push Docker Image" stage, post success section:
post {
    success {
        script {
            env.DOCKER_DIGEST = sh(
                script: "docker inspect ${DOCKER_IMAGE} --format='{{.Id}}'",
                returnStdout: true
            ).trim()

            registerBuildArtifactMetadata(
                name: "${APP_NAME}",
                url: "${DOCKER_IMAGE}",
                version: "${APP_VERSION}",
                type: "Docker",
                digest: "${env.DOCKER_DIGEST}",
                label: "build-${BUILD_NUMBER},${env.BRANCH_NAME}"
            )
        }
    }
}
```

**Verify:**
- Software Delivery Activity shows build artifacts
- Environment Inventory shows artifact versions
- DORA metrics begin calculating (requires deployments)

**Commit:** `git commit -m "Add build artifact registration"`

### Comparing with Complete Branch

At any point, you can compare your work with the complete implementation:

```bash
# View differences in Jenkinsfile
git diff complete -- Jenkinsfile

# View specific sections
git diff complete -- Jenkinsfile | grep -A 10 "registerSecurityScan"

# Checkout complete branch temporarily
git checkout complete
# ... review the file
git checkout clean
```

## Branch Maintenance

### Syncing Clean Branch with Updates

If you update the applications or tests:

```bash
# Make changes on clean branch
git checkout clean
# ... make your changes to src/, tests/, etc.
git add src/ tests/ Makefile requirements.txt
git commit -m "Update application code"

# Merge into complete branch
git checkout complete
git merge clean
git push origin complete

# Return to clean
git checkout clean
git push origin clean
```

### Updating Complete Branch Instrumentation

If CloudBees adds new features or you want to update the instrumentation:

```bash
# Update on complete branch
git checkout complete
# ... update Jenkinsfile
git add Jenkinsfile
git commit -m "Update CloudBees instrumentation"
git push origin complete

# Clean branch remains unchanged (no CloudBees steps)
```

## Jenkins Pipeline Configuration Per Branch

### Clean Branch Pipeline

**Expected behavior:**
- All stages execute successfully
- Tests run and results are archived
- Docker image builds and pushes
- **NO data appears in CloudBees Unify dashboards** (except CI Insights from plugin)

### Complete Branch Pipeline

**Expected behavior:**
- All stages execute successfully
- All SDLC metrics populate in CloudBees Unify:
  - CI Insights: Jenkins operational data
  - Test Insights: C and Python test results
  - Security Insights: Trivy and SonarQube findings
  - Software Delivery Activity: Builds, deployments, commits
  - DORA Metrics: Deployment frequency, lead time, etc.
  - Environment Inventory: Artifact versions

## Troubleshooting

### Pipeline Fails on Clean Branch

**Common issues:**
- Missing Jenkins credentials (docker-registry-credentials)
- Docker not available on Jenkins agent
- Python dependencies not installing

**Solution:** Fix infrastructure issues first on clean branch before adding CloudBees instrumentation

### CloudBees Steps Fail After Adding

**Common issues:**
- CloudBees Platform Insights plugin not authenticated
- Wrong parameter names in CloudBees steps
- Files not generated before CloudBees steps run

**Solution:** Compare exact syntax with complete branch

### Data Not Appearing in Dashboards

**Checklist:**
1. Verify CloudBees Platform Insights plugin is connected: Manage Jenkins > System > CloudBees Platform Insights > Test Connection
2. Check Console Output for CloudBees step execution
3. Wait 10-15 minutes for data ingestion
4. Verify files exist before CloudBees steps: Add `ls -la test-results/` before junit step
5. Compare with complete branch to ensure syntax matches

## Quick Reference

### Switch Branches

```bash
# Work on clean (following guide)
git checkout clean

# View complete (reference)
git checkout complete
```

### View Jenkinsfile Differences

```bash
git diff clean complete -- Jenkinsfile
```

### Reset Clean Branch (Start Over)

```bash
git checkout clean
git reset --hard origin/clean
```

### Create Feature Branch from Clean

```bash
git checkout clean
git checkout -b feature/my-instrumentation
# ... add CloudBees steps following guide
git commit -m "Add Test Insights instrumentation"
```

## Support

For questions about using this repository structure:
- See the main adoption guide: "Populating SDLC Metrics with Jenkins and CI"
- Compare your changes with the complete branch
- Review the README.md for application-specific details
- Check TROUBLESHOOTING.md for common issues

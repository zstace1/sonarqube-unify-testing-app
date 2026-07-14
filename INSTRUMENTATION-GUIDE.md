# CloudBees Instrumentation Cheat Sheet

**Quick reference for adding CloudBees integration points to the `clean` branch while following the adoption guide.**

This document provides copy-paste code snippets for each section of the adoption journey guide. Start with the `clean` branch, which has TODO comments marking where each snippet goes.

## Prerequisites

Before adding any instrumentation:
1. CloudBees Platform Insights plugin installed and authenticated in Jenkins
2. Jenkins credentials configured (docker-registry-url, docker-registry-credentials, sonarqube credentials)
3. CloudBees Unify environments created (Development, Production)

## Integration Points by Dashboard

The sections below follow the recommended implementation order from the adoption journey guide.

### 1. Build Artifacts & Environment Inventory

**When:** After building and packaging the application artifact
**Where:** In the `post` section of "Build and Package Application" stage
**What:** Register artifact metadata with CloudBees

Find: `// TODO: Uncomment the post block below to register the artifact with CloudBees Unify`

Uncomment the post block (remove the `//` comment markers):
```groovy
post {
    success {
        script {
            // Calculate artifact checksum for registration
            def artifactDigest = sh(
                script: "sha256sum ${APP_NAME}-${APP_VERSION}.tar.gz | awk '{print \$1}'",
                returnStdout: true
            ).trim()

            // Register build artifact with CloudBees Unify
            // IMPORTANT: Capture the return value to get artifact ID for deployment tracking
            def buildArtifactId = registerBuildArtifactMetadata(
                name: "${APP_NAME}",
                url: "${BUILD_URL}artifact/${APP_NAME}-${APP_VERSION}.tar.gz",
                version: "${APP_VERSION}",
                type: "Binary",
                digest: artifactDigest,
                label: "build-${BUILD_NUMBER},${BRANCH_NAME}"
            )

            // Store artifact ID for deployment stage
            env.ARTIFACT_ID = buildArtifactId
            echo "Build artifact registered with CloudBees Unify"
            echo "Artifact ID: ${env.ARTIFACT_ID}"
        }
    }
}
```

**Verify:**
- Navigate to Analytics > Software delivery activity
- Should see builds in "Code progression snapshot"
- Navigate to component > Environment inventory tab
- Should see artifact versions (without environment assignments until step 2)

---

### 2. DORA Metrics & Deployment Tracking

**When:** After successful deployment
**Where:** In the `post > success` section of "Deploy to Production" stage
**What:** Register deployed artifact to associate with target environment

Find: `// TODO: Uncomment the post block below to register deployment for DORA metrics`

Uncomment the post block (remove the `//` comment markers):
```groovy
post {
    success {
        script {
            echo "Deployment to Production completed successfully"

            // Register deployed artifact with CloudBees Unify
            // This uses the artifact ID captured from registerBuildArtifactMetadata in step 1
            registerDeployedArtifactMetadata(
                artifactId: env.ARTIFACT_ID,
                targetEnvironment: "Production",
                labels: "deployed,deployment-${BUILD_NUMBER}"
            )

            echo "Deployment registered with CloudBees Unify for DORA metrics tracking"
            echo "Environment: Production"
            echo "Artifact ID: ${env.ARTIFACT_ID}"
        }
    }
    failure {
        echo "Deployment to Production failed"
    }
}
```

**Key Points:**
- Use `registerDeployedArtifactMetadata` step (available in CloudBees Platform Integration Plugin :: Controllers)
- Pass the `artifactId` captured from `registerBuildArtifactMetadata` in step 1
- Specify `targetEnvironment` to associate with configured CloudBees environments (must match environment names created in Chapter 2)
- Only register in `success` block - failed deployments should not be registered
- This is the Jenkins equivalent of the `cloudbees-io/register-deployed-artifact@v2` action

**Verify:**
- Navigate to Analytics > Software delivery activity
- Check "Successful deployments" count in Code progression snapshot
- Navigate to Analytics > DORA metrics
- Select environment (Production)
- Should see deployment frequency after several builds
- Lead time, change failure rate, MTTR populate over time
- Navigate to component > Environment inventory tab
- Should see artifact versions assigned to Production environment

---

### 3. Security Insights - SCA (Trivy Filesystem)

**When:** After code quality checks, before package application
**Where:** In the commented-out `stage('SCA Security Scan - Trivy')` section
**What:** Uncomment Trivy filesystem scanning stage

**Note:** This uses a dedicated Trivy container in the Kubernetes pod (already configured in the agent section).

Find: `// TODO: Uncomment the stage below to add SCA Security Scan (Trivy filesystem)`

Uncomment the stage block (remove the `//` comment markers):
```groovy
stage('SCA Security Scan - Trivy') {
    steps {
        container('trivy') {
            echo "Running Trivy security scan..."
            sh '''
                # Run filesystem scan
                echo "=== Trivy Filesystem Scan ==="
                trivy fs --format sarif --output trivy-fs-report.sarif . --exit-code 0

                # Display scan summary
                trivy fs --severity HIGH,CRITICAL . --exit-code 0
            '''
        }
    }
    post {
        always {
            script {
                if (fileExists("trivy-fs-report.sarif")) {
                    registerSecurityScan(
                        artifacts: "trivy-fs-report.sarif",
                        format: "sarif",
                        scanner: "Trivy",
                        archive: true
                    )
                    echo "SCA scan results registered with CloudBees Unify"
                }
            }
        }
    }
}
```

**Verify:**
- Navigate to Analytics > Security insights
- Should see "Workflows with scanners" count increase
- Should see vulnerabilities by scan type (SCA)

---

### 4. Security Insights - SAST (SonarQube) [Optional]

**When:** After code quality checks
**Where:** In the commented-out `stage('SAST Security Scan - SonarQube')` section
**What:** Uncomment SonarQube SAST scanning stage

**Note:** Requires SonarQube server and credentials configured

Find: `// TODO: Uncomment the stage below to add SAST Security Scan (SonarQube)`

Uncomment the stage block (remove the `//` comment markers):
```groovy
stage('SAST Security Scan - SonarQube') {
    when {
        expression { return fileExists('sonar-project.properties') }
    }
    steps {
        container('sonarqube') {
            echo "Running SonarQube SAST scan..."
            script {
                sh '''
                    sonar-scanner \
                        -Dsonar.projectKey=${APP_NAME} \
                        -Dsonar.sources=src \
                        -Dsonar.host.url=${SONAR_HOST} \
                        -Dsonar.login=${SONAR_TOKEN}
                '''
            }
        }
    }
    post {
        always {
            script {
                exportSonarQubeScan(
                    component: "",
                    project: "${APP_NAME}",
                    host: "${SONAR_HOST}",
                    credentialId: "sonarqube-token"
                )
            }
        }
    }
}
```

**Note:** This uses a dedicated `sonarqube` container (pre-configured in the pod with the `sonarsource/sonar-scanner-cli` image).

**Environment Variables Needed:**
```groovy
// Add to environment section at top of Jenkinsfile
SONAR_HOST = credentials('sonarqube-url')
SONAR_TOKEN = credentials('sonarqube-token')
```

**Verify:**
- Security Insights shows SAST scan results
- Code quality issues appear in vulnerabilities list

---

### 5. Test Insights

**When:** After test execution stages
**Where:** In the `post` section of test stages
**What:** Publish JUnit XML test results

#### C Unit Tests

Find: `// TODO: Uncomment the post block below to publish test results to CloudBees Unify`

Uncomment the post block (remove the `//` comment markers):
```groovy
post {
    always {
        junit testResults: 'test-results/c-test-results.xml', allowEmptyResults: true
    }
}
```

#### Python Unit Tests

Find: `// TODO: Uncomment the post block below to publish test results to CloudBees Unify`

Uncomment the post block (remove the `//` comment markers):
```groovy
post {
    always {
        junit testResults: 'test-results/pytest-results.xml', allowEmptyResults: true
    }
}
```

**Verify:**
- Navigate to Analytics > Test insights
- Should see test suites from both C and Python
- Click on suite to see individual test cases

---

## Adding All Integration Points at Once

If you want to add all CloudBees instrumentation in one commit:

```bash
# Start from main branch
git checkout main

# Copy the complete Jenkinsfile
git checkout complete -- Jenkinsfile

# Commit all instrumentation
git commit -m "Add complete CloudBees SDLC metrics instrumentation

Implementation order (matching adoption journey guide):
- Build artifact registration (registerBuildArtifactMetadata)
- Deployment tracking (registerDeployedArtifactMetadata)
- Security scanning (Trivy SCA, SonarQube SAST)
- Test result publishing (junit)

This enables Environment Inventory, DORA metrics, Security Insights, and Test Insights.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# Push to your branch
git push
```

## Verification Checklist

After adding all instrumentation, verify each dashboard in the recommended order:

- [ ] **CI Insights** - Jenkins controller appears, shows system info
- [ ] **Environment Inventory** - Artifact versions listed, deployments tracked per environment
- [ ] **Software Delivery Activity** - Builds, commits, and deployments tracked in code progression
- [ ] **DORA Metrics** - Deployment frequency calculating (requires multiple builds over time)
- [ ] **Security Insights** - Trivy SCA and SonarQube SAST scans appear
- [ ] **Test Insights** - C and Python test suites visible with execution history

## Troubleshooting

### registerBuildArtifactMetadata not recognized

**Cause:** CloudBees Platform Insights plugin not installed
**Fix:** Install plugin in Jenkins, restart, re-authenticate

### junit step not recognized

**Cause:** JUnit plugin not installed
**Fix:** Install JUnit plugin from Jenkins plugin manager

### registerSecurityScan not recognized

**Cause:** CloudBees Platform Insights plugin not installed
**Fix:** Same as registerBuildArtifactMetadata above

### Data not appearing in dashboards

**Cause:** Multiple possible reasons
**Fix:**
1. Wait 10-15 minutes for data ingestion
2. Check Console Output for errors in CloudBees steps
3. Verify CloudBees Platform Insights plugin authentication
4. Ensure files exist before CloudBees steps run (add ls commands)

### Trivy installation fails

**Cause:** Network issues or permissions
**Fix:**
- Manually install Trivy on Jenkins agent
- Or use Docker image with Trivy pre-installed

## Next Steps

After successfully instrumenting the pipeline:

1. **Run multiple builds** - DORA metrics require data over time (minimum 5-10 builds recommended)
2. **Test different branches** - Create feature branches to verify Development environment tracking
3. **Review dashboards** - Navigate through each dashboard following the implementation order
4. **Configure Jira integration** - Add Flow Metrics dashboard (optional)
5. **Set up quality gates** - Use Security Insights to enforce vulnerability policies
6. **Customize views** - Create custom dashboard filters for your team

## Implementation Order Reference

Follow the adoption journey guide chapters in this order:

1. **Chapter 5**: Register Build Artifacts → Enables Environment Inventory
2. **Chapter 6**: Register Deployments → Enables DORA Metrics
3. **Chapter 7**: Add SCA Security Scanning → Enables Security Insights (SCA)
4. **Chapter 8**: Add SAST Security Scanning (optional) → Enhances Security Insights
5. **Chapter 9**: Publish Test Results → Enables Test Insights
6. **Chapter 10**: View all analytics dashboards

## Support

- **Complete implementation:** See `Jenkinsfile` on `complete` branch
- **Adoption guide:** Follow the step-by-step guide in PS documentation
- **Troubleshooting:** See SETUP.md and README.md in this repository

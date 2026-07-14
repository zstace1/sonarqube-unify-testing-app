# Quick Start Guide

**Get this demo running in 5 minutes!**

## Which Branch Should I Use?

**Following the adoption guide?**
- **Start with `clean` branch** - See [SETUP.md](SETUP.md) instead of this quick start
- Add CloudBees instrumentation step-by-step while following the guide

**Just want to see it work?**
- **Use `complete` branch** - Continue with this quick start
- Fully instrumented pipeline with all SDLC metrics

This quick start assumes you're using the **`complete`** branch with full instrumentation.

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] Jenkins 2.414.3+ installed and running
- [ ] CloudBees Platform Insights plugin installed in Jenkins
- [ ] CloudBees Unify account with Edition 2+
- [ ] Docker installed and running
- [ ] Git, GCC, Python 3.11+, Make installed

## Step-by-Step Setup

### 1. Clone This Repository

```bash
git clone https://github.com/YOUR_ORG/sdlc-metrics-jenkins-demo.git
cd sdlc-metrics-jenkins-demo

# Use the complete branch for this quick start
git checkout complete
```

### 2. Test Locally (Optional but Recommended)

```bash
# Run the local test script
./scripts/local-test.sh

# Or test manually:
make all && make test
pytest tests/python/ --verbose
```

### 3. Configure Jenkins Credentials

In Jenkins, navigate to **Manage Jenkins > Manage Credentials** and add:

| Credential ID | Type | Value |
|---------------|------|-------|
| `docker-registry-url` | Secret text | `docker.io/YOUR_USERNAME` |
| `docker-registry-credentials` | Username/Password | Docker Hub login |
| `sonarqube-url` | Secret text | `https://your-sonarqube.com` (optional) |
| `sonarqube-token` | Secret text | SonarQube API token (optional) |

### 4. Create Jenkins Multibranch Pipeline

1. Click **New Item**
2. Name: `sdlc-metrics-demo`
3. Type: **Multibranch Pipeline**
4. Branch Sources: Add your Git repository
5. Save

### 5. Trigger First Build

Jenkins will automatically scan and build branches. Or manually:
1. Click **Scan Repository Now**
2. Click on `main` branch
3. Wait for build to complete

### 6. Verify CloudBees Unify Dashboards

After ~10-15 minutes, check CloudBees Unify:

**CI Insights:**
```
Navigate to: Jenkins management > CI insights for Jenkins
Expected: Jenkins controller stats, run history, project activity
```

**Test Insights:**
```
Navigate to: Analytics > Test insights
Expected: C and Python test suites with results
```

**Security Insights:**
```
Navigate to: Analytics > Security insights
Expected: Trivy scan findings
```

**Software Delivery Activity:**
```
Navigate to: Analytics > Software delivery activity
Expected: Build runs, commit trends, deployment tracking
```

## Common Issues

### Build Fails on First Run

**Problem:** "Docker registry credentials not found"

**Solution:**
```bash
# Verify credentials exist in Jenkins
# Manage Jenkins > Manage Credentials
# Ensure 'docker-registry-credentials' is configured
```

**Problem:** "Trivy not found"

**Solution:**
The Jenkinsfile auto-installs Trivy. Ensure Jenkins agent has:
- Internet access
- wget installed
- Write permissions to /usr/local/bin or ~/bin

### No Data in CloudBees Dashboards

**Problem:** Dashboards empty after build

**Solution:**
1. Wait 10-15 minutes for data ingestion
2. Verify CloudBees Platform Insights plugin is authenticated:
   - Manage Jenkins > System > CloudBees Platform Insights
   - Click "Test Connection"
3. Check Jenkins logs for errors:
   - Manage Jenkins > System Log

### SonarQube Stage Skips

**Problem:** "SonarQube stage skipped"

**Solution:**
This is expected if you haven't configured SonarQube. The stage has a `when` condition:
```groovy
when {
    expression { return fileExists('sonar-project.properties') }
}
```

SonarQube is optional for this demo. Main metrics still populate without it.

## Next Steps

**After first successful build:**

1. **Explore the Jenkinsfile** - Understand each stage and CloudBees integration point
2. **Review Test Results** - Click on a build > Test Results tab
3. **Check Security Findings** - View scan results in CloudBees Security Insights
4. **Configure Flow Metrics** - Set up Jira integration (see main adoption guide)
5. **Customize for Your Org** - Update Docker registry, app name, environments

## Need Help?

- **Full Documentation:** See `README.md`
- **Adoption Guide:** CloudBees PS "Populating SDLC Metrics with Jenkins and CI"
- **Contributing:** See `CONTRIBUTING.md`

## Quick Commands Reference

```bash
# Local testing
make all              # Build C app
make test             # Run C tests
pytest tests/python/  # Run Python tests
./scripts/local-test.sh  # Run all tests

# Docker
docker build -t sdlc-demo-app:local .
docker run -p 5000:5000 sdlc-demo-app:local

# Access running app
curl http://localhost:5000/health
curl -X POST http://localhost:5000/api/calculator \
  -H "Content-Type: application/json" \
  -d '{"operation":"add","a":5,"b":3}'
```

---

**Ready to go?** Push this repository to your Git server and create the Jenkins pipeline job!

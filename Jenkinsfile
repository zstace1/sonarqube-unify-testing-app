pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: build
    image: ubuntu:24.04
    command:
    - sleep
    args:
    - 99d
  - name: sonarqube
    image: sonarsource/sonar-scanner-cli:latest
    command:
    - cat
    tty: true
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - sleep
    args:
    - 9999999
'''
        }
    }

    environment {
        // Application metadata
        APP_NAME = "sdlc-demo-app"

        // Build directories
        BUILD_DIR = "build"
        TEST_RESULTS_DIR = "test-results"
        DIST_DIR = "dist"

        // SonarQube credentials (for SAST scanning - optional)
        SONAR_HOST = credentials('sonarqube-url')
        SONAR_TOKEN = credentials('sonarqube-token')

        // Trivy version for SCA scanning
        TRIVY_VERSION = "0.72.0"
    }

    stages {
        stage('Setup Environment') {
            steps {
                container('build') {
                    echo "Installing build tools..."
                    sh '''
                        apt-get update && apt-get install -y \
                            build-essential \
                            python3 \
                            python3-pip \
                            git \
                            tar

                        # Configure git to trust the workspace directory
                        git config --global --add safe.directory ${WORKSPACE}

                        # Create necessary directories
                        mkdir -p ${BUILD_DIR}
                        mkdir -p ${TEST_RESULTS_DIR}

                        # Display tool versions
                        echo "=== Build Tool Versions ==="
                        gcc --version | head -1
                        python3 --version
                        pip3 --version
                        make --version | head -1
                    '''
                }
            }
        }

        stage('Initialize') {
            steps {
                container('build') {
                    script {
                        echo "=== SDLC Metrics Jenkins Demo Pipeline ==="
                        echo "Build Number: ${env.BUILD_NUMBER}"
                        echo "Branch: ${env.BRANCH_NAME}"

                        // Capture Git commit info
                        env.GIT_COMMIT_HASH = sh(
                            script: 'git rev-parse HEAD',
                            returnStdout: true
                        ).trim()

                        env.GIT_COMMIT_SHORT = sh(
                            script: 'git rev-parse --short HEAD',
                            returnStdout: true
                        ).trim()

                        // Generate version string
                        def commitCount = sh(
                            script: 'git rev-list --count HEAD',
                            returnStdout: true
                        ).trim()
                        env.APP_VERSION = "1.0.${commitCount}-${env.GIT_COMMIT_SHORT}"

                        echo "Git Commit: ${env.GIT_COMMIT_SHORT}"
                        echo "Version: ${env.APP_VERSION}"

                        // Display repository info
                        sh '''
                            echo "Repository: $(git config --get remote.origin.url)"
                            echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
                            echo "Last Commit: $(git log -1 --pretty=format:'%h - %s (%an)')"
                        '''
                    }
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                container('build') {
                    echo "Installing Python dependencies..."
                    sh '''
                        pip3 install --break-system-packages -r requirements.txt
                    '''
                }
            }
        }

        
        stage('Build and Package Application') {
            steps {
                container('build') {
                    echo "Building C application..."
                    sh '''
                        make clean
                        make all

                        # Verify build artifacts
                        ls -lh build/

                        echo "C application built successfully"
                    '''

                    echo "Building Python application..."
                    sh '''
                        # Compile Python files to check for syntax errors
                        python3 -m py_compile src/python/app.py

                        echo "Python application validated successfully"
                    '''

                    echo "Packaging application artifacts..."
                    sh """
                        # Create distribution directory
                        mkdir -p ${DIST_DIR}

                        # Copy C application binary
                        cp ${BUILD_DIR}/calculator ${DIST_DIR}/

                        # Copy Python application
                        mkdir -p ${DIST_DIR}/python-app
                        cp -r src/python/* ${DIST_DIR}/python-app/
                        cp requirements.txt ${DIST_DIR}/python-app/

                        # Copy documentation
                        cp README.md ${DIST_DIR}/ || echo "README.md not found, skipping"

                        # Create tarball
                        tar -czf ${APP_NAME}-${APP_VERSION}.tar.gz -C ${DIST_DIR} .

                        echo "=== Package Created ==="
                        echo "File: ${APP_NAME}-${APP_VERSION}.tar.gz"
                        ls -lh ${APP_NAME}-${APP_VERSION}.tar.gz

                        # Calculate checksum
                        sha256sum ${APP_NAME}-${APP_VERSION}.tar.gz
                    """
                    // Archive the artifact in Jenkins
                    archiveArtifacts artifacts: "${APP_NAME}-${APP_VERSION}.tar.gz", fingerprint: true
                }
            }
             post {
                 always {
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
        }

        stage('SCA Security Scan - Trivy') {
            steps {
                container('build') {
                    echo "Running Trivy dependency scan on packaged artifact..."
                    sh '''
                        if ! command -v trivy &> /dev/null; then
                            echo "Installing Trivy ${TRIVY_VERSION}..."
                            apt-get update && apt-get install -y wget
                            wget -q https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz
                            tar zxf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz
                            mv trivy /usr/local/bin/
                        fi

                        echo "=== Trivy Filesystem Scan (packaged artifact) ==="
                        trivy --version
                        trivy fs --format sarif --output trivy-fs-report.sarif ${DIST_DIR}

                        if [ ! -s trivy-fs-report.sarif ]; then
                            echo "ERROR: trivy did not produce a non-empty SARIF report"
                            exit 1
                        fi

                        RESULT_COUNT=$(grep -o "\\"ruleId\\"" trivy-fs-report.sarif | wc -l)
                        echo "SARIF result count: ${RESULT_COUNT}"

                        # Display scan summary
                        trivy fs --severity HIGH,CRITICAL ${DIST_DIR}
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
                        } else {
                            echo "No trivy-fs-report.sarif produced, skipping registration"
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                container('kaniko') {
                    echo "Building Docker image with Kaniko (no Docker daemon required)..."
                    sh '''
                        /kaniko/executor \
                            --context=dir://${WORKSPACE} \
                            --dockerfile=Dockerfile \
                            --destination=${APP_NAME}:${APP_VERSION} \
                            --no-push \
                            --tarPath=image.tar \
                            --digest-file=${WORKSPACE}/image-digest.txt

                        ls -lh image.tar
                        echo "=== Image Digest ==="
                        cat ${WORKSPACE}/image-digest.txt
                    '''
                }
                // Archive the image tarball in Jenkins so it has a downloadable URL
                archiveArtifacts artifacts: "image.tar", fingerprint: true
            }
            post {
                always {
                    script {
                        if (fileExists("image-digest.txt")) {
                            def imageDigest = readFile("image-digest.txt").trim()

                            // Register the Docker image as a build artifact with CloudBees Unify
                            def dockerArtifactId = registerBuildArtifactMetadata(
                                name: "${APP_NAME}",
                                url: "${BUILD_URL}artifact/image.tar",
                                version: "${APP_VERSION}",
                                type: "Docker",
                                digest: imageDigest,
                                label: "build-${BUILD_NUMBER},${BRANCH_NAME}"
                            )

                            env.DOCKER_ARTIFACT_ID = dockerArtifactId
                            echo "Docker image registered with CloudBees Unify"
                            echo "Docker Artifact ID: ${env.DOCKER_ARTIFACT_ID}"
                        } else {
                            echo "No image-digest.txt produced, skipping Docker artifact registration"
                        }
                    }
                }
            }
        }

        stage('Scan Docker Image - Trivy') {
            steps {
                container('build') {
                    echo "Running Trivy image scan on built Docker image..."
                    sh '''
                        if ! command -v trivy &> /dev/null; then
                            echo "Installing Trivy ${TRIVY_VERSION}..."
                            apt-get update && apt-get install -y wget
                            wget -q https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz
                            tar zxf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz
                            mv trivy /usr/local/bin/
                        fi

                        echo "=== Trivy Image Scan (image.tar built by Kaniko) ==="
                        trivy --version
                        trivy image --input image.tar --format sarif --output trivy-image-report.sarif

                        if [ ! -s trivy-image-report.sarif ]; then
                            echo "ERROR: trivy did not produce a non-empty SARIF report"
                            exit 1
                        fi

                        RESULT_COUNT=$(grep -o "\\"ruleId\\"" trivy-image-report.sarif | wc -l)
                        echo "SARIF result count: ${RESULT_COUNT}"

                        # Display scan summary
                        trivy image --input image.tar --severity HIGH,CRITICAL
                    '''
                }
            }
            post {
                always {
                    script {
                        if (fileExists("trivy-image-report.sarif")) {
                            registerSecurityScan(
                                artifacts: "trivy-image-report.sarif",
                                format: "sarif",
                                scanner: "Trivy",
                                archive: true
                            )
                            echo "Docker image scan results registered with CloudBees Unify"
                        } else {
                            echo "No trivy-image-report.sarif produced, skipping registration"
                        }
                    }
                }
            }
        }

        /*
         stage('Run C Unit Tests') {
             steps {
                 container('build') {
                     echo "Running C unit tests..."
                     sh '''
                         make test

                         # Verify test results file exists
                         if [ -f test-results/c-test-results.xml ]; then
                             echo "C test results generated"
                             cat test-results/c-test-results.xml
                         else
                             echo "Warning: C test results file not found"
                         fi
                     '''
                 }
             }
             post {
                 always {
                     junit testResults: 'test-results/c-test-results.xml', allowEmptyResults: true
                 }
             }
         }
         */

        /*
         stage('Run Python Unit Tests') {
             steps {
                 container('build') {
                     echo "Running Python unit tests..."
                     sh '''
                         cd tests/python
                         pytest test_app.py \
                           --junitxml=../../test-results/pytest-results.xml \
                             --verbose
                     '''
                 }
             }
             post {
                 always {
                     junit testResults: 'test-results/pytest-results.xml', allowEmptyResults: true
                 }
             }
         }
         */

        /*
         stage('Code Quality Analysis') {
             steps {
                 container('build') {
                     echo "Running code quality checks..."
                     sh '''
                         # Python code quality
                         echo "=== Python Linting ==="
                         flake8 src/python/ --max-line-length=120 --statistics || true
                     '''
                 }
             }
         }
         */

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
                                 -Dsonar.projectKey=${APP_NAME}-testing \
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
                             project: "sdlc-demo-app-testing",
                             component: "",
                             host: "${SONAR_HOST}",
                             credentialId: "sonarqube-token"
                             //includeAllIssues: true
                         )
                         echo "SonarQube scan completed - exporting ALL issues (bugs, code smells, security)"
                         registerSecurityScan(
                             artifacts: 'sonarqube-*.sarif.json',
                             format: 'sarif',
                             scanner: 'sonarqube',
                             archive: true
                         )
                     }
                 }
             }
         }

        /*
        stage('Deploy to Development') {
            steps {
                container('build') {
                    echo "Simulating deployment to Development..."
                    script {
                        sh """
                            echo "=== Deployment Configuration ==="
                            echo "Application: ${APP_NAME}"
                            echo "Version: ${APP_VERSION}"
                            echo "Artifact: ${APP_NAME}-${APP_VERSION}.tar.gz"
                            echo "Environment: Development"

                            # Create deployment directory
                            mkdir -p deployment-dev

                            # Extract application package
                            echo "Extracting application package..."
                            tar -xzf ${APP_NAME}-${APP_VERSION}.tar.gz -C deployment-dev/

                            echo "Deployment directory prepared at: \${WORKSPACE}/deployment-dev"
                            echo "Contents:"
                            ls -lh deployment-dev/

                            # In a real deployment, you would:
                            # - Copy files to target server (scp, rsync)
                            # - Restart application services
                            # - Run health checks
                            # - Update load balancer configuration

                            echo "Development deployment simulation complete!"
                        """
                    }
                }
            }
            post {
                always {
                    script {
                        // Register deployed artifact with CloudBees Unify
                        registerDeployedArtifactMetadata(
                            artifactId: env.ARTIFACT_ID,
                            targetEnvironment: "Development",
                            labels: "deployed,deployment-${BUILD_NUMBER}"
                        )

                        echo "Deployment registered with CloudBees Unify for DORA metrics tracking"
                        echo "Environment: Development"
                        echo "Artifact ID: ${env.ARTIFACT_ID}"
                    }
                }
            }
        }
        */

        /*
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                container('build') {
                    echo "Simulating deployment to Production..."
                    script {
                        sh """
                            echo "=== Deployment Configuration ==="
                            echo "Application: ${APP_NAME}"
                            echo "Version: ${APP_VERSION}"
                            echo "Artifact: ${APP_NAME}-${APP_VERSION}.tar.gz"
                            echo "Environment: Production"

                            # Create deployment directory
                            mkdir -p deployment-prod

                            # Extract application package
                            echo "Extracting application package..."
                            tar -xzf ${APP_NAME}-${APP_VERSION}.tar.gz -C deployment-prod/

                            echo "Deployment directory prepared at: \${WORKSPACE}/deployment-prod"
                            echo "Contents:"
                            ls -lh deployment-prod/

                            # In a real deployment, you would:
                            # - Copy files to target server (scp, rsync)
                            # - Restart application services
                            # - Run health checks
                            # - Update load balancer configuration
                            echo "Production deployment simulation complete!"
                        """

                        echo "Deployment registered with CloudBees Unify for DORA metrics tracking"
                        echo "Environment: Production"
                        echo "Artifact ID: ${env.ARTIFACT_ID}"

                        echo "Deployment registered again with CloudBees Unify for DORA metrics tracking"
                        echo "Environment: Production"
                        echo "Artifact ID: ${env.ARTIFACT_ID}"
                    }
                }
            }
        }
        */

        /*
        stage('Production Validation Tests') {
            when {
                branch 'main'
            }
            steps {
                container('build') {
                    echo "Running production validation tests..."
                    script {
                        sh """
                            echo "=== Production Smoke Tests ==="
                            echo "Testing deployed application..."

                            # Simulate running smoke tests
                            echo "Running health check..."
                            echo "Running API endpoint tests..."
                            echo "Running database connectivity tests..."
                        """

                        // Intentionally fail the validation
                        //error "Production validation tests failed!"
                    }
                }
            }
            post {
                always {
                    script {
                        // Register deployment failure with CloudBees Unify
                        registerDeployedArtifactMetadata(
                            artifactId: env.ARTIFACT_ID,
                            targetEnvironment: "Production",
                            labels: "validation-failed,deployment-${BUILD_NUMBER}"
                        )

                        echo "Failed deployment validation registered with CloudBees Unify"
                        echo "Environment: Production"
                        echo "Artifact ID: ${env.ARTIFACT_ID}"
                    }
                }
            }
        }
        */
    }

    post {
        always {
            echo "=== Pipeline Execution Complete ==="
            echo "Build: ${env.BUILD_NUMBER}"
            echo "Status: ${currentBuild.result}"
            echo "Duration: ${currentBuild.durationString}"

            // Archive test results (not published to CloudBees yet)
            archiveArtifacts artifacts: 'test-results/**/*.xml', allowEmptyArchive: true
            archiveArtifacts artifacts: 'build/**', allowEmptyArchive: true
        }

        success {
            echo "[SUCCESS] Pipeline completed successfully!"
        }

        failure {
            echo "[FAILURE] Pipeline failed"
            echo "Check the logs above for error details"
        }

        unstable {
            echo "[UNSTABLE] Pipeline completed with warnings"
        }
    }
}

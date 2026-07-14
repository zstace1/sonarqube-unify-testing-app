pipeline {
    agent any

    environment {
        // Application versioning
        APP_VERSION = "${env.BUILD_NUMBER}"
        APP_NAME = "sdlc-demo-app"

        // Docker registry configuration
        // Replace with your Docker registry URL
        DOCKER_REGISTRY = credentials('docker-registry-url')
        DOCKER_IMAGE = "${DOCKER_REGISTRY}/${APP_NAME}:${APP_VERSION}"
        DOCKER_CREDENTIALS = 'docker-registry-credentials'

        // CloudBees Unify environment mapping
        DEPLOY_ENV = "${env.BRANCH_NAME == 'main' ? 'Production' : 'Development'}"

        // Security scanning configuration
        SONAR_HOST = credentials('sonarqube-url')
        SONAR_TOKEN = credentials('sonarqube-token')
        TRIVY_VERSION = "0.58.0"

        // Build directories
        BUILD_DIR = "build"
        TEST_RESULTS_DIR = "test-results"
    }

    stages {
        stage('Initialize') {
            steps {
                script {
                    echo "=== SDLC Metrics Jenkins Demo Pipeline ==="
                    echo "Build Number: ${env.BUILD_NUMBER}"
                    echo "Branch: ${env.BRANCH_NAME}"
                    echo "Target Environment: ${DEPLOY_ENV}"

                    // Capture Git commit info
                    env.GIT_COMMIT_HASH = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()

                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    echo "Git Commit: ${env.GIT_COMMIT_SHORT}"
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm

                script {
                    // Display repository information
                    sh '''
                        echo "Repository: $(git config --get remote.origin.url)"
                        echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
                        echo "Last Commit: $(git log -1 --pretty=format:'%h - %s (%an)')"
                    '''
                }
            }
        }

        stage('Setup Environment') {
            steps {
                echo "Setting up build environment..."
                sh '''
                    # Create necessary directories
                    mkdir -p ${BUILD_DIR}
                    mkdir -p ${TEST_RESULTS_DIR}

                    # Display tool versions
                    echo "=== Build Tool Versions ==="
                    gcc --version | head -1
                    python3 --version
                    pip3 --version || echo "pip3 not found"
                    make --version | head -1
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "Installing Python dependencies..."
                sh '''
                    pip3 install --user -r requirements.txt
                    pip3 install --user pytest-junit
                '''
            }
        }

        stage('Build C Application') {
            steps {
                echo "Building C application..."
                sh '''
                    make clean
                    make all

                    # Verify build artifacts
                    ls -lh build/

                    echo "C application built successfully"
                '''
            }
        }

        stage('Build Python Application') {
            steps {
                echo "Building Python application..."
                sh '''
                    # Compile Python files to check for syntax errors
                    python3 -m py_compile src/python/app.py

                    echo "Python application validated successfully"
                '''
            }
        }

        stage('Run C Unit Tests') {
            steps {
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
            post {
                always {
                    // Publish C test results to CloudBees Unify
                    junit testResults: '**/test-results/c-test-results.xml', allowEmptyResults: true
                }
            }
        }

        stage('Run Python Unit Tests') {
            steps {
                echo "Running Python unit tests..."
                sh '''
                    cd tests/python
                    pytest test_app.py \
                        --junitxml=../../test-results/pytest-results.xml \
                        --verbose
                '''
            }
            post {
                always {
                    // Publish Python test results to CloudBees Unify
                    junit testResults: '**/test-results/pytest-results.xml', allowEmptyResults: true
                }
            }
        }

        stage('Code Quality Analysis') {
            steps {
                echo "Running code quality checks..."
                sh '''
                    # Python code quality
                    echo "=== Python Linting ==="
                    flake8 src/python/ --max-line-length=120 --statistics || true

                    # C code could be analyzed with cppcheck if available
                    echo "=== C Code Analysis ==="
                    echo "Static analysis would run here (cppcheck, etc.)"
                '''
            }
        }

        stage('SAST Security Scan - SonarQube') {
            when {
                expression { return fileExists('sonar-project.properties') }
            }
            steps {
                echo "Running SonarQube SAST scan..."
                script {
                    // This stage demonstrates SonarQube integration
                    // Requires sonar-scanner to be installed on Jenkins agent
                    sh '''
                        echo "=== SonarQube Scanner ==="
                        echo "Note: Requires sonar-scanner installation"
                        echo "Project: ${APP_NAME}"
                        echo "Host: ${SONAR_HOST}"

                        # Uncomment when sonar-scanner is available:
                        # sonar-scanner \
                        #     -Dsonar.projectKey=${APP_NAME} \
                        #     -Dsonar.sources=src \
                        #     -Dsonar.host.url=${SONAR_HOST} \
                        #     -Dsonar.login=${SONAR_TOKEN}
                    '''
                }
            }
            post {
                always {
                    script {
                        // Export SonarQube results to CloudBees (when configured)
                        echo "SonarQube export would run here"
                        // Uncomment when SonarQube is configured:
                        // exportSonarQubeScan(
                        //     component: "",
                        //     project: "${APP_NAME}",
                        //     host: "${SONAR_HOST}",
                        //     credentialId: "sonarqube-token"
                        // )
                    }
                }
            }
        }

        stage('SCA Security Scan - Trivy') {
            steps {
                echo "Running Trivy security scan..."
                sh '''
                    # Install Trivy if not available
                    if ! command -v trivy &> /dev/null; then
                        echo "Installing Trivy ${TRIVY_VERSION}..."
                        wget https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz
                        tar zxf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz
                        chmod +x trivy

                        # Try to move to /usr/local/bin, fallback to local bin
                        if ! mv trivy /usr/local/bin/ 2>/dev/null; then
                            mkdir -p ~/bin
                            mv trivy ~/bin/
                            export PATH="$HOME/bin:$PATH"
                        fi
                    fi

                    # Run filesystem scan
                    echo "=== Trivy Filesystem Scan ==="
                    trivy fs --format sarif --output trivy-fs-report.sarif . || true

                    # Display scan summary
                    trivy fs --severity HIGH,CRITICAL . || true
                '''
            }
            post {
                always {
                    script {
                        // Register security scan with CloudBees
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

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                script {
                    sh """
                        docker build \
                            --build-arg APP_VERSION=${APP_VERSION} \
                            --tag ${DOCKER_IMAGE} \
                            --tag ${DOCKER_REGISTRY}/${APP_NAME}:latest \
                            .

                        echo "Docker image built: ${DOCKER_IMAGE}"
                        docker images | grep ${APP_NAME}
                    """
                }
            }
        }

        stage('Scan Docker Image') {
            steps {
                echo "Scanning Docker image for vulnerabilities..."
                sh """
                    # Scan the built image
                    trivy image \
                        --format sarif \
                        --output ${TEST_RESULTS_DIR}/trivy-image-report.sarif \
                        ${DOCKER_IMAGE} || true

                    # Display critical vulnerabilities
                    trivy image --severity CRITICAL ${DOCKER_IMAGE} || true
                """
            }
            post {
                always {
                    script {
                        // Register container scan with CloudBees
                        if (fileExists("${TEST_RESULTS_DIR}/trivy-image-report.sarif")) {
                            registerSecurityScan(
                                artifacts: "${TEST_RESULTS_DIR}/trivy-image-report.sarif",
                                format: "sarif",
                                scanner: "Trivy",
                                archive: true
                            )
                        }
                    }
                }
            }
        }

        stage('Push Docker Image') {
            when {
                expression { return env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'develop' }
            }
            steps {
                echo "Pushing Docker image to registry..."
                script {
                    withCredentials([usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIALS}",
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh '''
                            echo "${DOCKER_PASS}" | docker login ${DOCKER_REGISTRY} -u "${DOCKER_USER}" --password-stdin
                            docker push ${DOCKER_IMAGE}
                            docker push ${DOCKER_REGISTRY}/${APP_NAME}:latest
                            echo "Docker image pushed successfully"
                        '''
                    }
                }
            }
            post {
                success {
                    script {
                        // Capture Docker image digest
                        env.DOCKER_DIGEST = sh(
                            script: "docker inspect ${DOCKER_IMAGE} --format='{{.Id}}'",
                            returnStdout: true
                        ).trim()

                        // Register build artifact with CloudBees Unify
                        def buildArtifactId = registerBuildArtifactMetadata(
                            name: "${APP_NAME}",
                            url: "${DOCKER_IMAGE}",
                            version: "${APP_VERSION}",
                            type: "Docker",
                            digest: "${env.DOCKER_DIGEST}",
                            label: "build-${BUILD_NUMBER},${env.BRANCH_NAME}"
                        )

                        // Capture artifact ID for deployment tracking
                        env.ARTIFACT_ID = buildArtifactId
                        echo "Build artifact registered with CloudBees Unify"
                        echo "Artifact ID: ${env.ARTIFACT_ID}"
                    }
                }
            }
        }

        stage('Deploy to Environment') {
            steps {
                echo "Deploying to ${DEPLOY_ENV} environment..."
                script {
                    // Deployment logic
                    // In a real scenario, this would use kubectl, helm, or other deployment tools
                    sh """
                        echo "=== Deployment Configuration ==="
                        echo "Environment: ${DEPLOY_ENV}"
                        echo "Image: ${DOCKER_IMAGE}"
                        echo "Version: ${APP_VERSION}"
                        echo "Digest: ${DOCKER_DIGEST}"

                        # Simulate deployment steps
                        echo "Pulling image..."
                        echo "Updating deployment manifest..."
                        echo "Applying configuration to ${DEPLOY_ENV}..."

                        # Simulate deployment verification
                        sleep 2
                        echo "Verifying deployment status..."
                        echo "Deployment successful!"

                        # In production, you would run:
                        # kubectl set image deployment/${APP_NAME} ${APP_NAME}=${DOCKER_IMAGE}
                        # kubectl rollout status deployment/${APP_NAME}
                        # Or with Helm:
                        # helm upgrade ${APP_NAME} ./charts/${APP_NAME} --set image.tag=${APP_VERSION} --wait
                    """
                }
            }
            post {
                success {
                    script {
                        echo "Deployment to ${DEPLOY_ENV} completed successfully"

                        // Register deployed artifact with CloudBees Unify
                        // This associates the artifact with the target environment for DORA metrics
                        registerDeployedArtifactMetadata(
                            artifactId: env.ARTIFACT_ID,
                            targetEnvironment: "${DEPLOY_ENV}",
                            labels: "deployed,deployment-${BUILD_NUMBER}"
                        )

                        echo "Deployment registered with CloudBees Unify for DORA metrics tracking"
                        echo "Environment: ${DEPLOY_ENV}"
                        echo "Artifact ID: ${env.ARTIFACT_ID}"
                        echo "Artifact: ${DOCKER_IMAGE}"
                    }
                }
                failure {
                    echo "Deployment to ${DEPLOY_ENV} failed"
                    echo "Rollback may be required"
                }
            }
        }

        stage('Smoke Tests') {
            when {
                expression { return env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'develop' }
            }
            steps {
                echo "Running smoke tests..."
                sh '''
                    echo "=== Smoke Test Suite ==="
                    echo "Verifying deployment health..."

                    # Placeholder for actual smoke tests
                    # curl -f http://deployed-app/health || exit 1

                    echo "Smoke tests passed"
                '''
            }
        }
    }

    post {
        always {
            echo "=== Pipeline Execution Complete ==="
            echo "Build: ${env.BUILD_NUMBER}"
            echo "Status: ${currentBuild.result}"
            echo "Duration: ${currentBuild.durationString}"

            // Clean up Docker images to save space
            sh '''
                docker rmi ${DOCKER_IMAGE} || true
                docker system prune -f || true
            '''

            // Archive important artifacts
            archiveArtifacts artifacts: 'test-results/**/*.xml', allowEmptyArchive: true
            archiveArtifacts artifacts: 'test-results/**/*.sarif', allowEmptyArchive: true
            archiveArtifacts artifacts: 'build/**', allowEmptyArchive: true
        }

        success {
            echo "[SUCCESS] Pipeline completed successfully!"
            echo "All SDLC metrics have been sent to CloudBees Unify"
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

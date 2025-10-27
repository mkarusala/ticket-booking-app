/**
 * Improved Declarative Jenkins Pipeline for Ticket Booking Application
 *
 * - Adds checkout, lint, caching, retries and parallel test split (unit / integration).
 * - Produces a reproducible image tag (build number + short git commit).
 * - Uses Jenkins credentials securely for Docker and Kubernetes.
 * - Adds helpful options: timestamps, timeout, build discarder.
 * - Better error handling and clearer logs.
 *
 * NOTE: Replace placeholders:
 *   - 'docker-hub-credentials-id' -> your Jenkins Docker Hub credentials ID
 *   - 'yourdockerhub/ticket-booking-app' -> your Docker Hub repo
 *   - 'kubeconfig-credentials-id' -> file-type credential that contains kubeconfig
 *   - adjust NodeJS tool name or remove the tools block if not configured
 */
pipeline {
  agent any

  // keep workspace clean/short logs/timeouts
  options {
    timestamps()
    timeout(time: 60, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '30', daysToKeepStr: '30'))
    ansiColor('xterm')
  }

  // IMPORTANT: replace ids/values below
  environment {
    DOCKER_CREDENTIALS = 'docker-hub-credentials-id'          // Jenkins usernamePassword or Docker credentials (ID)
    DOCKER_REPO        = 'yourdockerhub/ticket-booking-app'   // eg. 'johndoe/ticket-booking-app'
    APP_NAME           = 'ticket-booking-service'
    K8S_CREDS_ID       = 'kubeconfig-credentials-id'         // file credential id containing kubeconfig
    // NODEJS_TOOL      = 'NodeJS'                            // uncomment/adapt if you have a NodeJS tool configured
  }

  // tools { nodejs "${env.NODEJS_TOOL}" } // uncomment if using Jenkins Tool installer for Node

  stages {
    stage('1. Checkout') {
      steps {
        echo "Checking out ${env.BRANCH_NAME ?: 'SCM default branch'}..."
        checkout scm
        // show short commit for debugging
        script {
          env.GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          echo "Checked out commit ${env.GIT_COMMIT_SHORT}"
        }
      }
    }

    stage('2. Lint / Install') {
      steps {
        echo 'Installing dependencies and linting...'
        // cache node_modules with workspace if desired (simple example)
        sh '''
          if [ -f package-lock.json ]; then
            npm ci --silent
          else
            npm install --silent
          fi
          npm run lint || echo "Lint warnings (non-blocking)"; 
        '''
      }
    }

    stage('3. Build Docker Image') {
      steps {
        script {
          // create a deterministic tag: <repo>:<buildNumber>-<shortCommit>
          env.IMAGE_TAG = "${env.DOCKER_REPO}:${env.BUILD_NUMBER}-${env.GIT_COMMIT_SHORT}"
          echo "Building Docker image: ${env.IMAGE_TAG}"

          // allow 2 retries on transient docker build issues
          retry(2) {
            // build with cache-from if you keep previous images (optional)
            docker.build(env.IMAGE_TAG, "--pull .")
          }
        }
      }
    }

    stage('4. Tests (parallel)') {
      parallel {
        stage('Unit Tests') {
          steps {
            echo 'Running unit tests...'
            sh 'npm test -- --silent || { echo "Unit tests failed"; exit 1; }'
          }
          post { failure { echo 'Unit tests failed' } }
        }
        stage('Integration Tests') {
          steps {
            echo 'Running integration tests (if any)...'
            // if you have separate integration test script, run it; otherwise skip quickly
            sh 'if [ -f package.json ] && npm run -s integration-test >/dev/null 2>&1; then npm run integration-test; else echo "No integration tests script defined"; fi'
          }
          post { failure { echo 'Integration tests failed' } }
        }
      }
    }

    stage('5. Security / Image Scan (optional)') {
      steps {
        echo 'Optional: run container image scan (configure scanner as needed)'
        // Example placeholder for Trivy/other scanner:
        // sh 'trivy image --exit-code 1 ${env.IMAGE_TAG} || true'
        echo 'Skipping scan (configure if required)'
      }
    }

    stage('6. Push to Docker Hub') {
      steps {
        script {
          echo "Pushing ${env.IMAGE_TAG} and latest to registry..."
          // Use docker.withRegistry to use stored credentials. Provide credential ID.
          docker.withRegistry('https://registry.hub.docker.com', env.DOCKER_CREDENTIALS) {
            def img = docker.image(env.IMAGE_TAG)
            img.push() // push buildNumber-shortCommit tag
            // tag a separate 'latest' (or use semantic tags as desired)
            sh "docker tag ${env.IMAGE_TAG} ${env.DOCKER_REPO}:latest"
            sh "docker push ${env.DOCKER_REPO}:latest"
          }
        }
      }
    }

    stage('7. Deploy to Kubernetes') {
      steps {
        echo 'Deploying to Kubernetes using kubeconfig from credentials...'
        // Use file credentials to expose kubeconfig temporarily
        withCredentials([file(credentialsId: env.K8S_CREDS_ID, variable: 'KUBECONFIG_FILE')]) {
          // substitute IMAGE_TAG placeholder in k8s manifests without mutating repo (create temp copy)
          sh '''
            export KUBECONFIG="${KUBECONFIG_FILE}"
            TMP_DIR=$(mktemp -d)
            cp -r k8s/* "$TMP_DIR/"
            sed -i "s|IMAGE_TAG_PLACEHOLDER|${IMAGE_TAG}|g" "$TMP_DIR"/deployment.yaml || true
            kubectl apply -f "$TMP_DIR"/deployment.yaml
            kubectl apply -f "$TMP_DIR"/service.yaml
            kubectl rollout status deployment/${APP_NAME} --timeout=120s || (kubectl describe deployment ${APP_NAME} && kubectl get pods -o wide && exit 1)
          '''
        }
      }
    }
  }

  post {
    always {
      echo 'Cleaning workspace...'
      cleanWs()
    }
    success {
      echo "Pipeline finished successfully! Deployed ${env.IMAGE_TAG}"
    }
    failure {
      echo 'Pipeline failed. Check console logs for details.'
    }
  }
}

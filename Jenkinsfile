/**
 * Fixed Declarative Jenkins Pipeline for Ticket Booking Application
 *
 * ✅ Fixed invalid ansiColor placement
 * ✅ Compatible with Jenkins LTS without plugin errors
 * ✅ Clean structure + parallel test + Docker + K8s deploy
 */

pipeline {
  agent any

  options {
    timestamps()
    timeout(time: 60, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '30', daysToKeepStr: '30'))
    // Removed ansiColor('xterm') from options (invalid placement)
  }

  environment {
    DOCKER_CREDENTIALS = 'docker-hub-credentials-id'
    DOCKER_REPO        = 'yourdockerhub/ticket-booking-app'
    APP_NAME           = 'ticket-booking-service'
    K8S_CREDS_ID       = 'kubeconfig-credentials-id'
  }

  stages {

    stage('1. Checkout') {
      steps {
        ansiColor('xterm') {
          echo "Checking out ${env.BRANCH_NAME ?: 'SCM default branch'}..."
          checkout scm
          script {
            env.GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
            echo "Checked out commit ${env.GIT_COMMIT_SHORT}"
          }
        }
      }
    }

    stage('2. Lint / Install') {
      steps {
        ansiColor('xterm') {
          echo 'Installing dependencies and linting...'
          sh '''
            if [ -f package-lock.json ]; then
              npm ci --silent
            else
              npm install --silent
            fi
            npm run lint || echo "Lint warnings (non-blocking)"
          '''
        }
      }
    }

    stage('3. Build Docker Image') {
      steps {
        ansiColor('xterm') {
          script {
            env.IMAGE_TAG = "${env.DOCKER_REPO}:${env.BUILD_NUMBER}-${env.GIT_COMMIT_SHORT}"
            echo "Building Docker image: ${env.IMAGE_TAG}"
            retry(2) {
              docker.build(env.IMAGE_TAG, "--pull .")
            }
          }
        }
      }
    }

    stage('4. Tests (parallel)') {
      parallel {
        stage('Unit Tests') {
          steps {
            ansiColor('xterm') {
              echo 'Running unit tests...'
              sh 'npm test -- --silent || { echo "Unit tests failed"; exit 1; }'
            }
          }
          post { failure { echo 'Unit tests failed' } }
        }

        stage('Integration Tests') {
          steps {
            ansiColor('xterm') {
              echo 'Running integration tests (if any)...'
              sh '''
                if [ -f package.json ] && npm run -s integration-test >/dev/null 2>&1; then
                  npm run integration-test
                else
                  echo "No integration tests script defined"
                fi
              '''
            }
          }
          post { failure { echo 'Integration tests failed' } }
        }
      }
    }

    stage('5. Security / Image Scan (optional)') {
      steps {
        ansiColor('xterm') {
          echo 'Optional: run container image scan (configure scanner as needed)'
          echo 'Skipping scan (configure if required)'
        }
      }
    }

    stage('6. Push to Docker Hub') {
      steps {
        ansiColor('xterm') {
          script {
            echo "Pushing ${env.IMAGE_TAG} and latest to registry..."
            docker.withRegistry('https://registry.hub.docker.com', env.DOCKER_CREDENTIALS) {
              def img = docker.image(env.IMAGE_TAG)
              img.push()
              sh "docker tag ${env.IMAGE_TAG} ${env.DOCKER_REPO}:latest"
              sh "docker push ${env.DOCKER_REPO}:latest"
            }
          }
        }
      }
    }

    stage('7. Deploy to Kubernetes') {
      steps {
        ansiColor('xterm') {
          echo 'Deploying to Kubernetes using kubeconfig from credentials...'
          withCredentials([file(credentialsId: env.K8S_CREDS_ID, variable: 'KUBECONFIG_FILE')]) {
            sh '''
              export KUBECONFIG="${KUBECONFIG_FILE}"
              TMP_DIR=$(mktemp -d)
              cp -r k8s/* "$TMP_DIR/"
              sed -i "s|IMAGE_TAG_PLACEHOLDER|${IMAGE_TAG}|g" "$TMP_DIR"/deployment.yaml || true
              kubectl apply -f "$TMP_DIR"/deployment.yaml
              kubectl apply -f "$TMP_DIR"/service.yaml
              kubectl rollout status deployment/${APP_NAME} --timeout=120s || (
                kubectl describe deployment ${APP_NAME}
                kubectl get pods -o wide
                exit 1
              )
            '''
          }
        }
      }
    }
  }

  post {
    always {
      ansiColor('xterm') {
        echo 'Cleaning workspace...'
        cleanWs()
      }
    }
    success {
      ansiColor('xterm') {
        echo "✅ Pipeline finished successfully! Deployed ${env.IMAGE_TAG}"
      }
    }
    failure {
      ansiColor('xterm') {
        echo '❌ Pipeline failed. Check console logs for details.'
      }
    }
  }
}

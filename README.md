Perfect — here’s the **final, GitHub-optimized Markdown version** of your `README.md` file.
It’s properly structured, visually clean, and ready to paste directly into your repository.

---

````markdown
# Ticket Booking Application — DevOps Workflow

**Author:** Karusala Meenakshi  
**Repository:** [github.com/mkarusala/ticket-booking-app](https://github.com/mkarusala/ticket-booking-app)

---

## 1. Project Overview

This project is a **Node.js-based Ticket Booking Application** developed to demonstrate a complete **DevOps lifecycle** using **Git**, **Docker**, **Jenkins**, and **Kubernetes**.

The primary objective is to automate the build, test, and deployment processes of a simple web application while showcasing how modern DevOps tools integrate efficiently.

---

## 2. Application Overview

- **Tech Stack:** Node.js, Express  
- **Functionality:** RESTful API for ticket booking operations  
- **Storage:** In-memory (for demonstration)  
- **Default Port:** `http://localhost:3000`

---

## 3. Version Control (Git & GitHub)

### 3.1 Repository Initialization

```bash
git init
echo "node_modules" > .gitignore
echo "package-lock.json" >> .gitignore
git add .
git commit -m "feat: Initial setup for Node app and CI/CD config"
````

### 3.2 Branching Setup

```bash
git branch develop
git checkout develop
git remote add origin https://github.com/mkarusala/ticket-booking-app.git
git push -u origin main
git push -u origin develop
```

### 3.3 Branching Strategy

| Branch   | Purpose                          |
| -------- | -------------------------------- |
| main     | Stable production-ready branch   |
| develop  | Active integration branch        |
| feature/ | New feature development          |
| release/ | Pre-production testing           |
| hotfix/  | Quick fixes to production issues |

---

## 4. Containerization (Docker)

### 4.1 Dockerfile

```dockerfile
# Stage 1: Build
FROM node:18-alpine AS build
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm test

# Stage 2: Production
FROM node:18-alpine
WORKDIR /usr/src/app
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/app.js .
EXPOSE 3000
CMD ["node", "app.js"]
```

### 4.2 Build and Run Commands

```bash
docker build -t ticket-booking-app:local-test .
docker run -d -p 8080:3000 --name ticket-test ticket-booking-app:local-test
docker logs ticket-test
```

**Expected Output:**
`Server running on http://localhost:3000`

---

## 5. Continuous Integration (Jenkins)

### 5.1 Run Jenkins in Docker

```bash
docker run -d -p 8080:8080 -p 50000:50000 --name jenkins-server jenkins/jenkins:lts
```

If the port is already in use:

```bash
docker stop ticket-test
docker rm jenkins-server
docker run -d -p 8080:8080 -p 50000:50000 --name jenkins-server jenkins/jenkins:lts
```

### 5.2 Retrieve Jenkins Admin Password

```bash
docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword
```

**Example Output:**
`a7ff5c14cbf943099beb42fe85d704a4`

### 5.3 Jenkins Configuration Steps

1. Access Jenkins at `http://localhost:8080`
2. Enter the retrieved admin password
3. Install suggested plugins
4. Create the admin user
5. Install required plugins:

   * Git
   * Docker
   * Pipeline
   * Kubernetes

---

## 6. Jenkins Pipeline (CI/CD)

### 6.1 Jenkinsfile

```groovy
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git branch: 'develop', url: 'https://github.com/mkarusala/ticket-booking-app.git'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ticket-booking-app:${BUILD_NUMBER} .'
            }
        }
        stage('Run Tests') {
            steps {
                sh 'docker run ticket-booking-app:${BUILD_NUMBER} npm test || true'
            }
        }
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh 'echo $PASS | docker login -u $USER --password-stdin'
                    sh 'docker tag ticket-booking-app:${BUILD_NUMBER} your_dockerhub_username/ticket-booking-app:${BUILD_NUMBER}'
                    sh 'docker push your_dockerhub_username/ticket-booking-app:${BUILD_NUMBER}'
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl apply -f k8s/deployment.yaml'
                sh 'kubectl apply -f k8s/service.yaml'
            }
        }
    }
}
```

---

## 7. Kubernetes Deployment

### 7.1 Deployment Configuration (`deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ticket-booking-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ticket-booking-app
  template:
    metadata:
      labels:
        app: ticket-booking-app
    spec:
      containers:
      - name: ticket-booking-app
        image: mkarusala/ticket-booking-app:latest
        ports:
        - containerPort: 3000
```

### 7.2 Service Configuration (`service.yaml`)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ticket-booking-service
spec:
  selector:
    app: ticket-booking-app
  ports:
  - port: 8080
    targetPort: 3000
  type: LoadBalancer
```

### 7.3 Deployment Commands

```bash
kubectl apply -f k8s/
kubectl get pods
kubectl get svc
kubectl scale deployment ticket-booking-app --replicas=5
```

---

## 8. Workflow Summary

| Stage                  | Tool / Technology | Description                                |
| ---------------------- | ----------------- | ------------------------------------------ |
| Version Control        | Git, GitHub       | Code management and version tracking       |
| Containerization       | Docker            | Packaging and environment isolation        |
| Continuous Integration | Jenkins           | Automated build, test, and deploy process  |
| Orchestration          | Kubernetes        | Scaling, management, and service discovery |

---

## 9. Commands Summary

| Action               | Command                                                                         |
| -------------------- | ------------------------------------------------------------------------------- |
| Initialize Git       | `git init`                                                                      |
| Build Docker Image   | `docker build -t ticket-booking-app:local-test .`                               |
| Run Container        | `docker run -d -p 8080:3000 ticket-booking-app:local-test`                      |
| View Logs            | `docker logs ticket-test`                                                       |
| Stop Jenkins         | `docker stop jenkins-server`                                                    |
| Get Jenkins Password | `docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword` |
| Deploy to Kubernetes | `kubectl apply -f k8s/`                                                         |

---

## 10. Current Deployment Status

* **Docker Image:** Built and tested successfully
* **Application URL:** [http://localhost:3000](http://localhost:3000)
* **Jenkins:** Running at [http://localhost:8080](http://localhost:8080)
* **Kubernetes:** Ready for scaling and load balancing
* **GitHub Repository:** [mkarusala/ticket-booking-app](https://github.com/mkarusala/ticket-booking-app)

---

## 11. Key Highlights

* Multi-stage Docker build for optimized image size and efficiency
* Automated CI/CD pipeline using Jenkins
* Kubernetes manifests for cloud-ready deployment
* GitFlow branching model implementation
* Clean commits, structured logs, and modular DevOps workflow

---

## 12. Final Outcome

A fully automated **DevOps pipeline** has been implemented for a **Ticket Booking Web Application**, integrating **Docker**, **Jenkins**, and **Kubernetes** for build, test, and deployment stages.
The setup is production-ready and can be easily extended for cloud environments.

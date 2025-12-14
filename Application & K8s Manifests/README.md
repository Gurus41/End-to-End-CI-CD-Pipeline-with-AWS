Based on the GitHub repository you shared, I can help you create a comprehensive, step-by-step `README.md` file for the "End-to-End CI/CD Pipeline on AWS" project.

The repository contains the actual application source code, Dockerfile, and other configuration files needed to run the pipeline you described. The following `README.md` integrates your detailed setup instructions with the project's specific structure.

---

# End-to-End CI/CD Pipeline on AWS 🚀

This project implements a fully automated CI/CD pipeline using **Jenkins**, **SonarQube**, **Docker**, **AWS ECR**, and **AWS EKS** to build, scan, and deploy a containerized Node.js application on a Kubernetes cluster.

## 📋 Table of Contents
- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Step-by-Step Setup Guide](#step-by-step-setup-guide)
- [Running the Pipeline](#running-the-pipeline)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## 🏗️ Architecture Overview

The pipeline automates the entire software delivery process:
1.  **Source**: Code is committed to this Git repository.
2.  **CI Server (Jenkins)**: Pulls the code and orchestrates the pipeline.
3.  **Code Analysis (SonarQube)**: Scans for code quality, bugs, and security vulnerabilities.
4.  **Security Scan (Trivy)**: Scans the application files and the built Docker image for vulnerabilities.
5.  **Containerization (Docker)**: Builds the application into a Docker image.
6.  **Registry (AWS ECR / Docker Hub)**: Stores the approved Docker image.
7.  **Orchestration (AWS EKS)**: Deploys the containerized application (Future Scope).

```
[GitHub] --> [Jenkins] --> [SonarQube] --> [Quality Gate]
    |            |              |
    v            v              v
[Build & Test] -> [Docker Build] -> [Trivy Scan] -> [Push to Registry] -> [Deploy to EKS]
```

## 📁 Project Structure

```
End-to-End-CI-CD-Pipeline-on-AWS/
├── public/                 # Static assets (CSS, images)
├── src/                    # Application source code
├── .env.example            # Environment variables template
├── .gitignore
├── Dockerfile             # Instructions to build the Docker image
├── package.json           # Node.js dependencies and scripts
├── package-lock.json
└── (Kubernetes manifests for EKS - can be added here)
```

## ✅ Prerequisites

Before you begin, ensure you have the following:

1.  **An AWS Account** with configured credentials and an EC2 instance.
2.  **Software on EC2 Instance**:
    *   Jenkins (with port 8080 open)
    *   SonarQube (with port 9000 open)
    *   Docker
    *   Node.js & JDK (will be installed via Jenkins)
    *   Trivy (for security scanning)
3.  **Accounts & Tokens**:
    *   A **Docker Hub** account or an **AWS ECR** repository.
    *   A **SonarQube** user token.
    *   (Optional) AWS CLI configured for ECR/EKS access.

## 🛠️ Step-by-Step Setup Guide

Follow these steps to configure the tools and integrate them.

### Phase 1: Initial Access & Plugin Installation

1.  **Access Jenkins**
    *   Open your browser: `http://<YOUR-EC2-PUBLIC-IP>:8080`
    *   Get the admin password: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
    *   Log in and complete the setup.

2.  **Install Required Jenkins Plugins**
    Go to **Manage Jenkins > Manage Plugins > Available** tab. Search and install:
    *   Eclipse Temurin Installer
    *   SonarQube Scanner
    *   Sonar Quality Gates
    *   Node.js
    *   Docker Pipeline, Docker API, Docker Build Step

### Phase 2: Configure Global Tools in Jenkins

Navigate to **Manage Jenkins > Tools**. Configure the following:

| Tool | Name | Version / Source | Install Automatically |
| :--- | :--- | :--- | :--- |
| **JDK** | `jdk17` | `jdk-17.0.8.1+1` (Install from adoptium.net) | ✅ Yes |
| **Node.js** | `node16` | `NodeJS 16.2.0` | ✅ Yes |
| **Docker** | (Default) | `latest` | ✅ Yes |
| **SonarQube Scanner** | (Default) | `SonarQube Scanner 5.0.1.3006` | ✅ Yes |

Click **Apply** and **Save**.

### Phase 3: Configure SonarQube & Integrate with Jenkins

1.  **Access SonarQube**
    *   Open your browser: `http://<YOUR-EC2-PUBLIC-IP>:9000`
    *   Log in with default credentials (`admin`/`admin`).

2.  **Generate a SonarQube User Token**
    *   Go to **Administration > Security > Users**. Click on your user (e.g., `admin`).
    *   Under **Tokens**, click **Generate**. Name it `jenkins-token` and copy the generated value.

3.  **Add the Token as a Credential in Jenkins**
    *   Go to **Manage Jenkins > Manage Credentials > System > Global credentials**.
    *   Add a new credential:
        *   **Kind**: `Secret text`
        *   **Secret**: Paste the SonarQube token.
        *   **ID**: `sonarqube-token`
        *   **Description**: `Token for SonarQube Server`

4.  **Configure SonarQube Server in Jenkins**
    *   Go to **Manage Jenkins > Configure System**.
    *   Find the **SonarQube servers** section. Click **Add SonarQube**.
    *   **Name**: `sonarqube-server`
    *   **Server URL**: `http://<YOUR-EC2-PUBLIC-IP>:9000`
    *   **Server authentication token**: Select the `sonarqube-token` credential.

5.  **Create a Webhook in SonarQube**
    *   In SonarQube, go to **Administration > Configuration > Webhooks**.
    *   Click **Create**.
    *   **Name**: `Jenkins`
    *   **URL**: `http://<YOUR-EC2-PUBLIC-IP>:8080/sonarqube-webhook/`
    *   This allows SonarQube to send analysis results back to Jenkins.

### Phase 4: Configure Docker Hub / AWS ECR Credentials

1.  **Generate an Access Token** from your container registry (Docker Hub or AWS ECR).
2.  **Add the Credentials in Jenkins**:
    *   Go to **Manage Jenkins > Manage Credentials**.
    *   Add a new credential with **Kind** as `Username with password`.
    *   **Username**: Your Docker Hub username or AWS access key.
    *   **Password**: Your Docker Hub token or AWS secret key.
    *   **ID**: `container-registry-creds`

## 🚀 Running the Pipeline

### 1. Create the Jenkins Pipeline Job

1.  In Jenkins, click **New Item**.
2.  Enter a name, e.g., `End-to-End-CI-CD-Pipeline`, select **Pipeline**, and click **OK**.
3.  In the job configuration:
    *   Under **General**, you can check **Discard old builds** to keep the history clean.
    *   Scroll down to the **Pipeline** section.
    *   For **Definition**, select **Pipeline script**.
    *   Paste the Jenkins Pipeline script (provided below) into the **Script** text area.

### 2. The Complete Jenkins Pipeline Script

This script defines your entire CI/CD process. **Remember to replace placeholders like `<your-dockerhub-username>` with your actual details.**

```groovy
pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        // Path to SonarQube scanner
        SCANNER_HOME = tool 'sonar-scanner'
        // Your container registry image name (Modify this!)
        DOCKER_IMAGE = '<your-dockerhub-username>/end-to-end-cicd-app:latest'
    }
    stages {
        // Stage 1: Clean workspace and fetch latest code
        stage('Clean & Checkout') {
            steps {
                cleanWs()
                git branch: 'main', url: 'https://github.com/Gurus41/End-to-End-CI-CD-Pipeline-on-AWS.git'
            }
        }
        // Stage 2: Code Quality Analysis with SonarQube
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonarqube-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=End-to-End-CI-CD-Pipeline \
                    -Dsonar.projectKey=End-to-End-CI-CD-Pipeline \
                    -Dsonar.sources=src \
                    -Dsonar.host.url=http://<YOUR-EC2-PUBLIC-IP>:9000 '''
                    // Update the SonarQube host URL above
                }
            }
        }
        // Stage 3: Wait for Quality Gate result
        stage("Quality Gate") {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        // Stage 4: Install Node.js dependencies
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }
        // Stage 5: Security Scan on Source Code
        stage('Trivy Filesystem Scan') {
            steps {
                sh 'trivy fs . > trivy-fs-scan-report.txt'
                // Consider adding logic to fail the build on critical vulnerabilities
            }
        }
        // Stage 6: Build and Push Docker Image
        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry([credentialsId: 'container-registry-creds', url: '']) {
                        sh "docker build -t ${DOCKER_IMAGE} ."
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }
        // Stage 7: Security Scan on Docker Image
        stage('Trivy Image Scan') {
            steps {
                sh "trivy image ${DOCKER_IMAGE} > trivy-image-scan-report.txt"
            }
        }
        // Stage 8 (Future): Deploy to AWS EKS
        // stage('Deploy to EKS') {
        //     steps {
        //         script {
        //             // Steps to update Kubernetes manifests and deploy using kubectl
        //             echo 'Deploying to EKS...'
        //         }
        //     }
        // }
    }
    post {
        always {
            // Archive useful reports after build completes
            archiveArtifacts artifacts: 'trivy-*.txt', allowEmptyArchive: true
            echo 'Pipeline execution completed.'
        }
    }
}
```

### 3. Run the Pipeline

1.  Click **Save** on your Jenkins job.
2.  Click **Build Now** to trigger the pipeline manually.
3.  You can monitor the progress through each stage in the **Stage View**. Click on each stage for detailed logs.

## 📊 Monitoring (Next Steps)

After your pipeline is running, consider setting up monitoring to observe its health and performance:

*   **Prometheus & Grafana**: Install these on your EC2 instance or a separate server to collect metrics from Jenkins, SonarQube, and your application.
*   **Jenkins Monitoring Plugins**: Explore plugins like "Monitoring" and "Build Monitor View" for internal dashboards.
*   **CloudWatch**: Use AWS CloudWatch to monitor your EC2 instance metrics (CPU, Memory, Disk I/O).

## 🐛 Troubleshooting

| Issue | Possible Solution |
| :--- | :--- |
| **Jenkins cannot connect to SonarQube** | Verify SonarQube is running (`systemctl status sonar`). Check firewall rules for port `9000`. Ensure the server URL in Jenkins is correct. |
| **Docker permission denied in Jenkins** | Add the `jenkins` user to the `docker` group: `sudo usermod -aG docker jenkins` and restart Jenkins. |
| **SonarQube scanner not found** | Verify the SonarQube Scanner tool is correctly installed in **Manage Jenkins > Tools**. The `SCANNER_HOME` path in the pipeline should be correct. |
| **Pipeline fails at Quality Gate** | Check the analysis results directly in the SonarQube UI (`http://<EC2-IP>:9000`). Your code might not be meeting the defined quality conditions. |
| **Cannot push to Docker Hub/ECR** | Double-check the credentials ID in the `withDockerRegistry` step. Ensure your token/password has the correct write permissions. |

---

## 🔗 Useful Resources

*   [Official Jenkins Documentation](https://www.jenkins.io/doc/)
*   [SonarQube Documentation](https://docs.sonarsource.com/sonarqube/)
*   [Docker Documentation](https://docs.docker.com/)
*   [Trivy Scanner Documentation](https://aquasecurity.github.io/trivy/)

---
**Happy Building!** Feel free to contribute to this project by extending the pipeline with deployment to AWS EKS, adding more test stages, or improving the monitoring setup.
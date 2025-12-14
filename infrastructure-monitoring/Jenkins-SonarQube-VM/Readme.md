# End-to-End CI/CD Pipeline Setup on AWS: Jenkins and SonarQube Integration

This guide provides step-by-step instructions to set up Jenkins and SonarQube on an EC2 instance, configure necessary plugins and tools, and integrate SonarQube with Jenkins for a complete CI/CD pipeline.

## Prerequisites
- An EC2 instance running with Jenkins and SonarQube installed (via Terraform or manual setup).
- Replace `<EC2-Public-IP>` with your actual EC2 public IP address throughout this guide.

## 1. Access Jenkins Web UI
1. Open your web browser and navigate to:  
   `http://<EC2-Public-IP>:8080`

2. To get the initial admin password, run the following command on your EC2 instance:  
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
   - Copy the password and use it to log in as the admin user.

## 2. Install Jenkins Plugins
After logging into Jenkins:
1. Navigate to **Manage Jenkins** > **Manage Plugins**.
2. Go to the **Available** tab.
3. Search for and install the following plugins (check the boxes and click **Install without restart** or **Download now and install after restart**):
   - Eclipse Temurin Installer
   - SonarQube Scanner
   - Sonar Quality Gates
   - Quality Gates
   - Node.js
   - Docker
   - Docker Commands
   - Docker Pipeline
   - Docker API
   - Docker Build Step

4. Restart Jenkins if prompted to apply the changes.

## 3. Configure Tools in Jenkins
1. Navigate to **Manage Jenkins** > **Tools**.
2. Configure the following tools:

   ### Node.js Installation
   - Click **Add Node.js**.
   - **Name**: `node16`
   - **Install automatically**: Check this box.
   - **Version**: `NodeJS 16.2.0`

   ### JDK Installation
   - Click **Add JDK**.
   - **Name**: `jdk17`
   - **Install automatically**: Check this box.
   - **Add Installer**: Select **Install from adoptium.net**.
   - **Version**: `jdk-17.0.8.1+1`

   ### Docker Installation
   - Click **Add Docker**.
   - **Install automatically**: Check this box.
   - **Version**: `latest`

   ### SonarQube Scanner Installation
   - Click **Add SonarQube Scanner**.
   - **Name**: `sonar-scanner`
   - **Install automatically**: Check this box.
   - **Version**: `SonarQube Scanner 5.0.1.3006`

3. Click **Apply** and **Save**.

## 4. Access SonarQube Web UI
1. Open your web browser and navigate to:  
   `http://<EC2-Public-IP>:9000`

2. Use the default admin credentials:  
   - **Username**: `admin`  
   - **Password**: `admin`

## 5. Integrate SonarQube with Jenkins
### Generate SonarQube Token
1. In SonarQube, go to **Administration** > **Security** > **Users**.
2. Click on the admin user.
3. Under **Tokens**, click **Generate Token**.
4. **Name**: `Token for Jenkins`
5. Click **Generate** and copy the token (save it securely).

### Add Credentials in Jenkins
1. In Jenkins, go to **Manage Jenkins** > **Manage Credentials**.
2. Under **Stores scoped to Jenkins**, select **(global)**.
3. Click **Add Credentials**.
4. **Kind**: `Secret text`
5. **Secret**: Paste the SonarQube token.
6. **ID**: `SonarQube-Token`
7. **Description**: `SonarQube Token`
8. Click **Create**.

### Configure SonarQube Server in Jenkins
1. In Jenkins, go to **Manage Jenkins** > **Configure System**.
2. Scroll to **SonarQube servers**.
3. Click **Add SonarQube**.
4. **Name**: `SonarQube-Server`
5. **Server URL**: `http://<EC2-Public-IP>:9000`
6. **Server authentication token**: Select `SonarQube-Token` from the dropdown.
7. Click **Apply** and **Save**.

### Create Quality Gate in SonarQube
1. In SonarQube, go to **Quality Gates**.
2. Click **Create**.
3. **Name**: `SonarQube-Quality-Gate`
4. Configure the conditions as needed (e.g., add metrics like code coverage, bugs, etc.).
5. Click **Create**.

## 6. Create Webhook for SonarQube and Jenkins
1. In SonarQube, go to **Administration** > **Configuration** > **Webhooks**.
2. Click **Create**.
3. **Name**: `Jenkins`
4. **URL**: `http://<EC2-Public-IP>:8080/sonarqube-webhook/`
5. Click **Create**.

This webhook will notify Jenkins about SonarQube analysis results, enabling quality gate checks in your pipelines.

## 7. Create Jenkins Pipeline to Build and Push Docker Image to DockerHub

### Generate SonarQube Token for Project
1. In SonarQube dashboard, click **Manually**.
2. **Project Display Name**: `AutoStream`
3. **Project Key**: `AutoStream`
4. **Main Branch Name**: `Main`
5. Click **Setup**
6. Click **Locally**
7. Click **Generate**
8. Click **Continue** → Run analysis on your project (other) → What is your OS? (linux) → Command for execute the scanner

### Create Jenkins Pipeline
1. In Jenkins web UI, click **New Item**.
2. **Item name**: `AutoStream`
3. Select **Pipeline** → Click **OK**.
4. Under **General** → **Discard old builds**:
   - Check **Discard old builds**
   - **Max # of builds to keep**: `2`
5. Scroll to **Pipeline** section:
   - **Definition**: `Pipeline script`
   - Copy and paste the following pipeline script:

```groovy
pipeline {

    agent any

    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Gurus41/End-to-End-CI-CD-Pipeline-on-AWS.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh """
                    ${SCANNER_HOME}/bin/sonar-scanner \
                    -Dsonar.projectName=AutoStream \
                    -Dsonar.projectKey=AutoStream
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false,
                    credentialsId: 'SonarQube-Token'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs --severity HIGH,CRITICAL . > trivyfs.txt || true'
            }
        }
    }
}

```

Click on apply & save  Then Click on Build Now

Now we need configure our pipeline to build the Docker image and push that to Docker Hub

## 8. Configure DockerHub Integration

### Create DockerHub Access Token
1. Go to DockerHub → **Account Settings** → **PersonalAccessToken** → **New Access Token**.
2. Create a new access token with appropriate permissions.

### Add DockerHub Credentials to Jenkins
1. In Jenkins web UI → **Manage Jenkins** → **Credentials** → **System** → **Global Credentials** → **Add Credentials**.
2. Configure as follows:
   - **Kind**: `Username with password`
   - **Username**: Your DockerHub username
   - **Password**: Paste the DockerHub token
   - **ID**: `dockerhub`
   - **Description**: `DockerHub`
3. Click **Create**.

### Update Pipeline with Docker Stages
1. Go to your project → **Configure**.
2. Update the pipeline script to include Docker stages:

```groovy
pipeline {

    agent any

    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        IMAGE_NAME = "gurus41/autostream-cicd-pipeline"
        IMAGE_TAG  = "latest"
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Gurus41/End-to-End-CI-CD-Pipeline-on-AWS.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh """
                    ${SCANNER_HOME}/bin/sonar-scanner \
                    -Dsonar.projectName=AutoStream \
                    -Dsonar.projectKey=AutoStream
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false,
                    credentialsId: 'SonarQube-Token'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs . > trivyfs.txt || true'
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub', toolName: 'docker') {

                        sh """
                        docker build -t autostream .
                        docker tag autostream ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        """
                    }
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image ${IMAGE_NAME}:${IMAGE_TAG} > trivyimage.txt || true'
            }
        }
    }
}


```

Click on apply & save  Then Click on Build Now

# Now we move to Monitoring tools (Prometheus & Grafana)

For any issues, refer to the official documentation for [Jenkins](https://www.jenkins.io/doc/) and [SonarQube](https://docs.sonarsource.com/sonarqube/).
# Complete CI/CD Pipeline with Monitoring on AWS Stage 2

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Step-by-Step Implementation](#step-by-step-implementation)

## Overview
This guide provides a complete walkthrough for setting up a CI/CD pipeline with monitoring infrastructure on AWS. The setup includes:
- Monitoring server with Prometheus, Node Exporter, and Grafana
- Jenkins automation server integrated with Prometheus
- AWS EKS cluster for Kubernetes deployment
- Complete CI/CD pipeline from code commit to production deployment

## Prerequisites
- AWS account with appropriate permissions
- Basic understanding of Linux, Docker, Kubernetes, and AWS
- SSH client for accessing EC2 instances
- Git installed locally
- Docker Hub account (or other container registry)

## Architecture
```
Code Commit (GitHub) → Jenkins (CI/CD) → Docker Build/Push → EKS Deployment
      ↓                       ↓                  ↓               ↓
  SonarQube              Prometheus        Container Scan    Grafana Dashboard
      ↓                       ↓                  ↓               ↓
 Code Quality          Metrics Collection  Security Scan   Monitoring & Visualization
```

---

## Step-by-Step Implementation

### **Part 1: Setting Up Monitoring Server**

#### 1.1 Access Your Monitoring Server
```bash
# Connect to your EC2 instance using SSH
ssh -i your-key.pem ec2-user@YOUR-EC2-PUBLIC-IP
```

#### 1.2 Check Service Status
```bash
# Check Prometheus status
sudo systemctl status prometheus

# Check Node Exporter status (for system metrics)
sudo systemctl status node_exporter

# Check Grafana status (for visualization)
sudo systemctl status grafana-server
```

**Explanation**: 
- **Prometheus**: Time-series database for storing metrics
- **Node Exporter**: Collects system metrics (CPU, memory, disk, network)
- **Grafana**: Visualization tool for creating dashboards

#### 1.3 Configure Prometheus to Monitor the Server
1. **Access Prometheus Web UI**: Open `http://YOUR-EC2-IP:9090` in your browser
2. **Check Targets**: Go to Status → Targets to see what's being monitored
3. **Edit Prometheus Configuration**:
```bash
sudo vi /etc/prometheus/prometheus.yml
```

4. **Add Node Exporter Job** (append to the end of the file):
```yaml
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['YOUR-EC2-IP:9100']
        labels:
          instance: 'monitoring-server'
```

**Note**: 
- `localhost:9100` is where Node Exporter runs
- If monitoring other servers, use their IP:9100

5. **Validate Configuration**:
```bash
promtool check config /etc/prometheus/prometheus.yml
```

6. **Reload Prometheus**:
```bash
curl -X POST http://localhost:9090/-/reload
```

7. **Verify**: In Prometheus UI (Status → Targets), node_exporter should show as UP

#### 1.4 Set Up Grafana Dashboard
1. **Access Grafana**: Open `http://YOUR-EC2-IP:3000` in browser
   - Username: `admin`
   - Password: `admin` (change on first login)

2. **Add Prometheus as Data Source**:
   - Click "Datasource" → "Data Sources"
   - Click "Add data source"
   - Select "Prometheus"
   - URL: `http://YOUR-EC2-IP:9090`
   - Click "Save & Test" (should show "Data source is working")

3. **Import Dashboard for Server Monitoring**:
   - Click "+" → "Import"
   - Enter Dashboard ID: `1860` (Node Exporter Full dashboard)
   - Select Prometheus data source
   - Click "Import"

**Result**: You now have a complete monitoring dashboard showing CPU, memory, disk, and network metrics.

---

### **Part 2: Integrate Jenkins with Monitoring**

#### 2.1 Install Prometheus Plugin in Jenkins
1. **Navigate to Jenkins** → "Manage Jenkins" → "Plugins"
2. **Search for "Prometheus metrics"** and install
3. **Restart Jenkins** when prompted

#### 2.2 Configure Jenkins for Prometheus
1. Go to "Manage Jenkins" → "System"
2. Find "Prometheus" section
3. Check "Enable Prometheus" and "Add build status labels to metrics" & "Add build status label to metrics"
4. Set "Default namespace" to `jenkins`
5. Click "Save"

#### 2.3 Configure Prometheus to Scrape Jenkins
1. **Edit Prometheus configuration**:
```bash
sudo vi /etc/prometheus/prometheus.yml
```

2. **Add Jenkins Job**:
```yaml
  - job_name: 'jenkins'
    metrics_path: '/prometheus'
    static_configs:
      - targets: ['JENKINS-SERVER-IP:8080']
        labels:
          application: 'jenkins'
```

3. **Validate and Reload**:
```bash
promtool check config /etc/prometheus/prometheus.yml
curl -X POST http://localhost:9090/-/reload
```

4. **Verify**: In Prometheus UI, check Status → Targets for Jenkins

#### 2.4 Add Jenkins Dashboard to Grafana
1. **Import Jenkins Dashboard**:
   - In Grafana, click "+" → "Import"
   - Enter Dashboard ID: `9964` (Jenkins Performance and Health Overview)
   - Select Prometheus data source
   - Click "Import"

2. **Test Integration**:
   - Run a Jenkins job
   - Check Grafana dashboard for updated metrics
  
3. **SetupEmail Notification Through Jenkins**
   - 

---

### **Part 3: Set Up AWS EKS Cluster**

#### 3.1 Install Required Tools on Jenkins Server
```bash
# Update system
sudo apt update

# Install kubectl (Kubernetes CLI)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install
aws --version

# Install eksctl (EKS management tool)
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

#### 3.2 Configure AWS Credentials
```bash
aws configure
# Enter your AWS Access Key, Secret Key, Region (ap-south-1), and output format (json)
```

#### 3.3 Create EKS Cluster
```bash
eksctl create cluster \
  --name EndtoEndCICDPipeline-cluster \
  --region ap-south-1 \
  --nodegroup-name standard-workers \
  --node-type t2.small \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed
```

**Note**: Cluster creation takes 10-15 minutes

#### 3.4 Verify Cluster
```bash
# Check nodes
kubectl get nodes

# Check services
kubectl get svc
```

---

### **Part 4: Install Prometheus on EKS**

#### 4.1 Install Helm
```bash
# Method 1 (using snap)
sudo snap install helm --classic

# Method 2 (using script)
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm version
```

#### 4.2 Install Prometheus Stack
```bash
# Add Helm repositories
helm repo add stable https://charts.helm.sh/stable
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create namespace for Prometheus
kubectl create namespace prometheus

# Install Prometheus Stack
helm install prometheus prometheus-community/kube-prometheus-stack -n prometheus

# Verify installation
kubectl get pods -n prometheus
kubectl get svc -n prometheus
```

#### 4.3 Expose Prometheus Service
```bash
# Edit Prometheus service to use LoadBalancer
kubectl edit svc prometheus-kube-prometheus-prometheus -n prometheus
```

Change `type: ClusterIP` to `type: LoadBalancer` 
Change port & targetport to `9090` and save.

**Wait 2-3 minutes**, then check:
```bash
kubectl get svc -n prometheus
```

Note the LoadBalancer URL (EXTERNAL-IP).

#### 4.4 Add EKS Prometheus to Grafana
1. In Grafana: "Configuration" → "Data Sources" → "Add data source"
2. Select "Prometheus"
3. Name: `prometheus-eks`
4. URL: `http://LOADBALANCER-IP:9090`
5. Click "Save & Test"

#### 4.5 Import EKS Monitoring Dashboard
1. In Grafana: "+" → "Import"
2. Use Dashboard ID: `15760 or 17119` (Kubernetes Cluster Monitoring)
3. Select `prometheus-eks` as data source
4. Click "Import"

---

### **Part 5: Configure Jenkins Pipeline for EKS Deployment**

#### 5.1 Install Kubernetes Plugins in Jenkins
1. Go to Jenkins → "Manage Jenkins" → "Plugins"
2. Install these plugins:
   - Kubernetes
   - Kubernetes CLI
   - Kubernetes Credentials
   - Docker Pipeline

#### 5.2 Configure Kubernetes Credentials
```bash
# On Jenkins server, get kubeconfig
cat ~/.kube/config
# Copy the content and save as 'kubeconfig.txt'
```

1. In Jenkins: "Manage Jenkins" → "Credentials" → "System" → "Global credentials"
2. Click "Add Credentials":
   - Kind: "Secret file"
   - File: Upload `kubeconfig.txt`
   - ID: `k8s-config`
   - Description: "Kubernetes Configuration"
3. In Jenkins, go to `AutoStream` → Configurat → Pipeline syntex
   - Click on sample steps
   - Select: withkubeconfig: Configure kubernetes CLI(kubectl)
   - Kind: Secret file
   - Credentials : Upload your kubeconfig.txt
   - Generate Pipeline Script
   - copy: Genrate script
   - Add that to the Jenkins pipeline

#### 5.3 Create Jenkins Pipeline
Create a new Pipeline job with this script:

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
        IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT_SHORT}"
        SONAR_PROJECT_KEY = "AutoStream"
        SONAR_PROJECT_NAME = "AutoStream"
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
                    url: 'https://github.com/Gurus41/End-to-End-CI-CD-Pipeline-on-AWS.git',
                    poll: false
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh """
                    ${SCANNER_HOME}/bin/sonar-scanner \
                    -Dsonar.projectName=${SONAR_PROJECT_NAME} \
                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                    -Dsonar.sources=. \
                    -Dsonar.projectBaseDir=. \
                    -Dsonar.host.url=\${SONAR_HOST_URL} \
                    -Dsonar.login=\${SONAR_AUTH_TOKEN}
                    """
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: true,
                        credentialsId: 'SonarQube-Token'
                }
            }
        }
        
        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs . --severity HIGH,CRITICAL --exit-code 0 > trivyfs.txt || true'
            }
        }
        
        stage('Docker Build & Push') {
            steps {
                script {
                    // Check if Docker is available
                    sh 'docker --version'
                    
                    withDockerRegistry(credentialsId: 'dockerhub', toolName: 'docker') {
                        sh """
                        # Build the Docker image with multiple tags
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest .
                        
                        # Push both tags to Docker Hub
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                        """
                    }
                }
            }
        }
        
        stage('Trivy Image Scan') {
            steps {
                sh """
                trivy image ${IMAGE_NAME}:${IMAGE_TAG} \
                  --severity HIGH,CRITICAL \
                  --exit-code 0 > trivyimage.txt || true
                """
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Check if Kubernetes directory exists
                    sh '''
                    if [ -d "Kubernetes" ]; then
                        echo "Kubernetes directory found"
                        ls -la Kubernetes/
                    else
                        echo "WARNING: Kubernetes directory not found"
                    fi
                    '''
                    
                    // Deploy using kubeconfig credentials
                    withKubeConfig([credentialsId: 'k8s-config']) {
                        dir('Kubernetes') {
                            sh '''
                            # Apply Kubernetes manifests
                            if [ -f "deployment.yml" ]; then
                                kubectl apply -f deployment.yml
                            else
                                echo "ERROR: deployment.yml not found"
                            fi
                            
                            if [ -f "service.yml" ]; then
                                kubectl apply -f service.yml
                            fi
                            
                            # Check rollout status
                            kubectl rollout status deployment/autostream-app --timeout=300s
                            
                            # Display deployment info
                            kubectl get deployments,services,pods
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                script {
                    sh '''
                    # Remove local Docker images to save space
                    docker rmi ${IMAGE_NAME}:${IMAGE_TAG} 2>/dev/null || true
                    docker rmi ${IMAGE_NAME}:latest 2>/dev/null || true
                    docker image prune -f 2>/dev/null || true
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo "Pipeline completed: ${currentBuild.result}"
            
            // Archive security scan reports
            archiveArtifacts artifacts: '**/*.txt', allowEmptyArchive: true
            
            // Email notification
            emailext(
                subject: "[${currentBuild.result}] ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: """
                <html>
                <body>
                <h2>Build Notification</h2>
                <p><b>Project:</b> ${env.JOB_NAME}</p>
                <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                <p><b>Status:</b> ${currentBuild.result}</p>
                <p><b>Build URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                <p><b>Image:</b> ${IMAGE_NAME}:${IMAGE_TAG}</p>
                <p><b>Commit:</b> ${env.GIT_COMMIT ?: 'N/A'}</p>
                </body>
                </html>
                """,
                to: 'your-email@gmail.com',
                attachmentsPattern: 'trivyfs.txt,trivyimage.txt',
                mimeType: 'text/html'
            )
        }
        success {
            echo "Pipeline succeeded!"
        }
        failure {
            echo "Pipeline failed!"
        }
        cleanup {
            cleanWs()
        }
    }
}
```
We need generate the Commmand for the Kubernets



#### 5.4 Configure GitHub Webhook
1. **In Jenkins Job**:
   - Configure → "Build Triggers"
   - Check "GitHub hook trigger for GITScm polling"

2. **In GitHub Repository**:
   - Settings → Webhooks → Add webhook
   - Payload URL: `http://JENKINS-IP:8080/github-webhook/`
   - Content type: `application/json`
   - Which events: "Just the push event"
   - Add webhook

3. **Test**: Make a change in GitHub, Jenkins should auto-trigger

---

### **Part 6: Cleanup Commands**

#### 6.1 Clean EKS Resources
```bash
# Delete Prometheus namespace
kubectl delete namespace prometheus

# Delete application resources
kubectl delete -f deployment.yml
kubectl delete -f service.yml

# Delete EKS cluster
eksctl delete cluster --region=ap-south-1 --name=EndtoEndCICDPipeline-cluster
```

#### 6.2 Clean EC2 Instances
```bash
# Stop services
sudo systemctl stop prometheus node_exporter grafana-server

# Uninstall services (Ubuntu/Debian)
sudo apt remove --purge prometheus node_exporter grafana
```

#### 6.3 Terraform Cleanup (if used)
```bash
terraform destroy -auto-approve
```

---

## Troubleshooting Guide

### Common Issues and Solutions

1. **Prometheus not starting**:
   ```bash
   # Check logs
   sudo journalctl -u prometheus -f
   
   # Check configuration
   promtool check config /etc/prometheus/prometheus.yml
   ```

2. **Node Exporter metrics not showing**:
   ```bash
   # Check if port 9100 is open
   sudo netstat -tulpn | grep 9100
   
   # Check firewall
   sudo ufw allow 9100
   ```

3. **EKS cluster creation fails**:
   ```bash
   # Check CloudFormation events
   aws cloudformation describe-stack-events --stack-name eksctl-EndtoEndCICDPipeline-cluster
   
   # Check IAM permissions
   aws sts get-caller-identity
   ```

4. **Jenkins pipeline fails on kubectl**:
   ```bash
   # Test kubectl connection
   kubectl get nodes
   
   # Check kubeconfig
   kubectl config view
   ```

5. **Grafana login issues**:
   ```bash
   # Reset admin password
   sudo grafana-cli admin reset-admin-password newpassword
   ```

## Security Best Practices

1. **Change default passwords** (Grafana, Jenkins)
2. **Use IAM roles** instead of access keys
3. **Enable HTTPS** for all services
4. **Restrict SSH access** to specific IPs
5. **Regularly update** all software
6. **Use secrets management** for sensitive data
7. **Enable AWS CloudTrail** for auditing
8. **Implement network policies** in EKS

## Monitoring Checklist

- [ ] Prometheus targets show UP status
- [ ] Node Exporter metrics visible in Grafana
- [ ] Jenkins build metrics captured
- [ ] EKS cluster metrics available
- [ ] All dashboards showing data
- [ ] Alerts configured for critical issues
- [ ] Email notifications working
- [ ] Log aggregation in place

## Cost Optimization Tips

1. Use `t2/t3.small` for non-production
2. Implement auto-scaling for EKS nodes
3. Use Spot Instances for worker nodes
4. Schedule non-critical resources
5. Clean up unused resources regularly
6. Monitor AWS Cost Explorer

## Next Steps

1. **Implement Blue-Green Deployment** for zero-downtime updates
2. **Add Security Scanning** in CI/CD pipeline
3. **Implement Canary Deployments** for gradual rollouts
4. **Set up Logging** with ELK stack
5. **Configure Alerting** in Prometheus/Grafana
6. **Implement Backup Strategy** for EKS
7. **Add Performance Testing** in pipeline
8. **Set up Disaster Recovery** plan

---

## Support

For issues or questions:
1. Check service logs: `sudo journalctl -u SERVICE_NAME -f`
2. Verify network connectivity
3. Check AWS service limits
4. Review IAM permissions
5. Consult AWS documentation

**Remember**: Always test in staging before production deployment!

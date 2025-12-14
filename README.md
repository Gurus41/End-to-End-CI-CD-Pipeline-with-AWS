# End-to-End CI/CD Pipeline on AWS

Welcome to this comprehensive guide for setting up an **End-to-End CI/CD Pipeline on AWS**! This project demonstrates how to build, test, and deploy applications using popular DevOps tools like Jenkins, SonarQube, Docker, and Kubernetes on AWS.

Whether you're a beginner or looking to refresh your knowledge, this guide is designed to be easy to follow and educational. We'll walk through each step with clear explanations, so you can learn while building a real-world pipeline.

![alt text](<CI-CD pipeline.png>)

## 🚀 What You'll Learn
- Setting up Jenkins and SonarQube on AWS EC2
- Integrating code quality checks with SonarQube
- Building and pushing Docker images to Docker Hub
- Deploying applications to Kubernetes on AWS EKS
- Monitoring with Prometheus and Grafana
- Best practices for CI/CD pipelines

## 📁 Project Structure
This repository is organized into the following folders:

- **`End-T-End CICD Pipeline/`**: The main application code (a React app) that we'll build and deploy.
- **`Jenkins-SonarQube-VM/`**: Terraform scripts and setup guide for provisioning an EC2 instance with Jenkins and SonarQube.
- **`Monitoring-server/`**: Terraform configuration for setting up Prometheus and Grafana for monitoring.

## 🛠 Prerequisites
Before starting, make sure you have:
- An AWS account with appropriate permissions
- Basic knowledge of AWS services (EC2, EKS, etc.)
- Familiarity with Docker and Kubernetes concepts
- A GitHub account (for cloning repositories)

## 📋 Quick Start Guide

### 1. Set Up Your AWS Environment
Use the Terraform scripts in `Jenkins-SonarQube-VM/` to create an EC2 instance with Jenkins and SonarQube pre-installed.

### 2. Configure Jenkins and SonarQube
Follow the detailed steps in `Jenkins-SonarQube-VM/Readme.md` to:
- Access Jenkins and SonarQube web UIs
- Install necessary plugins
- Configure tools and integrations

### 3. Create Your CI/CD Pipeline
Use the Jenkins pipeline script provided to:
- Run code analysis with SonarQube
- Build and push Docker images
- Perform security scans with Trivy

### 4. Deploy to Kubernetes
Deploy your application to AWS EKS using the Kubernetes manifests in `End-T-End CICD Pipeline/Kubernetes/`.

### 5. Set Up Monitoring
Configure Prometheus and Grafana using the scripts in `Monitoring-server/` to monitor your pipeline and applications.

## 🔗 Detailed Guides
For step-by-step instructions, refer to these guides:

- **[Jenkins and SonarQube Setup](Jenkins-SonarQube-VM/Readme.md)**: Complete guide for installing and configuring Jenkins and SonarQube on AWS.
- **[Application README](End-T-End CICD Pipeline/README.md)**: Details about the sample React application.

## 🏗️ Architecture Overview
```
GitHub Repo → Jenkins → SonarQube Analysis → Docker Build → Docker Hub → Kubernetes Deployment → Monitoring
```

## 📚 Learning Resources
- [Jenkins Official Documentation](https://www.jenkins.io/doc/)
- [SonarQube Documentation](https://docs.sonarsource.com/sonarqube/)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contributing
Feel free to open issues or submit pull requests if you find ways to improve this guide!

## 📄 License
This project is for educational purposes. Please check individual tool licenses for production use.

---

Happy learning! If you get stuck, don't hesitate to ask questions or refer to the official documentation. Remember, DevOps is about continuous improvement – keep experimenting and learning! 🎉

3. **EKS cluster creation fails**:

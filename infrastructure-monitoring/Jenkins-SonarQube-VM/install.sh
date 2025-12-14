#!/bin/bash
set -e

echo "=============================="
echo "Installing Jenkins + SonarQube + Docker + Trivy"
echo "=============================="

####################################
# Update system
####################################
sudo apt update -y

####################################
# Install Java 17 (Temurin)
####################################
sudo mkdir -p /etc/apt/keyrings

wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public \
  | sudo tee /etc/apt/keyrings/adoptium.asc > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] \
https://packages.adoptium.net/artifactory/deb \
$(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" \
| sudo tee /etc/apt/sources.list.d/adoptium.list

sudo apt update -y
sudo apt install temurin-17-jdk -y

java --version

####################################
# Install Jenkins
####################################
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" \
| sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install jenkins -y

sudo systemctl enable jenkins
sudo systemctl start jenkins

####################################
# Install Docker
####################################
sudo apt install docker.io -y

sudo systemctl enable docker
sudo systemctl start docker

####################################
# Add users to Docker group
####################################
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins

sudo chmod 666 /var/run/docker.sock

####################################
# Run SonarQube (Docker Container)
####################################
docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  sonarqube:lts-community

####################################
# Install Trivy
####################################
sudo apt install wget apt-transport-https gnupg lsb-release -y

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
https://aquasecurity.github.io/trivy-repo/deb \
$(lsb_release -sc) main" \
| sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt update -y
sudo apt install trivy -y

####################################
# Status Checks
####################################
echo "=============================="
echo "Installation Completed"
echo "=============================="

systemctl status jenkins --no-pager
systemctl status docker --no-pager

docker ps

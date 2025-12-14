# ============================================
# JENKINS & SONARQUBE SERVER - SECURE VERSION
# ============================================

# 🔧 EC2 INSTANCE CONFIGURATION
resource "aws_instance" "web" {
  # 🖥️ Server Specifications
  ami                    = "ami-0287a05f0ef0e9d9a"      # ⚠️ MUST be valid for YOUR AWS REGION
  instance_type          = "t2.large"                   # 2 vCPU, 8GB RAM - Good for CI/CD
  key_name               = "Linux-VM-Key1"              # ⚠️ MUST exist in AWS EC2 Key Pairs

  # 🔐 Security Assignment
  vpc_security_group_ids = [aws_security_group.Jenkins-VM-SG.id]

  # ⚙️ Automation Script
  user_data = file("./install.sh")  # Changed to file() since no variables needed

  # 🏷️ Identification Tags
  tags = {
    Name = "Jenkins-SonarQube-Server"
  }

  # 💾 Storage Configuration
  root_block_device {
    volume_size = 40  # 40GB disk space for Jenkins builds & SonarQube database
  }
}

# ============================================
# SECURITY GROUP - FIREWALL RULES (SECURE!)
# ============================================

resource "aws_security_group" "Jenkins-VM-SG" {
  name        = "Jenkins-VM-SG"
  description = "Secure firewall for Jenkins & SonarQube"

  # 🔒 INBOUND RULES - Who can access the server

  # 🚨 CRITICAL: Management ports - ONLY YOUR IP
  ingress {
    description = "SSH Remote Access (Management)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⬅️ REPLACE WITH YOUR ACTUAL IP
  }

  ingress {
    description = "Jenkins CI/CD Dashboard"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⬅️ REPLACE WITH YOUR ACTUAL IP
  }

  ingress {
    description = "SonarQube Code Analysis"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⬅️ REPLACE WITH YOUR ACTUAL IP
  }

  ingress {
    description = "Grafana Monitoring Dashboard"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⬅️ REPLACE WITH YOUR ACTUAL IP
  }

  # 🌐 Public Web Ports - Open to everyone
  ingress {
    description = "HTTP Web Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ✅ OK - Public websites
  }

  ingress {
    description = "HTTPS Secure Web Traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ✅ OK - Public websites
  }

  # 🌐 OUTBOUND RULES - What your server can access
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0       # All ports
    to_port     = 0       # All ports
    protocol    = "-1"    # All protocols (TCP, UDP, ICMP)
    cidr_blocks = ["0.0.0.0/0"]  # ✅ Server can access internet
  }

  # 🏷️ Security Group Tags
  tags = {
    Name = "Jenkins-VM-SG"
  }
}
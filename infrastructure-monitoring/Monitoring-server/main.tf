# ============================================
# MONITORING SERVER - EC2 INSTANCE
# ============================================

resource "aws_instance" "monitoring_server" {
  # Server Configuration
  ami           = "ami-0287a05f0ef0e9d9a"  # ⚠️ Change for your region
  instance_type = "t2.medium"
  key_name      = "Linux-VM-Key1"          # ⚠️ Must exist in AWS

  # Security & Networking
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]

  # Startup Script (runs when server starts)
  user_data = file("./install.sh")  # Your setup script

  # Tags for Organization
  tags = {
    Name        = "Monitoring-Server"
    Purpose     = "CI/CD Pipeline Monitoring"
    Managed-By  = "Terraform"
  }

  # Storage Configuration
  root_block_device {
    volume_size = 20  # 20GB disk space
    volume_type = "gp3"  # Fast SSD
  }
}

# ============================================
# SECURITY GROUP - FIREWALL RULES
# ============================================

resource "aws_security_group" "monitoring_sg" {
  name        = "monitoring-server-sg"
  description = "Security rules for monitoring server"

  # ========== INBOUND RULES (What can access server) ==========

  # 🔐 SSH ACCESS - Only from your IP (Management)
  ingress {
    description = "SSH Remote Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⚠️ REPLACE WITH YOUR IP!
  }

  # 🌐 WEB ACCESS - Open to public (if needed)
  ingress {
    description = "HTTP Web Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Anyone can access website
  }

  ingress {
    description = "HTTPS Secure Web"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Anyone can access secure website
  }

  # 📊 MONITORING TOOLS - Only from your IP (NOT public!)
  ingress {
    description = "Prometheus Metrics"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⚠️ REPLACE WITH YOUR IP!
  }

  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⚠️ REPLACE WITH YOUR IP!
  }

  ingress {
    description = "Grafana Dashboard"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⚠️ REPLACE WITH YOUR IP!
  }

  # ========== OUTBOUND RULES (What server can access) ==========

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # Can connect to anywhere
  }

  # Tags
  tags = {
    Name = "monitoring-firewall"
  }
}
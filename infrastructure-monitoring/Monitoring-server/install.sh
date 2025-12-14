#!/bin/bash
set -e

echo "=============================="
echo "Updating system"
echo "=============================="
sudo apt update -y
sudo apt install -y wget curl apt-transport-https software-properties-common

# ---------------------------------------------------
# Install Prometheus
# ---------------------------------------------------
echo "=============================="
echo "Installing Prometheus"
echo "=============================="

sudo useradd --system --no-create-home --shell /bin/false prometheus || true

cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.47.1/prometheus-2.47.1.linux-amd64.tar.gz
tar -xvf prometheus-2.47.1.linux-amd64.tar.gz

sudo mkdir -p /etc/prometheus /data
sudo mv prometheus-2.47.1.linux-amd64/prometheus /usr/local/bin/
sudo mv prometheus-2.47.1.linux-amd64/promtool /usr/local/bin/
sudo mv prometheus-2.47.1.linux-amd64/consoles /etc/prometheus/
sudo mv prometheus-2.47.1.linux-amd64/console_libraries /etc/prometheus/
sudo mv prometheus-2.47.1.linux-amd64/prometheus.yml /etc/prometheus/

sudo chown -R prometheus:prometheus /etc/prometheus /data

sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/data \
  --web.listen-address=0.0.0.0:9090

Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# ---------------------------------------------------
# Install Node Exporter
# ---------------------------------------------------
echo "=============================="
echo "Installing Node Exporter"
echo "=============================="

sudo useradd --system --no-create-home --shell /bin/false node_exporter || true

cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz

sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/

sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# ---------------------------------------------------
# Install Grafana (FIXED)
# ---------------------------------------------------
echo "=============================="
echo "Installing Grafana"
echo "=============================="

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.grafana.com/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/grafana.gpg

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" \
| sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt update -y
sudo apt install -y grafana

sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# ---------------------------------------------------
# Service Status
# ---------------------------------------------------
echo "=============================="
echo "Checking services status"
echo "=============================="

sudo systemctl status prometheus --no-pager
sudo systemctl status node_exporter --no-pager
sudo systemctl status grafana-server --no-pager

echo "=============================="
echo "Installation Completed"
echo "Prometheus : http://<EC2-IP>:9090"
echo "Grafana    : http://<EC2-IP>:3000 (admin/admin)"
echo "NodeExp    : http://<EC2-IP>:9100"
echo "=============================="

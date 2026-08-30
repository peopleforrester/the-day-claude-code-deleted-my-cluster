#!/bin/bash
# ABOUTME: Install containerd 2.1.4 exactly as specified
# ABOUTME: Downloads from official GitHub releases and configures for Kubernetes

set -euo pipefail

LOG_DIR="logs/03-containerd"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
INSTALL_LOG="$LOG_DIR/install-$TIMESTAMP.log"
VERSION_LOG="$LOG_DIR/versions-$TIMESTAMP.log"

ALL_NODES=("192.168.0.50" "192.168.0.51" "192.168.0.52" "192.168.0.53" "192.168.0.54" "192.168.0.55" "192.168.0.56" "192.168.0.57" "192.168.0.58")
NODE_NAMES=("k8s01" "k8s02" "k8s03" "k8s04" "k8s05" "k8s06" "k8s07" "k8s08" "k8s09")

# Exact version to install
CONTAINERD_VERSION="2.1.4"
RUNC_VERSION="1.2.4"

echo "Installing containerd $CONTAINERD_VERSION on all nodes" | tee "$INSTALL_LOG"
echo "================================================" | tee -a "$INSTALL_LOG"

# Function to install containerd on a node
install_containerd() {
    local ip=$1
    local name=$2
    
    echo "" | tee -a "$INSTALL_LOG"
    echo "Installing on $name ($ip)..." | tee -a "$INSTALL_LOG"
    echo "------------------------" | tee -a "$INSTALL_LOG"
    
    # Install prerequisites
    echo "Installing prerequisites..." | tee -a "$INSTALL_LOG"
    ssh root@$ip "apt-get update && apt-get install -y wget tar" >/dev/null 2>&1
    
    # Download containerd 2.1.4
    echo "Downloading containerd $CONTAINERD_VERSION..." | tee -a "$INSTALL_LOG"
    ssh root@$ip "cd /tmp && wget -q https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz" 2>&1 | tee -a "$INSTALL_LOG"
    
    # Extract containerd
    echo "Extracting containerd..." | tee -a "$INSTALL_LOG"
    ssh root@$ip "tar -C /usr/local -xzf /tmp/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz" 2>&1 | tee -a "$INSTALL_LOG"
    
    # Download runc
    echo "Downloading runc $RUNC_VERSION..." | tee -a "$INSTALL_LOG"
    ssh root@$ip "wget -q -O /usr/local/sbin/runc https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64 && chmod +x /usr/local/sbin/runc" 2>&1 | tee -a "$INSTALL_LOG"
    
    # Download CNI plugins
    echo "Downloading CNI plugins..." | tee -a "$INSTALL_LOG"
    ssh root@$ip "mkdir -p /opt/cni/bin && cd /opt/cni/bin && wget -q https://github.com/containernetworking/plugins/releases/download/v1.6.1/cni-plugins-linux-amd64-v1.6.1.tgz && tar -xzf cni-plugins-linux-amd64-v1.6.1.tgz && rm cni-plugins-linux-amd64-v1.6.1.tgz" 2>&1 | tee -a "$INSTALL_LOG"
    
    # Create containerd service
    echo "Creating containerd service..." | tee -a "$INSTALL_LOG"
    ssh root@$ip "cat > /etc/systemd/system/containerd.service <<EOF
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target dbus.service

[Service]
Type=notify
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=mixed
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF" 2>&1 | tee -a "$INSTALL_LOG"
    
    # Configure containerd for Kubernetes
    echo "Configuring containerd..." | tee -a "$INSTALL_LOG"
    ssh root@$ip "mkdir -p /etc/containerd && containerd config default > /etc/containerd/config.toml" 2>&1 | tee -a "$INSTALL_LOG"
    
    # Enable SystemdCgroup (required for Kubernetes)
    ssh root@$ip "sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml" 2>&1 | tee -a "$INSTALL_LOG"
    
    # Set sandbox image to match Kubernetes version
    ssh root@$ip "sed -i 's|sandbox_image = \".*\"|sandbox_image = \"registry.k8s.io/pause:3.10\"|g' /etc/containerd/config.toml" 2>&1 | tee -a "$INSTALL_LOG"
    
    # Reload and start containerd
    echo "Starting containerd service..." | tee -a "$INSTALL_LOG"
    ssh root@$ip "systemctl daemon-reload && systemctl enable --now containerd" 2>&1 | tee -a "$INSTALL_LOG"
    
    # Verify installation
    echo "Verifying installation..." | tee -a "$INSTALL_LOG"
    local version=$(ssh root@$ip "containerd --version" 2>/dev/null)
    echo "  Installed: $version" | tee -a "$INSTALL_LOG"
    echo "$name: $version" >> "$VERSION_LOG"
    
    # Configure crictl
    echo "Configuring crictl..." | tee -a "$INSTALL_LOG"
    ssh root@$ip "cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
EOF" 2>&1 | tee -a "$INSTALL_LOG"
    
    echo "✓ $name installation complete" | tee -a "$INSTALL_LOG"
}

# Install on all nodes
for i in "${!ALL_NODES[@]}"; do
    install_containerd "${ALL_NODES[$i]}" "${NODE_NAMES[$i]}"
done

echo "" | tee -a "$INSTALL_LOG"
echo "================================================" | tee -a "$INSTALL_LOG"
echo "containerd $CONTAINERD_VERSION installed on all nodes!" | tee -a "$INSTALL_LOG"
echo "Installation log: $INSTALL_LOG" | tee -a "$INSTALL_LOG"
echo "Version log: $VERSION_LOG" | tee -a "$INSTALL_LOG"
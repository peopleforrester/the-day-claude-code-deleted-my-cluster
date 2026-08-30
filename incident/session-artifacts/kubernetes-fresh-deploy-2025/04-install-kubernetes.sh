#!/bin/bash
# ABOUTME: Install Kubernetes 1.33.4 exactly on all nodes
# ABOUTME: Configures prerequisites and installs kubeadm, kubelet, kubectl

set -euo pipefail

LOG_DIR="logs/04-kubernetes"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
INSTALL_LOG="$LOG_DIR/install-$TIMESTAMP.log"

ALL_NODES=("192.168.0.50" "192.168.0.51" "192.168.0.52" "192.168.0.53" "192.168.0.54" "192.168.0.55" "192.168.0.56" "192.168.0.57" "192.168.0.58")
NODE_NAMES=("k8s01" "k8s02" "k8s03" "k8s04" "k8s05" "k8s06" "k8s07" "k8s08" "k8s09")

echo "Installing Kubernetes 1.33.4 on all nodes" | tee "$INSTALL_LOG"
echo "================================================" | tee -a "$INSTALL_LOG"

# Install on all nodes
for i in "${!ALL_NODES[@]}"; do
    NODE="${ALL_NODES[$i]}"
    NAME="${NODE_NAMES[$i]}"
    
    echo "" | tee -a "$INSTALL_LOG"
    echo "=== Installing on $NAME ($NODE) ===" | tee -a "$INSTALL_LOG"
    
    # Prerequisites
    ssh root@$NODE "modprobe overlay && modprobe br_netfilter" 2>&1 | tee -a "$INSTALL_LOG"
    
    ssh root@$NODE "cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF" 2>&1 | tee -a "$INSTALL_LOG"
    
    ssh root@$NODE "sysctl --system >/dev/null 2>&1" && echo "✓ Sysctl configured" | tee -a "$INSTALL_LOG"
    
    # Disable swap
    ssh root@$NODE "swapoff -a && sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab" 2>&1 | tee -a "$INSTALL_LOG"
    echo "✓ Swap disabled" | tee -a "$INSTALL_LOG"
    
    # Install packages
    ssh root@$NODE "apt-get update >/dev/null 2>&1 && apt-get install -y apt-transport-https ca-certificates curl gpg >/dev/null 2>&1" && echo "✓ Prerequisites installed" | tee -a "$INSTALL_LOG"
    
    # Add Kubernetes GPG key
    ssh root@$NODE "mkdir -p /etc/apt/keyrings && curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null" && echo "✓ GPG key added" | tee -a "$INSTALL_LOG"
    
    # Add Kubernetes repository
    ssh root@$NODE 'echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" > /etc/apt/sources.list.d/kubernetes.list' && echo "✓ Repository added" | tee -a "$INSTALL_LOG"
    
    # Install Kubernetes 1.33.4
    ssh root@$NODE "apt-get update >/dev/null 2>&1 && apt-get install -y kubelet=1.33.4-1.1 kubeadm=1.33.4-1.1 kubectl=1.33.4-1.1 >/dev/null 2>&1" && echo "✓ Kubernetes 1.33.4 installed" | tee -a "$INSTALL_LOG"
    
    # Hold packages
    ssh root@$NODE "apt-mark hold kubelet kubeadm kubectl >/dev/null 2>&1" && echo "✓ Packages held" | tee -a "$INSTALL_LOG"
    
    # Configure crictl
    ssh root@$NODE "cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
EOF" && echo "✓ Crictl configured" | tee -a "$INSTALL_LOG"
    
    # Enable kubelet
    ssh root@$NODE "systemctl enable kubelet" >/dev/null 2>&1 && echo "✓ Kubelet enabled" | tee -a "$INSTALL_LOG"
    
    # Verify
    VERSION=$(ssh root@$NODE "kubeadm version -o short" 2>/dev/null)
    echo "✓ Installed: $VERSION" | tee -a "$INSTALL_LOG"
done

echo "" | tee -a "$INSTALL_LOG"
echo "================================================" | tee -a "$INSTALL_LOG"
echo "Kubernetes 1.33.4 installed on all nodes!" | tee -a "$INSTALL_LOG"
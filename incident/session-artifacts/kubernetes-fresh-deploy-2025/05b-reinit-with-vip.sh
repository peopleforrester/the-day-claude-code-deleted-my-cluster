#!/bin/bash
# ABOUTME: Re-initialize control plane with proper VIP configuration
# ABOUTME: Sets up k8s01 with controlPlaneEndpoint for HA

set -euo pipefail

LOG_DIR="logs/05b-reinit"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
INIT_LOG="$LOG_DIR/reinit-$TIMESTAMP.log"

FIRST_MASTER="192.168.0.50"
VIP="192.168.0.199"

echo "Re-initializing control plane with VIP endpoint" | tee "$INIT_LOG"
echo "================================================" | tee -a "$INIT_LOG"

# First reset the current cluster
echo "Resetting current cluster..." | tee -a "$INIT_LOG"
ssh root@$FIRST_MASTER "kubeadm reset -f" 2>&1 | tee -a "$INIT_LOG"
ssh root@$FIRST_MASTER "rm -rf /etc/kubernetes /var/lib/etcd" 2>&1 | tee -a "$INIT_LOG"
echo "✓ Reset complete" | tee -a "$INIT_LOG"

# Create kubeadm config with VIP as control plane endpoint
echo "Creating kubeadm configuration with VIP..." | tee -a "$INIT_LOG"
ssh root@$FIRST_MASTER "cat > /tmp/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: $FIRST_MASTER
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///run/containerd/containerd.sock
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: v1.33.4
controlPlaneEndpoint: '$VIP:6443'
networking:
  serviceSubnet: '10.96.0.0/12'
  podSubnet: '10.244.0.0/16'
apiServer:
  certSANs:
  - '$VIP'
  - '$FIRST_MASTER'
  - '192.168.0.51'
  - '192.168.0.52'
  - 'k8s01'
  - 'k8s02'
  - 'k8s03'
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
containerRuntimeEndpoint: unix:///run/containerd/containerd.sock
EOF" 2>&1 | tee -a "$INIT_LOG"
echo "✓ Config created" | tee -a "$INIT_LOG"

# Initialize with upload-certs for HA
echo "Initializing cluster with upload-certs..." | tee -a "$INIT_LOG"
ssh root@$FIRST_MASTER "kubeadm init --config=/tmp/kubeadm-config.yaml --upload-certs" 2>&1 | tee -a "$INIT_LOG"

# Setup kubectl
echo "Configuring kubectl..." | tee -a "$INIT_LOG"
ssh root@$FIRST_MASTER "mkdir -p /root/.kube && cp -i /etc/kubernetes/admin.conf /root/.kube/config" 2>&1 | tee -a "$INIT_LOG"

# Copy kubeconfig locally
echo "Copying kubeconfig locally..." | tee -a "$INIT_LOG"
mkdir -p ~/.kube
scp root@$FIRST_MASTER:/etc/kubernetes/admin.conf ~/.kube/config

# Since we're using VIP, we need to temporarily point to the actual master
sed -i "s/$VIP/$FIRST_MASTER/g" ~/.kube/config

echo "" | tee -a "$INIT_LOG"
echo "================================================" | tee -a "$INIT_LOG"
echo "Control plane re-initialized with VIP endpoint!" | tee -a "$INIT_LOG"
echo "Note: VIP $VIP configured but not active yet (no kube-vip)" | tee -a "$INIT_LOG"
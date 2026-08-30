#!/bin/bash
# ABOUTME: Initialize first control plane node with kube-vip for HA
# ABOUTME: Sets up k8s01 as initial master with VIP 192.168.0.199

set -euo pipefail

LOG_DIR="logs/05-control-plane"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
INIT_LOG="$LOG_DIR/init-$TIMESTAMP.log"

FIRST_MASTER="192.168.0.50"
VIP="192.168.0.199"
INTERFACE="enp1s0"  # Primary network interface

echo "Initializing control plane on k8s01 with VIP $VIP" | tee "$INIT_LOG"
echo "================================================" | tee -a "$INIT_LOG"

# First, install kube-vip
echo "Installing kube-vip v1.0.0..." | tee -a "$INIT_LOG"
ssh root@$FIRST_MASTER "curl -sL https://github.com/kube-vip/kube-vip/releases/download/v1.0.0/kube-vip-linux-amd64.tar.gz -o /tmp/kube-vip.tar.gz" 2>&1 | tee -a "$INIT_LOG"
ssh root@$FIRST_MASTER "tar -xzf /tmp/kube-vip.tar.gz -C /tmp && mv /tmp/kube-vip /usr/local/bin/ && chmod +x /usr/local/bin/kube-vip" 2>&1 | tee -a "$INIT_LOG"
echo "✓ kube-vip installed" | tee -a "$INIT_LOG"

# Generate kube-vip manifest
echo "Generating kube-vip manifest..." | tee -a "$INIT_LOG"
ssh root@$FIRST_MASTER "KVVERSION=v1.0.0 kube-vip manifest pod \
    --interface $INTERFACE \
    --address $VIP \
    --controlplane \
    --services \
    --arp \
    --leaderElection > /etc/kubernetes/manifests/kube-vip.yaml" 2>&1 | tee -a "$INIT_LOG"
echo "✓ kube-vip manifest created" | tee -a "$INIT_LOG"

# Create kubeadm config
echo "Creating kubeadm configuration..." | tee -a "$INIT_LOG"
ssh root@$FIRST_MASTER "cat > /tmp/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: $FIRST_MASTER
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  kubeletExtraArgs:
    container-runtime-endpoint: unix:///run/containerd/containerd.sock
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: v1.33.4
controlPlaneEndpoint: '$VIP:6443'
networking:
  serviceSubnet: '10.96.0.0/12'
  podSubnet: '10.244.0.0/16'
  dnsDomain: 'cluster.local'
apiServer:
  certSANs:
  - '$VIP'
  - '192.168.0.50'
  - '192.168.0.51'
  - '192.168.0.52'
  - 'k8s01'
  - 'k8s02'
  - 'k8s03'
  extraArgs:
    authorization-mode: 'Node,RBAC'
controllerManager:
  extraArgs:
    bind-address: '0.0.0.0'
scheduler:
  extraArgs:
    bind-address: '0.0.0.0'
etcd:
  local:
    dataDir: '/var/lib/etcd'
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
bindAddress: '0.0.0.0'
clusterCIDR: '10.244.0.0/16'
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
containerRuntimeEndpoint: unix:///run/containerd/containerd.sock
EOF" 2>&1 | tee -a "$INIT_LOG"
echo "✓ kubeadm config created" | tee -a "$INIT_LOG"

# Initialize the cluster
echo "Initializing Kubernetes cluster..." | tee -a "$INIT_LOG"
ssh root@$FIRST_MASTER "kubeadm init --config=/tmp/kubeadm-config.yaml --upload-certs 2>&1" | tee -a "$INIT_LOG"

# Setup kubectl for root user
echo "Configuring kubectl..." | tee -a "$INIT_LOG"
ssh root@$FIRST_MASTER "mkdir -p /root/.kube && cp -i /etc/kubernetes/admin.conf /root/.kube/config && chown root:root /root/.kube/config" 2>&1 | tee -a "$INIT_LOG"
echo "✓ kubectl configured" | tee -a "$INIT_LOG"

# Copy kubeconfig locally
echo "Copying kubeconfig locally..." | tee -a "$INIT_LOG"
mkdir -p ~/.kube
scp root@$FIRST_MASTER:/etc/kubernetes/admin.conf ~/.kube/config
sed -i "s/$FIRST_MASTER/$VIP/g" ~/.kube/config
echo "✓ Local kubeconfig configured" | tee -a "$INIT_LOG"

# Verify cluster
echo "Verifying cluster status..." | tee -a "$INIT_LOG"
kubectl get nodes 2>&1 | tee -a "$INIT_LOG"

# Get join commands
echo "Generating join commands..." | tee -a "$INIT_LOG"
CERT_KEY=$(ssh root@$FIRST_MASTER "kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -1")
JOIN_TOKEN=$(ssh root@$FIRST_MASTER "kubeadm token create")
CA_HASH=$(ssh root@$FIRST_MASTER "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'")

cat > "$LOG_DIR/join-commands.txt" <<EOF
# Control Plane Join Command:
kubeadm join $VIP:6443 --token $JOIN_TOKEN --discovery-token-ca-cert-hash sha256:$CA_HASH --control-plane --certificate-key $CERT_KEY

# Worker Node Join Command:
kubeadm join $VIP:6443 --token $JOIN_TOKEN --discovery-token-ca-cert-hash sha256:$CA_HASH
EOF

echo "✓ Join commands saved to $LOG_DIR/join-commands.txt" | tee -a "$INIT_LOG"

echo "" | tee -a "$INIT_LOG"
echo "================================================" | tee -a "$INIT_LOG"
echo "Control plane initialized successfully!" | tee -a "$INIT_LOG"
echo "VIP: $VIP" | tee -a "$INIT_LOG"
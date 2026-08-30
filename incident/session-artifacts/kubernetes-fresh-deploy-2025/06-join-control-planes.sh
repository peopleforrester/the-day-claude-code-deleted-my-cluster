#!/bin/bash
# ABOUTME: Join additional control plane nodes k8s02 and k8s03
# ABOUTME: Creates HA control plane with multiple masters

set -euo pipefail

LOG_DIR="logs/06-control-planes"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
JOIN_LOG="$LOG_DIR/join-$TIMESTAMP.log"

# Control plane nodes to join
CONTROL_NODES=("192.168.0.51" "192.168.0.52")
NODE_NAMES=("k8s02" "k8s03")

# Join parameters from initial control plane
TOKEN="<REDACTED-KUBEADM-TOKEN>"
CA_HASH="5862d7151e76b4e9bf7153a38877feab0ba1f6c55517c9a7b1fa9acae433cbc3"
CERT_KEY="4955eea0e10dc530e7020a7ee72f7fe0e4d6e70af63332900e30e2f21cd1b5bd"
API_SERVER="192.168.0.50:6443"

echo "Joining additional control plane nodes" | tee "$JOIN_LOG"
echo "=======================================" | tee -a "$JOIN_LOG"

for i in "${!CONTROL_NODES[@]}"; do
    NODE="${CONTROL_NODES[$i]}"
    NAME="${NODE_NAMES[$i]}"
    
    echo "" | tee -a "$JOIN_LOG"
    echo "=== Joining $NAME ($NODE) ===" | tee -a "$JOIN_LOG"
    
    # Join as control plane
    echo "Executing kubeadm join..." | tee -a "$JOIN_LOG"
    ssh root@$NODE "kubeadm join $API_SERVER --token $TOKEN \
        --discovery-token-ca-cert-hash sha256:$CA_HASH \
        --control-plane \
        --certificate-key $CERT_KEY" 2>&1 | tee -a "$JOIN_LOG"
    
    # Setup kubectl
    echo "Configuring kubectl on $NAME..." | tee -a "$JOIN_LOG"
    ssh root@$NODE "mkdir -p /root/.kube && cp -i /etc/kubernetes/admin.conf /root/.kube/config && chown root:root /root/.kube/config" 2>&1 | tee -a "$JOIN_LOG"
    
    echo "✓ $NAME joined as control plane" | tee -a "$JOIN_LOG"
done

echo "" | tee -a "$JOIN_LOG"
echo "Verifying control plane status..." | tee -a "$JOIN_LOG"
kubectl get nodes -o wide | tee -a "$JOIN_LOG"

echo "" | tee -a "$JOIN_LOG"
echo "=======================================" | tee -a "$JOIN_LOG"
echo "Additional control planes joined successfully!" | tee -a "$JOIN_LOG"
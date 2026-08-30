#!/bin/bash
# ABOUTME: Join worker nodes k8s04-k8s09 to the cluster
# ABOUTME: Expands cluster capacity with 6 worker nodes

set -euo pipefail

LOG_DIR="logs/08-workers"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
JOIN_LOG="$LOG_DIR/join-$TIMESTAMP.log"

# Worker nodes to join
WORKER_NODES=("192.168.0.53" "192.168.0.54" "192.168.0.55" "192.168.0.56" "192.168.0.57" "192.168.0.58")
NODE_NAMES=("k8s04" "k8s05" "k8s06" "k8s07" "k8s08" "k8s09")

# Join parameters
TOKEN="<REDACTED-KUBEADM-TOKEN>"
CA_HASH="644dc6a8bec38b976b8515b228e2d3aeae8b33cae9a650ecb2c7193b87695042"
API_SERVER="192.168.0.199:6443"

echo "Joining worker nodes to cluster" | tee "$JOIN_LOG"
echo "================================" | tee -a "$JOIN_LOG"

for i in "${!WORKER_NODES[@]}"; do
    NODE="${WORKER_NODES[$i]}"
    NAME="${NODE_NAMES[$i]}"
    
    echo "" | tee -a "$JOIN_LOG"
    echo "=== Joining $NAME ($NODE) ===" | tee -a "$JOIN_LOG"
    
    # Join as worker
    echo "Executing kubeadm join..." | tee -a "$JOIN_LOG"
    ssh root@$NODE "kubeadm join $API_SERVER --token $TOKEN \
        --discovery-token-ca-cert-hash sha256:$CA_HASH" 2>&1 | tee -a "$JOIN_LOG"
    
    echo "✓ $NAME joined as worker" | tee -a "$JOIN_LOG"
    
    # Brief pause between joins
    sleep 5
done

echo "" | tee -a "$JOIN_LOG"
echo "Waiting for nodes to be ready..." | tee -a "$JOIN_LOG"
sleep 10

# Verify all nodes
echo "Verifying cluster status..." | tee -a "$JOIN_LOG"
kubectl get nodes -o wide 2>&1 | tee -a "$JOIN_LOG"

echo "" | tee -a "$JOIN_LOG"
echo "================================" | tee -a "$JOIN_LOG"
echo "Worker nodes joined successfully!" | tee -a "$JOIN_LOG"
#!/bin/bash
# ABOUTME: Install Longhorn storage latest stable version
# ABOUTME: Provides distributed storage for the cluster

set -euo pipefail

LOG_DIR="logs/09-longhorn"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
INSTALL_LOG="$LOG_DIR/install-$TIMESTAMP.log"

echo "Installing Longhorn storage latest stable" | tee "$INSTALL_LOG"
echo "==========================================" | tee -a "$INSTALL_LOG"

# Install prerequisites on all nodes
echo "Installing prerequisites on all nodes..." | tee -a "$INSTALL_LOG"
ALL_NODES=($(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'))
for NODE in "${ALL_NODES[@]}"; do
    echo "Installing on node $NODE..." | tee -a "$INSTALL_LOG"
    ssh root@$NODE "apt-get update >/dev/null 2>&1 && apt-get install -y open-iscsi nfs-common >/dev/null 2>&1" 2>&1 | tee -a "$INSTALL_LOG"
    ssh root@$NODE "systemctl enable --now iscsid" 2>&1 | tee -a "$INSTALL_LOG"
done
echo "✓ Prerequisites installed" | tee -a "$INSTALL_LOG"

# Get latest stable version
echo "Getting latest stable version..." | tee -a "$INSTALL_LOG"
LONGHORN_VERSION=$(curl -s https://api.github.com/repos/longhorn/longhorn/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "✓ Latest version: $LONGHORN_VERSION" | tee -a "$INSTALL_LOG"

# Install Longhorn
echo "Installing Longhorn $LONGHORN_VERSION..." | tee -a "$INSTALL_LOG"
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/${LONGHORN_VERSION}/deploy/longhorn.yaml 2>&1 | tee -a "$INSTALL_LOG"

# Wait for Longhorn to be ready
echo "Waiting for Longhorn to be ready..." | tee -a "$INSTALL_LOG"
kubectl -n longhorn-system wait --for=condition=available deployment/longhorn-driver-deployer --timeout=300s 2>&1 | tee -a "$INSTALL_LOG"

# Create StorageClass
echo "Creating default StorageClass..." | tee -a "$INSTALL_LOG"
cat <<EOF | kubectl apply -f - 2>&1 | tee -a "$INSTALL_LOG"
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: driver.longhorn.io
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "30"
  fromBackup: ""
  fsType: "ext4"
EOF

# Verify installation
echo "" | tee -a "$INSTALL_LOG"
echo "Verifying Longhorn installation..." | tee -a "$INSTALL_LOG"
kubectl get pods -n longhorn-system | tee -a "$INSTALL_LOG"

echo "" | tee -a "$INSTALL_LOG"
echo "StorageClasses:" | tee -a "$INSTALL_LOG"
kubectl get storageclass | tee -a "$INSTALL_LOG"

echo "" | tee -a "$INSTALL_LOG"
echo "==========================================" | tee -a "$INSTALL_LOG"
echo "Longhorn installed successfully!" | tee -a "$INSTALL_LOG"
echo "Access UI via: kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80" | tee -a "$INSTALL_LOG"
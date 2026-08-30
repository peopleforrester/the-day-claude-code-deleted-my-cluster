#!/bin/bash
# ABOUTME: Join additional control plane nodes to the cluster
# ABOUTME: Creates HA control plane with 3 masters

set -e

echo "=== Joining Control Plane Node ==="

HOSTNAME=$(hostname)
if [[ ! "$HOSTNAME" =~ ^master[2-3]$ ]]; then
    echo "ERROR: This script should only run on master2 or master3"
    exit 1
fi

echo "Joining $HOSTNAME as control plane node..."

# Join as control plane with certificate key
kubeadm join 192.168.0.100:6443 \
    --token <REDACTED-KUBEADM-TOKEN> \
    --discovery-token-ca-cert-hash sha256:7539ce73805bdbd6ba72efdc42a43a3d5c48ab9e4ebdc0c20c47cd40adaeac5c \
    --control-plane \
    --certificate-key b12bffd3a967b3ce3464540920a87b96f971c1671e78581cef2ffe840d0c2ac1

echo ""
echo "=== Control Plane Join Complete ==="
echo "Node $HOSTNAME joined as control plane"

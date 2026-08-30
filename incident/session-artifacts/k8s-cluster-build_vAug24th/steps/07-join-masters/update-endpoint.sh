#!/bin/bash
# ABOUTME: Update control plane endpoint for HA
# ABOUTME: Sets stable endpoint for multi-master setup

set -e

export KUBECONFIG=/etc/kubernetes/admin.conf

echo "=== Updating Control Plane Endpoint ==="

# Get current kubeadm config
kubectl get cm kubeadm-config -n kube-system -o yaml > kubeadm-config.yaml

# Update the controlPlaneEndpoint
sed -i 's/controlPlaneEndpoint: ""/controlPlaneEndpoint: "192.168.0.100:6443"/g' kubeadm-config.yaml

# If controlPlaneEndpoint doesn't exist, add it
if ! grep -q "controlPlaneEndpoint:" kubeadm-config.yaml; then
    sed -i '/clusterName:/a\    controlPlaneEndpoint: "192.168.0.100:6443"' kubeadm-config.yaml
fi

# Apply the updated config
kubectl apply -f kubeadm-config.yaml

echo "Control plane endpoint updated to 192.168.0.100:6443"

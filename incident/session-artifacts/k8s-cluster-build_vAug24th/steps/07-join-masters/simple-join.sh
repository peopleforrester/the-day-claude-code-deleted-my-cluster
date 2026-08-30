#!/bin/bash
# ABOUTME: Simple control plane join for additional masters
# ABOUTME: Joins without HA endpoint configuration

set -e

echo "=== Joining as Control Plane Node ==="

HOSTNAME=$(hostname)
echo "Joining $HOSTNAME to cluster..."

# First, copy certificates from master1
echo "Copying certificates from master1..."

# Create directories
mkdir -p /etc/kubernetes/pki/etcd

# Copy certificates from master1 (these would normally be done via --certificate-key)
scp root@192.168.0.100:/etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/
scp root@192.168.0.100:/etc/kubernetes/pki/ca.key /etc/kubernetes/pki/
scp root@192.168.0.100:/etc/kubernetes/pki/sa.key /etc/kubernetes/pki/
scp root@192.168.0.100:/etc/kubernetes/pki/sa.pub /etc/kubernetes/pki/
scp root@192.168.0.100:/etc/kubernetes/pki/front-proxy-ca.crt /etc/kubernetes/pki/
scp root@192.168.0.100:/etc/kubernetes/pki/front-proxy-ca.key /etc/kubernetes/pki/
scp root@192.168.0.100:/etc/kubernetes/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/
scp root@192.168.0.100:/etc/kubernetes/pki/etcd/ca.key /etc/kubernetes/pki/etcd/

echo "Certificates copied successfully"

# Join as control plane
kubeadm join 192.168.0.100:6443 \
    --token <REDACTED-KUBEADM-TOKEN> \
    --discovery-token-ca-cert-hash sha256:7539ce73805bdbd6ba72efdc42a43a3d5c48ab9e4ebdc0c20c47cd40adaeac5c \
    --control-plane

echo ""
echo "=== Control Plane Join Complete ==="
echo "Node $HOSTNAME joined as control plane"

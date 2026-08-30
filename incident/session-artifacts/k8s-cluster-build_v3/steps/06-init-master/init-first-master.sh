#!/bin/bash
# ABOUTME: Script to initialize the first Kubernetes master node
# ABOUTME: Sets up the control plane with HA configuration

set -e

MASTER1="192.168.0.100"
VIP="192.168.0.199"

echo "Initializing Kubernetes cluster on first master node..."
echo "This may take several minutes..."

# Copy kubeadm config to master1
echo "Copying kubeadm configuration..."
scp configs/kubeadm-config.yaml root@$MASTER1:/tmp/kubeadm-config.yaml

# Initialize the cluster
echo "Running kubeadm init on $MASTER1..."
ssh root@$MASTER1 "kubeadm init --config=/tmp/kubeadm-config.yaml --upload-certs" | tee steps/06-init-master/init-output.log

# Extract important information from output
echo
echo "Extracting join commands and certificate key..."

# Get the certificate key for control plane join
CERT_KEY=$(grep -A1 "certificate-key" steps/06-init-master/init-output.log | tail -1 | xargs)
echo "$CERT_KEY" > state/certificate-key.txt

# Get control plane join command
grep -A2 "kubeadm join.*--control-plane" steps/06-init-master/init-output.log | grep -v "^$" > state/control-plane-join.txt

# Get worker join command
grep -A1 "kubeadm join" steps/06-init-master/init-output.log | grep -v "control-plane" | grep -v "^$" | head -2 > state/worker-join.txt

# Setup kubectl access on master1
echo
echo "Configuring kubectl access on master1..."
ssh root@$MASTER1 "mkdir -p /root/.kube && cp /etc/kubernetes/admin.conf /root/.kube/config && chown root:root /root/.kube/config"

# Copy admin.conf to local for management
echo "Copying kubeconfig to local machine..."
mkdir -p $HOME/.kube
scp root@$MASTER1:/etc/kubernetes/admin.conf $HOME/.kube/k8s-cluster-config
chmod 600 $HOME/.kube/k8s-cluster-config

# Update kube-vip manifest to use admin.conf
echo "Updating kube-vip to use admin.conf..."
ssh root@$MASTER1 "sed -i 's/path: \/etc\/kubernetes\/super-admin.conf/path: \/etc\/kubernetes\/admin.conf/g' /etc/kubernetes/manifests/kube-vip.yaml"

echo
echo "First master node initialized successfully!"
echo "API Server endpoint: https://$VIP:6443"
echo
echo "To access the cluster from this machine:"
echo "export KUBECONFIG=$HOME/.kube/k8s-cluster-config"

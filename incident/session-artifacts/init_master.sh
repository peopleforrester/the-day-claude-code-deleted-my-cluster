#!/bin/bash
# ABOUTME: Script to initialize Kubernetes master node
# ABOUTME: Sets up the control plane and generates join command for workers

set -e

echo "Initializing Kubernetes master node..."

# Initialize the cluster with pod network CIDR for Calico
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.0.183

# Configure kubectl for the current user
echo "Configuring kubectl for user..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico network plugin
echo "Installing Calico network plugin..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml

# Wait for Calico to be ready
echo "Waiting for Calico to be ready..."
kubectl wait --for=condition=Ready pods -l k8s-app=calico-node -n kube-system --timeout=300s

# Generate join command for worker nodes
echo "Generating join command for worker nodes..."
kubeadm token create --print-join-command > /root/kubeadm_join_command.sh
chmod +x /root/kubeadm_join_command.sh

echo "Master node initialization complete!"
echo "Join command saved to: /root/kubeadm_join_command.sh"

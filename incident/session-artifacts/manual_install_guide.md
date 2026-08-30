# Manual Kubernetes Installation Guide

Due to network connectivity issues, here's a step-by-step manual installation guide.

## Step 1: Fix DNS on All Nodes

SSH into each node and run:

```bash
# For each node:
ssh root@<NODE_IP>

# Fix DNS
cat <<EOF | sudo tee /etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# Test connectivity
ping -c 3 google.com
```

## Step 2: Install Prerequisites on All Nodes

On each node, run these commands:

```bash
# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set sysctl params
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Install containerd
sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Add Kubernetes repo
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

## Step 3: Initialize Master Node (192.168.0.183)

On the master node only:

```bash
# Initialize cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.0.183

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml

# Get join command
kubeadm token create --print-join-command
```

## Step 4: Join Worker Nodes

Copy the join command from Step 3 and run it on each worker node with sudo:

```bash
sudo kubeadm join 192.168.0.183:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

## Step 5: Verify Cluster

On the master node:

```bash
kubectl get nodes
kubectl get pods -A
```

## Alternative: Offline Installation

If internet connectivity is poor, consider:
1. Downloading all required packages on a machine with good connectivity
2. Creating a local repository
3. Installing from the local repository

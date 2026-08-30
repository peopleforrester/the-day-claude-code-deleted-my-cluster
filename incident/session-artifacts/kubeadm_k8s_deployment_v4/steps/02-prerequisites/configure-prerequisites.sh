#\!/bin/bash
# Configure system prerequisites for Kubernetes

# Disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Load required kernel modules
cat > /etc/modules-load.d/k8s.conf << MODULES
overlay
br_netfilter
MODULES

modprobe overlay
modprobe br_netfilter

# Configure sysctl parameters
cat > /etc/sysctl.d/k8s.conf << SYSCTL
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSCTL

sysctl --system

# Update package index
apt-get update

# Install required packages
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

echo "Prerequisites configured successfully"

#!/bin/bash

# Install containerd runtime with systemd cgroup driver

# Update package index
apt-get update

# Install dependencies
apt-get install -y ca-certificates curl gnupg

# Install containerd
apt-get install -y containerd

# Create containerd configuration directory
mkdir -p /etc/containerd

# Generate default configuration and modify for systemd cgroup
containerd config default > /etc/containerd/config.toml

# Configure systemd cgroup driver
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Configure sandbox image for Kubernetes
sed -i 's|sandbox_image = ".*"|sandbox_image = "registry.k8s.io/pause:3.9"|' /etc/containerd/config.toml

# Enable and restart containerd
systemctl daemon-reload
systemctl enable containerd
systemctl restart containerd

# Verify installation
echo "=== Verification ==="
echo "Containerd version:"
containerd --version
echo ""
echo "Service status:"
systemctl is-active containerd
echo ""
echo "Cgroup driver configuration:"
grep SystemdCgroup /etc/containerd/config.toml | grep -v "#"
echo ""
echo "Runtime status:"
ctr version

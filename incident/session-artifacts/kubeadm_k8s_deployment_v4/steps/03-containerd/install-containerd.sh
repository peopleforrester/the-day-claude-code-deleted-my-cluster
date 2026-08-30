#\!/bin/bash
# Install and configure containerd for Kubernetes

# Install containerd
apt-get update
apt-get install -y containerd

# Create containerd configuration directory
mkdir -p /etc/containerd

# Generate default configuration
containerd config default > /etc/containerd/config.toml

# Configure containerd to use systemd cgroup driver
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Ensure the containerd.sock file exists
mkdir -p /run/containerd

# Restart containerd
systemctl daemon-reload
systemctl enable containerd
systemctl restart containerd

# Verify installation
systemctl is-active containerd

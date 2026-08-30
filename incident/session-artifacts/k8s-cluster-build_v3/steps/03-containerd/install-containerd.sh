#!/bin/bash
# ABOUTME: Script to install and configure containerd for Kubernetes
# ABOUTME: Configures systemd cgroup driver and required plugins

set -e

NODES="192.168.0.100 192.168.0.101 192.168.0.102 192.168.0.103 192.168.0.104"

echo "Installing and configuring containerd on all nodes..."

for node in $NODES; do
    echo "=== Configuring $node ==="

    # Install containerd
    ssh root@$node "apt-get update -qq && apt-get install -y containerd"
    echo "  - Containerd installed"

    # Create containerd config directory
    ssh root@$node "mkdir -p /etc/containerd"

    # Generate default config and modify for systemd cgroup
    ssh root@$node "containerd config default > /etc/containerd/config.toml"

    # Enable systemd cgroup driver
    ssh root@$node "sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml"

    # Set the correct sandbox image
    ssh root@$node "sed -i 's|sandbox_image = \"registry.k8s.io/pause:3.6\"|sandbox_image = \"registry.k8s.io/pause:3.9\"|g' /etc/containerd/config.toml"

    echo "  - Configuration updated with systemd cgroup"

    # Restart containerd
    ssh root@$node "systemctl restart containerd && systemctl enable containerd"
    echo "  - Containerd service restarted and enabled"

    # Verify containerd is running
    if ssh root@$node "systemctl is-active containerd" >/dev/null 2>&1; then
        echo "  - Containerd is running successfully"
    else
        echo "  - ERROR: Containerd failed to start!"
        exit 1
    fi

    echo
done

echo "Containerd installed and configured on all nodes!"

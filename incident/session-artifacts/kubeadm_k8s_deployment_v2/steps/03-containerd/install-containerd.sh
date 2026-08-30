#!/bin/bash
# Install and configure containerd on all nodes

NODES=("192.168.0.183" "192.168.0.194" "192.168.0.196" "192.168.0.197" "192.168.0.198")

echo "=== Installing Containerd on All Nodes ==="
echo "Start time: $(date)"
echo ""

for node in "${NODES[@]}"; do
  echo "Installing containerd on node $node..."

  # Install containerd
  echo "  - Installing containerd package..."
  ssh root@$node "apt-get update && apt-get install -y containerd" 2>&1 > /dev/null

  # Create containerd config directory
  echo "  - Creating config directory..."
  ssh root@$node "mkdir -p /etc/containerd" 2>&1

  # Generate default config and modify for systemd cgroup
  echo "  - Generating and configuring containerd config..."
  ssh root@$node "containerd config default > /etc/containerd/config.toml" 2>&1

  # Configure systemd cgroup driver
  ssh root@$node "sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml" 2>&1

  # Set the correct sandbox image
  ssh root@$node "sed -i 's|sandbox_image = \"registry.k8s.io/pause:3.8\"|sandbox_image = \"registry.k8s.io/pause:3.9\"|g' /etc/containerd/config.toml" 2>&1

  # Restart containerd
  echo "  - Restarting containerd service..."
  ssh root@$node "systemctl restart containerd && systemctl enable containerd" 2>&1

  echo "  ✓ Containerd installed on node $node"
  echo ""
done

echo "=== Containerd Installation Complete ==="
echo "End time: $(date)"

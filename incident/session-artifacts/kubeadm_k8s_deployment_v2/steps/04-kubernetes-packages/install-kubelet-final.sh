#!/bin/bash
# Final attempt to install kubelet

NODES=("192.168.0.183" "192.168.0.194" "192.168.0.196" "192.168.0.197" "192.168.0.198")

for node in "${NODES[@]}"; do
  echo "Installing kubelet on $node..."

  # Unhold packages
  ssh root@$node "apt-mark unhold kubelet kubeadm kubectl" 2>&1

  # Install kubelet with force
  ssh root@$node "apt-get install -y --allow-change-held-packages kubelet" 2>&1 | tail -n 10

  # Re-hold packages
  ssh root@$node "apt-mark hold kubelet kubeadm kubectl" 2>&1

  # Enable kubelet
  ssh root@$node "systemctl enable kubelet" 2>&1

  echo "---"
done

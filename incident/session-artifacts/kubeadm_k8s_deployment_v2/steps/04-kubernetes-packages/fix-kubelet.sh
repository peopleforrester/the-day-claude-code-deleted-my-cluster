#!/bin/bash
# Fix broken packages and install kubelet

NODES=("192.168.0.183" "192.168.0.194" "192.168.0.196" "192.168.0.197" "192.168.0.198")

for node in "${NODES[@]}"; do
  echo "Fixing packages on $node..."
  ssh root@$node "apt-get install -f -y" 2>&1 > /dev/null
  ssh root@$node "apt-get install -y kubelet" 2>&1 > /dev/null
  ssh root@$node "systemctl enable kubelet" 2>&1
  echo "Done with $node"
  echo ""
done

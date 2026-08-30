#!/bin/bash
# Clean up disk space on all nodes

NODES=("192.168.0.183" "192.168.0.194" "192.168.0.196" "192.168.0.197" "192.168.0.198")

echo "=== Cleaning up disk space on all nodes ==="
echo ""

for node in "${NODES[@]}"; do
  echo "Cleaning node $node..."

  # Clean apt cache
  echo "  - Cleaning apt cache..."
  ssh root@$node "apt-get clean" 2>&1

  # Remove old kernels
  echo "  - Removing old kernels..."
  ssh root@$node "apt-get autoremove -y" 2>&1 > /dev/null

  # Clean journal logs
  echo "  - Cleaning journal logs..."
  ssh root@$node "journalctl --vacuum-time=2d" 2>&1

  # Show disk usage after cleanup
  echo -n "  - Disk usage after cleanup: "
  ssh root@$node "df -h / | tail -1 | awk '{print \$5}'" 2>&1

  echo ""
done

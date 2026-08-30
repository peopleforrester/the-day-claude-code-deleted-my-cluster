#!/bin/bash
# Clean up containerd storage

NODES=("192.168.0.183" "192.168.0.194" "192.168.0.196")

for node in "${NODES[@]}"; do
  echo "Cleaning containerd on $node..."

  # Stop containerd temporarily
  ssh root@$node "systemctl stop containerd" 2>&1

  # Clear containerd content store
  ssh root@$node "rm -rf /var/lib/containerd/io.containerd.content.v1.content/ingest/*" 2>&1
  ssh root@$node "rm -rf /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/*" 2>&1

  # Restart containerd
  ssh root@$node "systemctl start containerd" 2>&1

  # Check disk space
  echo -n "  Disk usage: "
  ssh root@$node "df -h / | tail -1 | awk '{print \$5}'" 2>&1
  echo ""
done

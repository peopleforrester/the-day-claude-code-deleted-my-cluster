#!/bin/bash
# Deep clean to free disk space

NODES=("192.168.0.183" "192.168.0.194" "192.168.0.196")

for node in "${NODES[@]}"; do
  echo "Deep cleaning $node..."

  # Clean logs
  ssh root@$node "find /var/log -type f -name '*.log' -delete" 2>&1
  ssh root@$node "find /var/log -type f -name '*.gz' -delete" 2>&1

  # Clean apt
  ssh root@$node "apt-get clean" 2>&1
  ssh root@$node "rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*" 2>&1

  # Clean journal
  ssh root@$node "journalctl --vacuum-size=10M" 2>&1

  # Check space
  echo -n "  Final disk usage: "
  ssh root@$node "df -h / | tail -1 | awk '{print \$5}'" 2>&1
  echo ""
done

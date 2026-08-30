#!/bin/bash
# Validate containerd installation on all nodes

NODES=("192.168.0.183:master1" "192.168.0.194:master2" "192.168.0.196:master3" "192.168.0.197:worker1" "192.168.0.198:worker2")
FAILED=0

echo "=== Containerd Validation ==="
echo "Test Date: $(date)"
echo ""

for node_info in "${NODES[@]}"; do
  IFS=':' read -r ip hostname <<< "$node_info"
  echo "Checking $hostname ($ip):"

  # Check containerd service
  echo -n "  - Containerd service active: "
  service_status=$(ssh root@$ip "systemctl is-active containerd" 2>/dev/null)
  if [ "$service_status" = "active" ]; then
    echo "✓ PASS"
  else
    echo "✗ FAIL ($service_status)"
    FAILED=$((FAILED + 1))
  fi

  # Check containerd enabled
  echo -n "  - Containerd service enabled: "
  enabled_status=$(ssh root@$ip "systemctl is-enabled containerd" 2>/dev/null)
  if [ "$enabled_status" = "enabled" ]; then
    echo "✓ PASS"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi

  # Check SystemdCgroup setting
  echo -n "  - SystemdCgroup enabled: "
  systemd_cgroup=$(ssh root@$ip "grep 'SystemdCgroup = true' /etc/containerd/config.toml" 2>/dev/null)
  if [ -n "$systemd_cgroup" ]; then
    echo "✓ PASS"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi

  # Check containerd version
  echo -n "  - Containerd version: "
  version=$(ssh root@$ip "containerd --version" 2>/dev/null | awk '{print $3}')
  if [ -n "$version" ]; then
    echo "$version ✓"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi

  echo ""
done

echo "=== Summary ==="
if [ $FAILED -eq 0 ]; then
  echo "✓ Containerd validated successfully on all nodes!"
  exit 0
else
  echo "✗ $FAILED checks failed!"
  exit 1
fi

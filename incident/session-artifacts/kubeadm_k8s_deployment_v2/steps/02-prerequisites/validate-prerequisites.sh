#!/bin/bash
# Validate system prerequisites on all nodes

NODES=("192.168.0.183:master1" "192.168.0.194:master2" "192.168.0.196:master3" "192.168.0.197:worker1" "192.168.0.198:worker2")
FAILED=0

echo "=== System Prerequisites Validation ==="
echo "Test Date: $(date)"
echo ""

for node_info in "${NODES[@]}"; do
  IFS=':' read -r ip hostname <<< "$node_info"
  echo "Checking $hostname ($ip):"

  # Check swap
  echo -n "  - Swap disabled: "
  swap_status=$(ssh root@$ip "swapon -s | wc -l" 2>/dev/null)
  if [ "$swap_status" -eq "0" ]; then
    echo "✓ PASS"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi

  # Check kernel modules
  echo -n "  - Kernel module overlay: "
  if ssh root@$ip "lsmod | grep -q overlay" 2>/dev/null; then
    echo "✓ PASS"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi

  echo -n "  - Kernel module br_netfilter: "
  if ssh root@$ip "lsmod | grep -q br_netfilter" 2>/dev/null; then
    echo "✓ PASS"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi

  # Check sysctl parameters
  echo -n "  - IP forwarding enabled: "
  ip_forward=$(ssh root@$ip "sysctl net.ipv4.ip_forward -n" 2>/dev/null)
  if [ "$ip_forward" = "1" ]; then
    echo "✓ PASS"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi

  echo -n "  - Bridge netfilter enabled: "
  bridge_nf=$(ssh root@$ip "sysctl net.bridge.bridge-nf-call-iptables -n" 2>/dev/null)
  if [ "$bridge_nf" = "1" ]; then
    echo "✓ PASS"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi

  echo ""
done

echo "=== Summary ==="
if [ $FAILED -eq 0 ]; then
  echo "✓ All prerequisites validated successfully!"
  exit 0
else
  echo "✗ $FAILED checks failed!"
  exit 1
fi

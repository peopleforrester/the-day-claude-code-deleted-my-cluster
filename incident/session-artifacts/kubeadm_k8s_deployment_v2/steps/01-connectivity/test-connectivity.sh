#!/bin/bash
# Test script to validate connectivity to all nodes

echo "=== Connectivity Test Results ==="
echo "Test Date: $(date)"
echo ""

NODES=("192.168.0.183:master1" "192.168.0.194:master2" "192.168.0.196:master3" "192.168.0.197:worker1" "192.168.0.198:worker2")
FAILED=0

for node in "${NODES[@]}"; do
  IFS=':' read -r ip hostname <<< "$node"
  echo -n "Testing $hostname ($ip)... "

  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes root@$ip "exit" 2>/dev/null; then
    echo "✓ PASS"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "=== Summary ==="
echo "Total nodes: ${#NODES[@]}"
echo "Passed: $((${#NODES[@]} - FAILED))"
echo "Failed: $FAILED"

if [ $FAILED -eq 0 ]; then
  echo ""
  echo "✓ All nodes are reachable!"
  exit 0
else
  echo ""
  echo "✗ Some nodes are not reachable!"
  exit 1
fi

#!/bin/bash
# Validate kube-vip setup

MASTER_NODES=("192.168.0.183:master1" "192.168.0.194:master2" "192.168.0.196:master3")
VIP="192.168.0.180"
FAILED=0

echo "=== kube-vip Validation ==="
echo "Test Date: $(date)"
echo ""

for node_info in "${MASTER_NODES[@]}"; do
  IFS=':' read -r ip hostname <<< "$node_info"
  echo "Checking $hostname ($ip):"

  # Check manifest exists
  echo -n "  - kube-vip manifest exists: "
  if ssh root@$ip "test -f /etc/kubernetes/manifests/kube-vip.yaml" 2>/dev/null; then
    echo "✓ PASS"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi

  # Check image pulled
  echo -n "  - kube-vip image present: "
  image_exists=$(ssh root@$ip "ctr -n k8s.io images ls | grep kube-vip" 2>/dev/null)
  if [ -n "$image_exists" ]; then
    echo "✓ PASS"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi

  # Check manifest contains correct VIP
  echo -n "  - VIP configured ($VIP): "
  vip_configured=$(ssh root@$ip "grep -q 'value: $VIP' /etc/kubernetes/manifests/kube-vip.yaml && echo yes" 2>/dev/null)
  if [ "$vip_configured" = "yes" ]; then
    echo "✓ PASS"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi

  echo ""
done

# Test VIP connectivity (will fail until kubeadm init)
echo "Testing VIP connectivity:"
echo -n "  - Ping $VIP: "
if ping -c 1 -W 2 $VIP >/dev/null 2>&1; then
  echo "✓ PASS"
else
  echo "⚠ Not yet active (expected until kubeadm init)"
fi

echo ""
echo "=== Summary ==="
if [ $FAILED -eq 0 ]; then
  echo "✓ kube-vip configured successfully on all master nodes!"
  echo "  Note: VIP will become active after kubeadm init"
  exit 0
else
  echo "✗ $FAILED checks failed!"
  exit 1
fi

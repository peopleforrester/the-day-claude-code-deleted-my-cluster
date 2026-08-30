#!/bin/bash
# Validate Kubernetes packages installation

NODES=("192.168.0.183:master1" "192.168.0.194:master2" "192.168.0.196:master3" "192.168.0.197:worker1" "192.168.0.198:worker2")
FAILED=0

echo "=== Kubernetes Packages Validation ==="
echo "Test Date: $(date)"
echo ""

for node_info in "${NODES[@]}"; do
  IFS=':' read -r ip hostname <<< "$node_info"
  echo "Checking $hostname ($ip):"

  # Check kubeadm
  echo -n "  - kubeadm installed: "
  kubeadm_version=$(ssh root@$ip "kubeadm version -o short 2>/dev/null" 2>/dev/null)
  if [ -n "$kubeadm_version" ]; then
    echo "✓ $kubeadm_version"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi

  # Check kubectl
  echo -n "  - kubectl installed: "
  kubectl_version=$(ssh root@$ip "kubectl version --client 2>/dev/null | grep 'Client Version' | awk '{print \$3}'" 2>/dev/null)
  if [ -n "$kubectl_version" ]; then
    echo "✓ $kubectl_version"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi

  # Check kubelet
  echo -n "  - kubelet installed: "
  kubelet_version=$(ssh root@$ip "kubelet --version 2>/dev/null | cut -d' ' -f2" 2>/dev/null)
  if [ -n "$kubelet_version" ]; then
    echo "✓ $kubelet_version"
  else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
  fi

  # Check kubelet service
  echo -n "  - kubelet service: "
  kubelet_enabled=$(ssh root@$ip "systemctl is-enabled kubelet 2>/dev/null" 2>/dev/null)
  if [ "$kubelet_enabled" = "enabled" ]; then
    echo "✓ enabled"
  else
    echo "✗ not enabled"
    FAILED=$((FAILED + 1))
  fi

  echo ""
done

# Save versions
echo "Saving package versions..."
ssh root@192.168.0.183 "kubeadm version -o short && kubectl version --client=true -o yaml | grep gitVersion | cut -d' ' -f2 && kubelet --version | cut -d' ' -f2" 2>/dev/null > steps/04-kubernetes-packages/kubernetes-version.json 2>&1

echo "=== Summary ==="
if [ $FAILED -eq 0 ]; then
  echo "✓ All Kubernetes packages validated successfully!"
  exit 0
else
  echo "✗ $FAILED checks failed!"
  exit 1
fi

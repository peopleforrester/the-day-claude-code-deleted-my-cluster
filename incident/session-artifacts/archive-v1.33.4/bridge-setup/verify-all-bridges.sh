#!/bin/bash
echo "========================================="
echo "Bridge Verification for All Worker Nodes"
echo "========================================="
echo

for node in k8s04 k8s05 k8s06 k8s07 k8s08 k8s09; do
  case $node in
    k8s04) ip="192.168.0.53" ;;
    k8s05) ip="192.168.0.54" ;;
    k8s06) ip="192.168.0.55" ;;
    k8s07) ip="192.168.0.56" ;;
    k8s08) ip="192.168.0.57" ;;
    k8s09) ip="192.168.0.58" ;;
  esac

  echo "=== $node ($ip) ==="
  ssh root@$ip "ip -br link show br0" 2>/dev/null || echo "Bridge check failed"
  kubectl get node $node --no-headers | awk '{print "Node Status: "$2}'
  echo
done

echo "========================================="
echo "Summary Complete"
echo "========================================="

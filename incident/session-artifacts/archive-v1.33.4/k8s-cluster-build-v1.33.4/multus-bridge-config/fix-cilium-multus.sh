#!/bin/bash
# Fix Cilium to work as a chained CNI with Multus

echo "========================================="
echo "Configuring Cilium to work with Multus"
echo "========================================="

# Update Cilium ConfigMap to work in chained mode
echo "1. Updating Cilium ConfigMap for chained CNI mode..."
kubectl patch configmap cilium-config -n kube-system --type merge -p '
{
  "data": {
    "cni-exclusive": "false",
    "cni-chaining-mode": "generic-veth",
    "custom-cni-conf": "false",
    "write-cni-conf-when-ready": ""
  }
}'

# Wait for Cilium to restart
echo "2. Restarting Cilium pods to apply changes..."
kubectl rollout restart daemonset/cilium -n kube-system
kubectl rollout restart daemonset/cilium-envoy -n kube-system

echo "3. Waiting for Cilium pods to be ready..."
kubectl rollout status daemonset/cilium -n kube-system --timeout=120s
kubectl rollout status daemonset/cilium-envoy -n kube-system --timeout=120s

echo "========================================="
echo "Cilium reconfiguration complete"
echo "========================================="

#!/bin/bash
# Set up kube-vip for HA on all master nodes

MASTER_NODES=("192.168.0.183" "192.168.0.194" "192.168.0.196")
VIP="192.168.0.180"
INTERFACE="eth0"  # Adjust if different
KUBE_VIP_VERSION="v0.8.7"

echo "=== Setting up kube-vip for HA ==="
echo "Start time: $(date)"
echo "VIP: $VIP"
echo "kube-vip version: $KUBE_VIP_VERSION"
echo ""

# First, determine the correct interface on master1
echo "Determining network interface..."
INTERFACE=$(ssh root@192.168.0.183 "ip route | grep default | awk '{print \$5}'" 2>/dev/null)
echo "Using interface: $INTERFACE"
echo ""

for node in "${MASTER_NODES[@]}"; do
  echo "Configuring kube-vip on node $node..."

  # Create directory for static pod manifests
  echo "  - Creating static pod directory..."
  ssh root@$node "mkdir -p /etc/kubernetes/manifests" 2>&1

  # Pull kube-vip container image
  echo "  - Pulling kube-vip image..."
  ssh root@$node "ctr image pull ghcr.io/kube-vip/kube-vip:$KUBE_VIP_VERSION" 2>&1

  # Generate kube-vip manifest
  echo "  - Generating kube-vip manifest..."
  ssh root@$node "ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:$KUBE_VIP_VERSION vip /kube-vip manifest pod \
    --interface $INTERFACE \
    --address $VIP \
    --controlplane \
    --services \
    --arp \
    --leaderElection > /etc/kubernetes/manifests/kube-vip.yaml" 2>&1

  echo "  ✓ kube-vip configured on node $node"
  echo ""
done

# Save the manifest from master1
echo "Saving kube-vip manifest..."
ssh root@192.168.0.183 "cat /etc/kubernetes/manifests/kube-vip.yaml" > configs/kube-vip-manifest.yaml 2>&1

echo "=== kube-vip Setup Complete ==="
echo "End time: $(date)"

#!/bin/bash
# ABOUTME: Script to configure kube-vip for HA on master nodes
# ABOUTME: Creates static pod manifests for VIP management

set -e

MASTER_NODES="192.168.0.100 192.168.0.101 192.168.0.102"
VIP="192.168.0.199"
INTERFACE="enp0s3"  # Default interface, will be detected
KUBE_VIP_VERSION="v0.8.7"

echo "Setting up kube-vip on master nodes..."

for node in $MASTER_NODES; do
    echo "=== Configuring $node ==="

    # Detect primary network interface
    INTERFACE=$(ssh root@$node "ip route | grep default | awk '{print \$5}' | head -1")
    echo "  - Detected interface: $INTERFACE"

    # Pull kube-vip container image
    ssh root@$node "ctr -n=k8s.io images pull ghcr.io/kube-vip/kube-vip:$KUBE_VIP_VERSION"
    echo "  - kube-vip image pulled"

    # Create manifest directory
    ssh root@$node "mkdir -p /etc/kubernetes/manifests"

    # Generate kube-vip manifest
    ssh root@$node "ctr -n=k8s.io run --rm ghcr.io/kube-vip/kube-vip:$KUBE_VIP_VERSION vip /kube-vip manifest pod \
        --interface $INTERFACE \
        --address $VIP \
        --controlplane \
        --services \
        --arp \
        --leaderElection > /etc/kubernetes/manifests/kube-vip.yaml"

    echo "  - kube-vip manifest created"

    # Adjust manifest for pre-init state
    ssh root@$node "sed -i 's/path: \/etc\/kubernetes\/admin.conf/path: \/etc\/kubernetes\/super-admin.conf/g' /etc/kubernetes/manifests/kube-vip.yaml"

    echo "  - Manifest adjusted for pre-init state"
    echo
done

echo "kube-vip configured on all master nodes!"
echo "VIP: $VIP will be activated when first master is initialized"

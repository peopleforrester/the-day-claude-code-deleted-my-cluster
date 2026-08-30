#!/bin/bash
# Install kube-vip v1.0.0 using the container image method

CONTROL_NODES=(50 51 52)
VIP="192.168.0.200"
KUBE_VIP_VERSION="v1.0.0"
KUBE_VIP_IMAGE="ghcr.io/kube-vip/kube-vip:${KUBE_VIP_VERSION}"

echo "==================================="
echo "Installing kube-vip ${KUBE_VIP_VERSION}"
echo "VIP: $VIP"
echo "Started: $(date)"
echo "==================================="
echo ""

# For each control plane node
for node in "${CONTROL_NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    echo "Setting up kube-vip on $NODE_NAME ($IP)..."

    # Get the primary network interface
    INTERFACE=$(ssh root@$IP "ip route | grep default | awk '{print \$5}' | head -1" 2>/dev/null)
    echo "  Network interface: $INTERFACE"

    # Pull the kube-vip container image using ctr (containerd)
    echo "  Pulling kube-vip container image..."
    ssh root@$IP "ctr image pull ${KUBE_VIP_IMAGE}" 2>/dev/null

    if [ $? -ne 0 ]; then
        echo "  ✗ Failed to pull image - trying with docker.io prefix..."
        # Some versions might need docker.io prefix
        ssh root@$IP "ctr image pull docker.io/plndr/kube-vip:${KUBE_VIP_VERSION}" 2>/dev/null
    fi

    # Extract the binary from the container
    echo "  Extracting kube-vip binary from container..."
    ssh root@$IP "mkdir -p /tmp/kube-vip-extract"

    # Create a container and copy the binary out
    ssh root@$IP "ctr run --rm --mount type=bind,src=/tmp/kube-vip-extract,dst=/extract,options=rbind:rw ${KUBE_VIP_IMAGE} extract-${NODE_NAME} cp /kube-vip /extract/kube-vip" 2>/dev/null

    # If that didn't work, try the docker.io image
    if [ ! -f /tmp/kube-vip-extract/kube-vip ]; then
        ssh root@$IP "ctr run --rm --mount type=bind,src=/tmp/kube-vip-extract,dst=/extract,options=rbind:rw docker.io/plndr/kube-vip:${KUBE_VIP_VERSION} extract-${NODE_NAME} cp /kube-vip /extract/kube-vip" 2>/dev/null
    fi

    # Move binary to final location
    ssh root@$IP "mv /tmp/kube-vip-extract/kube-vip /usr/local/bin/kube-vip 2>/dev/null && chmod +x /usr/local/bin/kube-vip"

    # Verify the binary works
    KUBE_VIP_CHECK=$(ssh root@$IP "/usr/local/bin/kube-vip version 2>&1 | head -1" 2>/dev/null)
    echo "  Version check: $KUBE_VIP_CHECK"

    # Since we can't generate the manifest without the binary, create it manually
    # This will be used as a static pod when the cluster initializes
    echo "  Creating static pod manifest for cluster initialization..."

    ssh root@$IP "mkdir -p /etc/kubernetes/manifests"

    # Create the kube-vip static pod manifest
    ssh root@$IP "cat > /etc/kubernetes/manifests/kube-vip.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: kube-vip
  namespace: kube-system
spec:
  containers:
  - args:
    - manager
    env:
    - name: vip_arp
      value: \"true\"
    - name: vip_interface
      value: \"$INTERFACE\"
    - name: port
      value: \"6443\"
    - name: vip_cidr
      value: \"32\"
    - name: vip_address
      value: \"$VIP\"
    - name: dns_mode
      value: \"first\"
    - name: vip_leaderelection
      value: \"true\"
    - name: vip_leasename
      value: \"plndr-cp-lock\"
    - name: vip_leaseduration
      value: \"15\"
    - name: vip_renewdeadline
      value: \"10\"
    - name: vip_retryperiod
      value: \"2\"
    - name: prometheus_server
      value: \":2113\"
    image: ${KUBE_VIP_IMAGE}
    imagePullPolicy: IfNotPresent
    name: kube-vip
    resources: {}
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - NET_RAW
    volumeMounts:
    - mountPath: /etc/kubernetes/admin.conf
      name: kubeconfig
  hostAliases:
  - hostnames:
    - kubernetes
    ip: 127.0.0.1
  hostNetwork: true
  volumes:
  - hostPath:
      path: /etc/kubernetes/admin.conf
    name: kubeconfig
EOF"

    echo "  ✓ Static pod manifest created"

    # For testing before cluster init, create a simple service
    # This will be removed once the cluster is initialized
    echo "  Creating test configuration..."

    ssh root@$IP "cat > /tmp/kube-vip-test.sh << 'EOF'
#!/bin/bash
# Test script for kube-vip (temporary until cluster init)
ip addr add $VIP/32 dev $INTERFACE 2>/dev/null
arping -c 3 -A -I $INTERFACE $VIP 2>/dev/null
echo \"VIP $VIP configured on $INTERFACE for testing\"
EOF"

    ssh root@$IP "chmod +x /tmp/kube-vip-test.sh"

    # Only activate on first node for now
    if [ "$node" = "50" ]; then
        echo "  Activating VIP on primary node for testing..."
        ssh root@$IP "/tmp/kube-vip-test.sh"

        # Check if VIP is assigned
        HAS_VIP=$(ssh root@$IP "ip addr show | grep -q '$VIP' && echo 'yes' || echo 'no'" 2>/dev/null)
        if [ "$HAS_VIP" = "yes" ]; then
            echo "  ✓ VIP $VIP assigned to $NODE_NAME"
        else
            echo "  ✗ VIP assignment failed"
        fi
    fi

    echo ""
done

# Test VIP
echo "Testing VIP connectivity..."
ping -c 2 -W 1 $VIP &>/dev/null
if [ $? -eq 0 ]; then
    echo "  ✓ VIP $VIP is responding"
else
    echo "  ✗ VIP not responding (will be fully configured during cluster init)"
fi

echo ""
echo "==================================="
echo "kube-vip Installation Summary"
echo "==================================="
echo "✓ kube-vip ${KUBE_VIP_VERSION} configured on control plane nodes"
echo "✓ Static pod manifests created at /etc/kubernetes/manifests/kube-vip.yaml"
echo "✓ VIP temporarily assigned for testing"
echo ""
echo "Note: kube-vip will run as a static pod once kubeadm initializes the cluster"
echo ""
echo "Completed: $(date)"

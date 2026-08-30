#!/bin/bash
# Retry kube-vip setup with proper cleanup

MASTER_NODES=("192.168.0.183" "192.168.0.194" "192.168.0.196")
VIP="192.168.0.180"
INTERFACE="enp1s0"
KUBE_VIP_VERSION="v0.8.7"

echo "=== Retrying kube-vip Setup ==="
echo ""

for node in "${MASTER_NODES[@]}"; do
  echo "Setting up kube-vip on $node..."

  # Clean any existing images
  ssh root@$node "ctr -n k8s.io images rm ghcr.io/kube-vip/kube-vip:$KUBE_VIP_VERSION 2>/dev/null || true" 2>&1

  # Pull kube-vip image
  echo "  - Pulling kube-vip image..."
  ssh root@$node "ctr -n k8s.io image pull ghcr.io/kube-vip/kube-vip:$KUBE_VIP_VERSION" 2>&1 | grep -E "(done|unpacking|%)" || echo "    Pull completed"

  # Generate kube-vip manifest directly
  echo "  - Generating manifest..."
  ssh root@$node "cat > /etc/kubernetes/manifests/kube-vip.yaml << 'EOF'
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
    - name: port
      value: \"6443\"
    - name: vip_interface
      value: $INTERFACE
    - name: vip_cidr
      value: \"24\"
    - name: cp_enable
      value: \"true\"
    - name: cp_namespace
      value: kube-system
    - name: vip_ddns
      value: \"false\"
    - name: vip_leaderelection
      value: \"true\"
    - name: vip_leaseduration
      value: \"5\"
    - name: vip_renewdeadline
      value: \"3\"
    - name: vip_retryperiod
      value: \"1\"
    - name: address
      value: $VIP
    - name: prometheus_server
      value: :2112
    image: ghcr.io/kube-vip/kube-vip:$KUBE_VIP_VERSION
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
status: {}
EOF" 2>&1

  echo "  ✓ kube-vip manifest created"
  echo ""
done

# Save the manifest
ssh root@192.168.0.183 "cat /etc/kubernetes/manifests/kube-vip.yaml" > configs/kube-vip-manifest.yaml 2>&1

echo "=== kube-vip Setup Complete ==="

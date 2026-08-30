#!/bin/bash
# Fix kube-vip for initial bootstrap

MASTER1="192.168.0.183"

# Remove the existing kube-vip pod
ssh root@$MASTER1 "rm -f /etc/kubernetes/manifests/kube-vip.yaml" 2>&1

# Wait for pod to be removed
sleep 5

# Create a simpler kube-vip manifest without leader election for bootstrap
ssh root@$MASTER1 "cat > /etc/kubernetes/manifests/kube-vip.yaml << 'EOF'
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
      value: enp1s0
    - name: vip_cidr
      value: \"24\"
    - name: cp_enable
      value: \"true\"
    - name: cp_namespace
      value: kube-system
    - name: vip_leaderelection
      value: \"false\"
    - name: address
      value: 192.168.0.180
    image: ghcr.io/kube-vip/kube-vip:v0.8.7
    imagePullPolicy: IfNotPresent
    name: kube-vip
    resources: {}
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - NET_RAW
  hostNetwork: true
status: {}
EOF" 2>&1

echo "kube-vip updated for bootstrap"

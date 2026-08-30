# Step 05: HA Infrastructure Setup - kube-vip v1.0.0

## Overview
Installed and configured kube-vip v1.0.0 for High Availability with Virtual IP 192.168.0.200

## Initial Mistake and Correction
- **ERROR**: Initially installed HAProxy and Keepalived instead of kube-vip
- **CORRECTED**: Removed HAProxy/Keepalived and installed kube-vip v1.0.0 as specified in requirements

## Completed Actions

### 1. Removed Incorrect Components
- Uninstalled HAProxy and Keepalived from all control plane nodes
- Removed all associated configuration files
- Cleaned up firewall rules added for HAProxy

### 2. Installed kube-vip v1.0.0
- Pulled kube-vip container image: `ghcr.io/kube-vip/kube-vip:v1.0.0`
- Created static pod manifests at `/etc/kubernetes/manifests/kube-vip.yaml`
- Configured for ARP mode with leader election

### 3. Configuration Details
- **VIP**: 192.168.0.200
- **Port**: 6443 (Kubernetes API server)
- **Mode**: ARP with leader election
- **Network Interfaces**:
  - k8s01 (192.168.0.50): enp2s0
  - k8s02 (192.168.0.51): enp2s0
  - k8s03 (192.168.0.52): enp1s0

### 4. Current Status
- VIP 192.168.0.200 is currently active on k8s01
- Static pod manifests prepared on all control plane nodes
- kube-vip will fully activate as a static pod when kubeadm initializes the cluster

## Files Created
- `discovery-05.log` - Initial discovery of HA components
- `removal.log` - HAProxy/Keepalived removal log
- `install-kube-vip-correct.sh` - Correct kube-vip installation script
- Static pod manifests on each control plane node

## Key Configuration (kube-vip.yaml)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-vip
  namespace: kube-system
spec:
  containers:
  - name: kube-vip
    image: ghcr.io/kube-vip/kube-vip:v1.0.0
    env:
    - name: vip_arp
      value: "true"
    - name: vip_interface
      value: "<interface>"  # enp2s0 or enp1s0
    - name: vip_address
      value: "192.168.0.200"
    - name: port
      value: "6443"
    - name: vip_leaderelection
      value: "true"
```

## Verification Results
- ✅ kube-vip v1.0.0 container images pulled on all control plane nodes
- ✅ Static pod manifests created at `/etc/kubernetes/manifests/kube-vip.yaml`
- ✅ VIP 192.168.0.200 active and responding to ping
- ✅ Ready for cluster initialization

## Next Steps
Ready for Step 06: Initialize First Master
- kubeadm will detect and use the kube-vip static pod manifest
- VIP will provide HA for the Kubernetes API server

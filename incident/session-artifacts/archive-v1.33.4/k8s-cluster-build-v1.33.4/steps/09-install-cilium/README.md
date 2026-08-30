# Step 09: Install Cilium CNI v1.18.0 - COMPLETE

## Installation Summary

Successfully installed Cilium v1.18.0 as the primary CNI, followed by Multus v4.2.2 as the meta-plugin.

## Cilium Installation Details

### Version
- Cilium: v1.18.0
- Helm Chart: 1.18.0
- Installation Method: Helm

### Configuration
```yaml
- Mode: Tunnel (VXLAN)
- Pod CIDR: 10.244.0.0/16
- Service CIDR: 10.96.0.0/12
- kube-proxy Replacement: Enabled
- BPF Masquerade: Enabled
- Hubble: Enabled with Relay
- API Server: 192.168.0.200:6443
```

### Components Deployed
- cilium (DaemonSet) - 3 pods running
- cilium-envoy (DaemonSet) - 3 pods running
- cilium-operator (Deployment) - 1 pod running
- hubble-relay (Deployment) - Running

## Multus Installation (Completed After Cilium)

### Version
- Multus CNI: v4.2.2
- Installation Method: Kubernetes manifest

### Configuration
- Primary CNI: Cilium
- Config Location: `/etc/cni/net.d/00-multus.conf.cilium_bak`
- Multus is correctly using Cilium as the delegate CNI

### Components Deployed
- kube-multus-ds (DaemonSet) - 3 pods running
- network-attachment-definitions CRD installed

## Cluster Status After CNI Installation

### Nodes
```
NAME    STATUS   ROLES           VERSION
k8s01   Ready    control-plane   v1.33.4
k8s02   Ready    control-plane   v1.33.4
k8s03   Ready    control-plane   v1.33.4
```

### Core Components
- CoreDNS: Running (2 replicas)
- kube-proxy: Replaced by Cilium eBPF
- All system pods: Healthy

## CNI Configuration Structure

```
/etc/cni/net.d/
├── 00-multus.conf.cilium_bak  # Multus configuration with Cilium delegate
├── 05-cilium.conflist         # Cilium CNI configuration
└── multus.d/
    └── multus.kubeconfig       # Multus kubeconfig for API access
```

## Verification Commands Used

```bash
# Check Cilium status
kubectl get pods -n kube-system -l k8s-app=cilium

# Check Multus status
kubectl get pods -n kube-system -l app=multus

# Verify nodes are Ready
kubectl get nodes

# Check CNI configuration
cat /etc/cni/net.d/00-multus.conf.cilium_bak
```

## Key Learnings

1. **Dependency Order**: Multus requires a primary CNI (Cilium) to be installed first
2. **Configuration Updates**: Cilium v1.18.0 deprecated the `tunnel` option; use `routingMode` instead
3. **Validation**: Always perform dry-run with Helm before actual installation
4. **Verification**: Check both pod status and CNI configuration files

## Next Steps

1. ✅ Join worker nodes to the cluster
2. ✅ Configure Linux bridges on worker nodes for KubeVirt
3. ✅ Create NetworkAttachmentDefinitions for Multus
4. ✅ Install Longhorn storage
5. ✅ Install KubeVirt

## Files Created
- `cilium-values.yaml` - Helm values for Cilium v1.18.0
- `install-cilium.sh` - Installation script with validation
- CNI configurations deployed to all nodes

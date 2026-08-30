# MetalLB Installation Documentation
Date: 2025-08-25

## Installation Summary

MetalLB v0.14.8 has been successfully installed on the Kubernetes cluster to provide LoadBalancer service type support for bare-metal environments.

## Configuration

### Prerequisites Verified
- ✅ Kubernetes v1.33.4 cluster running
- ✅ kube-proxy strictARP mode enabled
- ✅ All nodes healthy and accessible

### Installation Method
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml
```

### IP Address Pool Configuration
- **Pool Name**: default-pool
- **IP Range**: 192.168.0.210-192.168.0.250 (41 IPs available)
- **Mode**: Layer 2 (L2Advertisement)
- **Namespace**: metallb-system

### Deployed Components
- **Controller**: 1 replica (managing IP allocation)
- **Speaker**: 1 per node (9 total - handling ARP/NDP)
- **Webhook**: Validation webhook for configuration

## Services Configured with LoadBalancer

### Longhorn UI
- **Service**: longhorn-ui-lb
- **External IP**: 192.168.0.211
- **Port**: 80 → 8000
- **Access URL**: http://192.168.0.211

## Verification

### Pod Status
All MetalLB pods running successfully:
- controller-865d8c9c64-dbj4k: Running
- speaker pods on all 9 nodes: Running

### Test Results
- ✅ Test nginx deployment received IP 192.168.0.210
- ✅ Longhorn UI accessible via LoadBalancer IP
- ✅ HTTP connectivity verified

## Files Created
1. `ip-pool.yaml` - IP address pool and L2 advertisement configuration
2. `test-service.yaml` - Test deployment and service (cleaned up after verification)
3. `longhorn-ui-lb.yaml` - LoadBalancer service for Longhorn UI

## Usage Notes
- Services of type LoadBalancer will automatically receive IPs from the pool
- IPs are allocated sequentially starting from 192.168.0.210
- L2 mode works without BGP router configuration
- ARP requests handled by speaker pods on each node

## Next Steps
Any service requiring external access can now use `type: LoadBalancer` and will automatically receive an IP from the MetalLB pool.

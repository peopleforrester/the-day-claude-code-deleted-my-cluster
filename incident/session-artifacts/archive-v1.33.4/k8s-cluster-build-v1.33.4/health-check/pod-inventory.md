# Complete Pod Inventory - 104 Pods Explained
Date: 2025-08-25

## Why 104 Pods?

The 104 pods are essential components for a production-ready Kubernetes cluster with HA, CNI, storage, and load balancing. Here's the breakdown:

## kube-system namespace (55 pods)

### Control Plane Components (15 pods)
These run only on control plane nodes (k8s01-03):
- **kube-apiserver** (3 pods) - API server for Kubernetes, one per control plane
- **kube-controller-manager** (3 pods) - Manages controller loops, one per control plane
- **kube-scheduler** (3 pods) - Schedules pods to nodes, one per control plane
- **etcd** (3 pods) - Key-value store for cluster state, one per control plane
- **kube-vip** (3 pods) - Provides VIP (192.168.0.200) for HA API access

### Essential System Services (11 pods)
These run on ALL nodes:
- **kube-proxy** (9 pods) - Network proxy on each node for service routing
- **coredns** (2 pods) - DNS service for the cluster (replicated for HA)

### CNI - Cilium Network (19 pods)
Provides pod networking and security:
- **cilium** (9 pods) - Main CNI agent, one per node
- **cilium-envoy** (9 pods) - L7 proxy for advanced networking, one per node
- **cilium-operator** (1 pod) - Manages Cilium resources cluster-wide
- **hubble-relay** (1 pod) - Network observability relay

### CNI - Multus (9 pods)
Secondary CNI for multiple network interfaces:
- **kube-multus-ds** (9 pods) - Meta-plugin for multiple networks, one per node

## longhorn-system namespace (39 pods)

### Storage Controllers (13 pods)
Manage storage operations:
- **csi-attacher** (3 pods) - Attaches volumes to nodes
- **csi-provisioner** (3 pods) - Creates/deletes volumes
- **csi-resizer** (3 pods) - Handles volume expansion
- **csi-snapshotter** (3 pods) - Manages volume snapshots
- **longhorn-driver-deployer** (1 pod) - Deploys CSI driver

### Storage Data Plane (24 pods)
Handle actual storage operations on workers:
- **longhorn-manager** (6 pods) - Storage manager, one per worker
- **longhorn-csi-plugin** (6 pods) - CSI plugin, one per worker
- **engine-image** (6 pods) - Container image for volume engines
- **instance-manager** (6 pods) - Manages volume instances

### Storage UI (2 pods)
- **longhorn-ui** (2 pods) - Web UI for storage management

## metallb-system namespace (10 pods)

### Load Balancer Components
Provides LoadBalancer service type:
- **controller** (1 pod) - Manages IP allocation
- **speaker** (9 pods) - Handles ARP/NDP on each node

## Summary: Why This Many?

The pod count is HIGH but NORMAL because:

1. **High Availability**: Critical components (API server, controller, scheduler, etcd) run 3 copies
2. **DaemonSets**: Many components run on EVERY node (9 nodes):
   - kube-proxy (9)
   - cilium (9)
   - cilium-envoy (9)
   - multus (9)
   - metallb-speaker (9)
3. **Worker Services**: Storage components run on each worker (6 workers):
   - longhorn-manager (6)
   - longhorn-csi-plugin (6)
   - engine-image (6)
   - instance-manager (6)
4. **Replicated Services**: For reliability:
   - CoreDNS (2 replicas)
   - Longhorn UI (2 replicas)
   - CSI controllers (3 replicas each)

## Is This Normal?

**YES** - For a 9-node cluster with:
- HA control plane (3 masters)
- Advanced CNI (Cilium + Multus)
- Distributed storage (Longhorn)
- Load balancing (MetalLB)

Each component is necessary:
- **Remove Cilium**: No pod networking
- **Remove Longhorn**: No persistent storage
- **Remove MetalLB**: No LoadBalancer services
- **Remove Multus**: No multi-network support for VMs

This is actually quite efficient for a production-ready cluster with these capabilities!

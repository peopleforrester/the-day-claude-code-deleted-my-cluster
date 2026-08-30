# Network Configuration Issue

## Problem
All VMs are accessible via 192.168.0.x addresses from the host, but internally they all show the same IP address (10.0.2.2) on their primary interface. This suggests:

1. The VMs are behind NAT or a proxy
2. The 192.168.0.x addresses are external/management IPs
3. The VMs cannot bind to the 192.168.0.x addresses directly

## Impact
- etcd cannot bind to 192.168.0.183:2380
- kube-apiserver cannot start without etcd
- Cluster initialization fails

## Potential Solutions
1. Find the actual internal network interfaces that can communicate between VMs
2. Use a different network configuration for Kubernetes
3. Set up port forwarding or tunneling
4. Reconfigure the VMs with proper networking

## Current State
- Kubernetes packages installed
- kube-vip configured but not functional
- Containerd moved to /data to save space
- Multiple initialization attempts failed due to network issues

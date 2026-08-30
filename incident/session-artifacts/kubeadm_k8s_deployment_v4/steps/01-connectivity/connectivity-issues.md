# Connectivity Test Results - Step 01

## Summary

Only 1 out of 5 nodes is currently accessible via SSH.

## Issues Found

1. **master2 (192.168.0.101)**: Permission denied - SSH authentication failed
2. **master3 (192.168.0.102)**: Permission denied - SSH authentication failed
3. **worker1 (192.168.0.103)**: Connection timeout - Node may be down or network issue
4. **worker2 (192.168.0.104)**: Permission denied - SSH authentication failed

## Accessible Nodes

- **master1 (192.168.0.100)**: Successfully connected
  - OS: Ubuntu 24.04.2 LTS
  - Kernel: 6.8.0-64-generic
  - CPU: 2 cores
  - Memory: 3.8Gi
  - Disk: 22G

## Required Actions

To proceed with the Kubernetes cluster deployment, the following must be resolved:

1. SSH key authentication needs to be configured for all nodes
2. Verify all VMs are running and network connectivity exists
3. Ensure root SSH access is enabled on all nodes

## Note

The cluster build cannot proceed until all nodes are accessible. The remaining steps require SSH access to configure and install components on all nodes.

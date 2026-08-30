# Issues Encountered - Step 01

## Issue 1: Network Testing Tools Not Available
**Problem**: ping and nc commands not found on fresh Ubuntu 24.04 installations
**Impact**: Cannot perform inter-node network latency tests
**Resolution**: Document as known issue; will install iputils-ping and netcat-openbsd in Step 02
**Status**: Documented for next step

## Issue 2: IP Forwarding Disabled
**Problem**: net.ipv4.ip_forward=0 on all nodes
**Impact**: Required for Kubernetes networking
**Resolution**: Will enable in Step 02 via sysctl
**Status**: Ready to fix

## Issue 3: Swap Enabled
**Problem**: All nodes have swap enabled (4-8GB)
**Impact**: Kubernetes recommends disabling swap
**Resolution**: Will disable permanently in Step 02
**Status**: Ready to fix

## Non-Issues (Confirmed OK)
- SSH connectivity: Working perfectly
- OS version: Ubuntu 24.04.3 LTS as required
- Cgroup v2: Active and ready
- Hardware resources: All exceed minimums
- DNS resolution: Working on all nodes

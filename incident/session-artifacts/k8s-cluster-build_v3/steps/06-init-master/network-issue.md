# Network Configuration Issue

## Problem
All VMs are configured with the same internal IP address (10.0.2.2) which appears to be a NAT configuration. This prevents Kubernetes from working properly as:

1. Each node needs a unique IP address
2. Nodes must be able to communicate with each other directly
3. etcd cannot bind to 192.168.0.100 because that IP doesn't exist on the interface

## Current Setup
- External IPs: 192.168.0.100-104 (accessible via SSH)
- Internal IPs: All nodes show 10.0.2.2
- Network interface: enp1s0

## Required Fix
The VMs need to be reconfigured with bridged networking or another setup where:
1. Each VM has a unique IP address on the same subnet
2. VMs can communicate directly with each other
3. The IP addresses are stable and match what we're using in the configuration

## Temporary Workaround Attempted
Tried using the internal IP (10.0.2.2) but this fails because:
- All nodes have the same IP
- Multi-node cluster requires unique IPs per node
- etcd peers cannot communicate

## Recommendation
The VM network configuration needs to be changed from NAT to Bridged Adapter or similar before proceeding with the Kubernetes installation.

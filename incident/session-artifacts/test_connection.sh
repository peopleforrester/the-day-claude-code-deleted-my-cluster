#!/bin/bash
# ABOUTME: Script to test SSH connectivity to all cluster nodes
# ABOUTME: Helps verify credentials and connectivity before deployment

echo "Testing SSH connectivity to Kubernetes cluster nodes"
echo "Default credentials: User=claude, Password=<REDACTED-PASSWORD>"
echo ""

# Test each node
echo "Testing master (192.168.0.183)..."
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no claude@192.168.0.183 'hostname && echo "✓ Connected successfully"'

echo ""
echo "Testing worker1 (192.168.0.191)..."
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no claude@192.168.0.191 'hostname && echo "✓ Connected successfully"'

echo ""
echo "Testing worker2 (192.168.0.194)..."
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no claude@192.168.0.194 'hostname && echo "✓ Connected successfully"'

echo ""
echo "Testing worker3 (192.168.0.196)..."
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no claude@192.168.0.196 'hostname && echo "✓ Connected successfully"'

echo ""
echo "Testing worker4 (192.168.0.197)..."
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no claude@192.168.0.197 'hostname && echo "✓ Connected successfully"'

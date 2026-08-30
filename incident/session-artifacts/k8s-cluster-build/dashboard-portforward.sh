#!/bin/bash
# ABOUTME: Direct port forwarding for Kubernetes Dashboard
# ABOUTME: Uses kubectl port-forward instead of proxy

echo "Setting up Kubernetes Dashboard port forwarding..."

# Port forward both web and API services
echo "Starting port forwards..."
echo "Dashboard will be available at: http://localhost:8080"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Run port forwards through SSH
ssh root@192.168.0.100 '
kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard-web 8080:8000 --address=0.0.0.0 &
PID1=$!
kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard-api 9000:9000 --address=0.0.0.0 &
PID2=$!
echo "Port forwarding started. Press Ctrl+C to stop..."
wait $PID1 $PID2
'

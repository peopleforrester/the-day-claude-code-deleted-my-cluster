#!/bin/bash
# ABOUTME: Install Ingress-NGINX v1.13.1 controller
# ABOUTME: Provides ingress capabilities for the cluster

set -e

INGRESS_VERSION="v1.13.1"

echo "=== Installing Ingress-NGINX Controller ${INGRESS_VERSION} ==="

export KUBECONFIG=/etc/kubernetes/admin.conf

# Deploy Ingress-NGINX using the official manifest
echo "1. Downloading Ingress-NGINX ${INGRESS_VERSION} manifest..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${INGRESS_VERSION}/deploy/static/provider/baremetal/deploy.yaml

# Wait for the controller to be ready
echo "2. Waiting for Ingress-NGINX controller to be ready..."
kubectl -n ingress-nginx rollout status deployment ingress-nginx-controller --timeout=180s

# Verify the installation
echo "3. Verifying Ingress-NGINX installation..."
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Check version
echo "4. Checking Ingress-NGINX version..."
kubectl get deployment ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.template.spec.containers[0].image}'

echo ""
echo "=== Ingress-NGINX ${INGRESS_VERSION} Installation Complete ==="
echo ""
echo "NodePort Service available at:"
kubectl get svc ingress-nginx-controller -n ingress-nginx

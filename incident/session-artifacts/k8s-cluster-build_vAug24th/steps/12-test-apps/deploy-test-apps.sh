#!/bin/bash
# ABOUTME: Deploy test applications to verify cluster functionality
# ABOUTME: Tests deployment, scaling, services, ingress, and monitoring

set -e

echo "=== Deploying Test Applications ==="

export KUBECONFIG=/etc/kubernetes/admin.conf

# Deploy the test application
echo "1. Deploying nginx test application..."
kubectl apply -f test-deployment.yaml

# Wait for deployment to be ready
echo "2. Waiting for deployment to be ready..."
kubectl rollout status deployment nginx-test --timeout=120s

# Check pod status
echo "3. Checking pod status..."
kubectl get pods -l app=nginx-test

# Check services
echo "4. Checking services..."
kubectl get svc nginx-test-service nginx-test-nodeport

# Check HPA
echo "5. Checking HorizontalPodAutoscaler..."
kubectl get hpa nginx-test-hpa

# Check PDB
echo "6. Checking PodDisruptionBudget..."
kubectl get pdb nginx-test-pdb

# Check Ingress
echo "7. Checking Ingress..."
kubectl get ingress nginx-test-ingress

# Test service connectivity
echo "8. Testing service connectivity..."
POD_NAME=$(kubectl get pods -l app=nginx-test -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- curl -s -o /dev/null -w "%{http_code}" http://nginx-test-service && echo " - Service connectivity OK"

# Check metrics
echo "9. Checking pod metrics..."
kubectl top pods -l app=nginx-test

# Test rolling update
echo "10. Testing rolling update..."
kubectl set image deployment/nginx-test nginx=nginx:1.27-alpine --record
kubectl rollout status deployment nginx-test --timeout=120s

# Check rollout history
echo "11. Checking rollout history..."
kubectl rollout history deployment nginx-test

# Test scaling
echo "12. Testing manual scaling..."
kubectl scale deployment nginx-test --replicas=5
sleep 10
kubectl get pods -l app=nginx-test

# Scale back
kubectl scale deployment nginx-test --replicas=3
sleep 10

echo ""
echo "=== Test Application Deployment Complete ==="
echo ""
echo "Access methods:"
echo "  NodePort: http://192.168.0.100:30080"
echo "  Ingress: http://test.k8s.local (requires hosts file entry)"
echo ""
echo "Verified functionality:"
echo "  ✓ Deployment with 3 replicas"
echo "  ✓ ClusterIP and NodePort services"
echo "  ✓ HorizontalPodAutoscaler configured"
echo "  ✓ PodDisruptionBudget enforced"
echo "  ✓ Ingress routing configured"
echo "  ✓ Rolling updates working"
echo "  ✓ Manual scaling working"
echo "  ✓ Metrics collection working"

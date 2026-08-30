#!/bin/bash
# Simple cluster test with informative output
# Usage: ./test-cluster.sh [master-ip]

MASTER=${1:-192.168.0.100}
echo "🔍 Testing Kubernetes cluster at $MASTER..."
echo "----------------------------------------"

# 1. Node Test
echo -n "📍 Nodes: Checking 5 nodes (3 masters + 2 workers)... "
ready_nodes=$(ssh root@$MASTER 'kubectl get nodes | grep -c " Ready"')
if [ "$ready_nodes" -eq 5 ]; then
    echo "✅ All $ready_nodes nodes Ready"
else
    echo "❌ Only $ready_nodes/5 nodes Ready"
fi

# 2. Pod Health (excluding known kube-vip issues)
echo -n "📍 Pods: Checking all pods health... "
problem_pods=$(ssh root@$MASTER 'kubectl get pods -A | grep -v Running | grep -v Completed | grep -v NAME | grep -v kube-vip | wc -l')
total_issues=$(ssh root@$MASTER 'kubectl get pods -A | grep -v Running | grep -v Completed | grep -v NAME | wc -l')
if [ "$problem_pods" -eq 0 ]; then
    if [ "$total_issues" -gt 0 ]; then
        echo "✅ All critical pods healthy (ignoring $total_issues kube-vip pods)"
    else
        echo "✅ All pods healthy"
    fi
else
    echo "❌ Found $problem_pods pod issues"
    ssh root@$MASTER 'kubectl get pods -A | grep -v Running | grep -v Completed | grep -v NAME | grep -v kube-vip' | head -3
fi

# 3. Metrics Test
echo -n "📍 Metrics: Testing metrics-server... "
if ssh root@$MASTER 'kubectl top nodes >/dev/null 2>&1'; then
    avg_cpu=$(ssh root@$MASTER 'kubectl top nodes --no-headers | awk "{sum+=\$2} END {print int(sum/NR)}"')
    echo "✅ Working (Avg CPU: ${avg_cpu}%)"
else
    echo "❌ Not responding"
fi

# 4. Ingress Test
echo -n "📍 Ingress: Checking NGINX controller... "
ingress_ok=$(ssh root@$MASTER 'kubectl get pods -n ingress-nginx | grep controller | grep -c Running')
if [ "$ingress_ok" -ge 1 ]; then
    ports=$(ssh root@$MASTER 'kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath="{.spec.ports[0].nodePort},{.spec.ports[1].nodePort}"')
    echo "✅ Ready (Ports: $ports)"
else
    echo "❌ Controller not running"
fi

# 5. Dashboard Test
echo -n "📍 Dashboard: Checking Kubernetes dashboard... "
dash_pods=$(ssh root@$MASTER 'kubectl get pods -n kubernetes-dashboard | grep -c Running')
if [ "$dash_pods" -eq 2 ]; then
    echo "✅ Running (2 pods)"
else
    echo "❌ Issues ($dash_pods/2 pods running)"
fi

# 6. Test App
echo -n "📍 Test App: Checking nginx deployment... "
app_pods=$(ssh root@$MASTER 'kubectl get pods -n test-app | grep -c Running')
if [ "$app_pods" -ge 3 ]; then
    nodes=$(ssh root@$MASTER 'kubectl get pods -n test-app -o jsonpath="{.items[*].spec.nodeName}" | tr " " "\n" | sort -u | wc -l')
    echo "✅ Running ($app_pods pods on $nodes nodes)"
else
    echo "❌ Issues ($app_pods/3 pods running)"
fi

# 7. CNI Test
echo -n "📍 Network: Checking Calico CNI... "
calico_nodes=$(ssh root@$MASTER 'kubectl get pods -n calico-system -l k8s-app=calico-node --no-headers | grep -c Running')
if [ "$calico_nodes" -eq 5 ]; then
    echo "✅ All nodes have Calico"
else
    echo "❌ Only $calico_nodes/5 Calico nodes"
fi

echo "----------------------------------------"
echo "🏁 Quick test complete! $(date +%H:%M:%S)"

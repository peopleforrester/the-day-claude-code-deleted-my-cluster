#!/bin/bash
echo "Testing kubectl exec on worker nodes..."
for i in 4 5 6 7 8 9; do
  NODE="k8s0$i"
  kubectl run test-$NODE --image=alpine --overrides="{\"spec\":{\"nodeSelector\":{\"kubernetes.io/hostname\":\"$NODE\"}}}" --restart=Never -- sleep 30 2>/dev/null
done

sleep 5

for i in 4 5 6 7 8 9; do
  NODE="k8s0$i"
  echo -n "$NODE: "
  kubectl exec test-$NODE -- echo "Working" 2>/dev/null || echo "Failed"
done

for i in 4 5 6 7 8 9; do
  kubectl delete pod test-k8s0$i --force --grace-period=0 2>/dev/null
done

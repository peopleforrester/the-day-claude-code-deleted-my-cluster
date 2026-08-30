#!/bin/bash
# Final kubeadm init

ssh root@192.168.0.183 "kubeadm init --config=/root/kubeadm-config.yaml --upload-certs" > steps/06-init-master/kubeadm-init-final.log 2>&1

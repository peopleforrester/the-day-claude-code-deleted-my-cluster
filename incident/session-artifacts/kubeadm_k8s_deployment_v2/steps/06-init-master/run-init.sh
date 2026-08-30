#!/bin/bash
# Run kubeadm init

ssh root@192.168.0.183 "kubeadm init --config=/root/kubeadm-config.yaml --upload-certs"

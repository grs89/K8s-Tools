#!/bin/bash

# This script installs the NFS Subdir External Provisioner to dynamically provision NFS storage in Kubernetes.
# Make sure your NFS server is reachable from all nodes in the cluster.
# Usage:
# chmod +x 01-StorageClass-nfs.sh
# ./01-StorageClass-nfs.sh

set -e

# Configurable values
NFS_SERVER="192.168.20.115"
NFS_PATH="/data/nfs/monitoring"
STORAGE_CLASS_NAME="nfs-client"

echo "🔧 Adding Helm repo for NFS provisioner..."
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

echo "📦 Installing NFS Subdir External Provisioner..."
helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace kube-system \
  --create-namespace \
  --set nfs.server="${NFS_SERVER}" \
  --set nfs.path="${NFS_PATH}" \
  --set storageClass.name="${STORAGE_CLASS_NAME}" \
  --set storageClass.defaultClass=true

echo "✅ NFS Provisioner installed and '${STORAGE_CLASS_NAME}' StorageClass created as default."

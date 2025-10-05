#!/bin/bash

# chmod +x 02-Start.sh
# ./02-Start.sh
# This script installs Zabbix on Kubernetes using Helm
# Make sure the following are ready:
# - A running Kubernetes cluster
# - Helm installed and configured
# - An accessible NFS server and the NFS client provisioner installed in the cluster
# - A custom values file for Zabbix (my-zabbix-values.yaml) is created in the same directory
# - The Zabbix Helm chart is available in the Helm repository
# helm show values zabbix-community/zabbix > my-zabbix-values.yaml
# helm upgrade zabbix zabbix-community/zabbix -n zabbix  -f zabbix-values.yaml

set -e

echo "🔁 Adding and updating Helm repos..."
helm repo add zabbix-community https://zabbix-community.github.io/helm-zabbix
helm repo update

echo "🚀 Installing Zabbix Stack..."
export ZABBIX_CHART_VERSION='7.0.6'
helm install zabbix zabbix-community/zabbix -n zabbix --create-namespace  --version $ZABBIX_CHART_VERSION -f zabbix-values.yaml

echo "✅ Zabbix stack installed successfully!"

echo ""
export NODE_PORT=$(kubectl get --namespace zabbix -o jsonpath="{.spec.ports[0].nodePort}" services zabbix-zabbix-web)
export NODE_IP=$(kubectl get nodes --namespace zabbix -o jsonpath="{.items[0].status.addresses[0].address}")
echo "Access endpoints:"
echo "🔹 Zabbix:  http://$NODE_IP:$NODE_PORT"

  

echo ""
echo "To uninstall everything, run:"
echo "helm uninstall zabbix -n zabbix"

#helm show values zabbix-community/zabbix > zabbix-values.yaml
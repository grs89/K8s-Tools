#!/bin/bash

#chmod +x 02-Start.sh
#./02-Start.sh

# This script installs the monitoring stack (Prometheus, Loki, Tempo) on Kubernetes using Helm
# Make sure the following are ready:
# - A running Kubernetes cluster
# - Helm installed and configured
# - An accessible NFS server and the NFS client provisioner installed in the cluster

set -e

echo "🔁 Adding and updating Helm repos..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo "🚀 Installing Prometheus stack..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.storageClassName=nfs-client \
  --set grafana.persistence.size=5Gi \
  --set grafana.adminPassword='admin' \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=32000 \
  --set 'prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=nfs-client' \
  --set 'prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=10Gi' \
  --set 'prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce'

echo "📦 Installing Loki stack..."
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --create-namespace \
  --set loki.persistence.enabled=true \
  --set loki.persistence.storageClassName=nfs-client \
  --set loki.persistence.size=10Gi \
  --set promtail.enabled=true \
  --set promtail.config.client.url=http://loki:3100/loki/api/v1/push

echo "📦 Installing Tempo..."
helm install tempo grafana/tempo \
  --namespace monitoring \
  --create-namespace \
  --set persistence.enabled=true \
  --set persistence.storageClassName=nfs-client \
  --set 'persistence.accessModes[0]=ReadWriteOnce' \
  --set persistence.size=10Gi \
  --set service.type=NodePort \
  --set service.nodePort=31002 \
  --set tempo.metricsGenerator.enabled=true

echo "✅ Monitoring stack installed successfully!"

echo ""
echo "Access endpoints:"
echo "🔹 Grafana:   http://<node-ip>:32000 (admin/admin)"
echo "🔹 Loki:      http://loki.monitoring.svc.cluster.local:3100"
echo "🔹 Tempo:     http://tempo.monitoring.svc.cluster.local:3100"

echo ""
echo "To uninstall everything, run:"
echo "  helm uninstall prometheus -n monitoring"
echo "  helm uninstall loki -n monitoring"
echo "  helm uninstall tempo -n monitoring"

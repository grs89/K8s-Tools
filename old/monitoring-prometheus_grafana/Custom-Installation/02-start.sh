#!/bin/bash

# -----------------------------------------------------------------------------
# Script para instalar el stack de monitoreo en Kubernetes con Helm
# Componentes: Prometheus, Loki, Tempo
# Requiere los archivos: values.yaml, loki-values.yaml, tempo-values.yaml
# chmod +x 02-start.sh
# ./02-start.sh
# -----------------------------------------------------------------------------

set -e

echo "🚀 Agregando repositorios de Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update


#helm upgrade prometheus prometheus-community/kube-prometheus-stack \
#  --namespace monitoring \
#  -f prometheus-values.yaml

echo "📦 Instalando Prometheus (kube-prometheus-stack)..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f prometheus-values.yaml

echo "📦 Instalando Loki stack..."
helm install loki grafana/loki-stack \
  --namespace monitoring --create-namespace \
  -f loki-values.yaml

echo "📦 Instalando Tempo..."
helm install tempo grafana/tempo \
  --namespace monitoring --create-namespace \
  -f tempo-values.yaml

echo ""
echo "✅ Stack de monitoreo desplegado correctamente"
echo "➡️  Para acceder a Grafana: http://<node-ip>:<port> (según lo definido en values.yaml)"

echo ""
echo "To uninstall everything, run:"
echo "  helm uninstall prometheus -n monitoring"
echo "  helm uninstall loki -n monitoring"
echo "  helm uninstall tempo -n monitoring"
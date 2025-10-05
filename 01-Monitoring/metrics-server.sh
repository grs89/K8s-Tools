#!/bin/bash

echo "🚀 Instalando Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "✅ Aplicando patch para permitir conexiones inseguras al kubelet..."
kubectl patch deployment metrics-server -n kube-system \
  --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

echo "⏳ Esperando que los pods del Metrics Server estén listos..."
kubectl rollout status deployment/metrics-server -n kube-system

echo "📊 Verificando métricas..."
kubectl top nodes
kubectl top pods -A

echo "✅ Instalación completada."

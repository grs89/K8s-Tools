#!/bin/bash

echo "🚀 Instalando Kubernetes Dashboard..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

echo "✅ Cambiando el servicio a NodePort (puerto 32000)..."
kubectl -n kubernetes-dashboard patch service kubernetes-dashboard \
  -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "targetPort": 8443, "nodePort": 32000}]}}'

echo "📝 Creando archivo dashboard-admin.yaml..."
cat <<EOF > dashboard-admin.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

echo "✅ Aplicando dashboard-admin.yaml..."
kubectl apply -f dashboard-admin.yaml

echo "⏳ Esperando que el Dashboard esté disponible..."
kubectl rollout status deployment/kubernetes-dashboard -n kubernetes-dashboard

# Obtener IP del nodo automáticamente
NODE_IP=$(kubectl get nodes -o wide | awk 'NR==2{print $6}')

echo "✅ Instalación completada."
echo "🌐 Acceso: https://${NODE_IP}:32000"
echo "🔑 Para obtener el token de acceso, ejecuta:"
echo "kubectl -n kubernetes-dashboard create token admin-user"


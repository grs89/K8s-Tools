#!/bin/bash

set -e

NAMESPACE="argocd"
RELEASE_NAME="argocd"
NODE_PORT=32080  # Puerto base para HTTP, HTTPS será +1
STORAGE_CLASS="nfs-client"  # Cambia este valor si usas otro SC

echo "➡️ Creando namespace $NAMESPACE..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "➡️ Agregando el repositorio de Helm de Argo CD..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "➡️ Creando archivo de configuración argocd-values.yaml..."
cat <<EOF > argocd-values.yaml
server:
  service:
    type: NodePort
    nodePortHttp: $NODE_PORT
    nodePortHttps: $((NODE_PORT+1))
    ports:
      http: 80
      https: 443

redis:
  metrics:
    enabled: true
  persistence:
    enabled: true
    size: 1Gi
    storageClass: $STORAGE_CLASS
EOF

echo "➡️ Instalando Argo CD con Helm usando el archivo de configuración..."
helm install $RELEASE_NAME argo/argo-cd -n $NAMESPACE -f argocd-values.yaml

echo "✅ Argo CD instalado en el namespace '$NAMESPACE'."

echo "⏳ Esperando unos segundos para que se cree el secret inicial..."
sleep 10

echo "🔐 Contraseña inicial del usuario 'admin':"
kubectl -n $NAMESPACE get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Obtener IP interna del primer nodo
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo "🌐 Puedes acceder a la UI de Argo CD en:"
echo "➡️  https://$NODE_IP:$((NODE_PORT+1))"


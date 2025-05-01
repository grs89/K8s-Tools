#!/bin/bash

set -e

NAMESPACE="argocd"
RELEASE_NAME="argocd"
NODE_PORT=32080  # Cambia si necesitas un puerto diferente

echo "➡️ Creando namespace $NAMESPACE..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "➡️ Agregando el repositorio de Helm de Argo CD..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "➡️ Creando archivo de configuración para NodePort..."
cat <<EOF > argocd-values.yaml
server:
  service:
    type: NodePort
    nodePortHttp: $NODE_PORT
    nodePortHttps: $((NODE_PORT+1))
    ports:
      http: 80
      https: 443
EOF

echo "➡️ Instalando Argo CD con servicio tipo NodePort..."
helm install $RELEASE_NAME argo/argo-cd -n $NAMESPACE -f argocd-values.yaml

echo "✅ Argo CD instalado en el namespace '$NAMESPACE'."

echo "⏳ Esperando unos segundos para que se cree el secret inicial..."
sleep 10

echo "🔐 Contraseña inicial del usuario 'admin':"
kubectl -n $NAMESPACE get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo "🌐 Puedes acceder a la UI de Argo CD en:"
echo "➡️  https://$NODE_IP:$((NODE_PORT+1))"

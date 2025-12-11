# Troubleshooting - K8s-Tools

Guía de solución de problemas comunes al usar K8s-Tools.

## 📋 Índice

- [Problemas Generales](#problemas-generales)
- [Kubernetes Dashboard](#kubernetes-dashboard)
- [Metrics Server](#metrics-server)
- [NFS Storage](#nfs-storage)
- [ArgoCD](#argocd)
- [Helm](#helm)

---

## Problemas Generales

### ❌ Error: "kubectl: command not found"

**Problema**: kubectl no está instalado o no está en el PATH.

**Solución**:
```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verificar
kubectl version --client
```

### ❌ Error: "The connection to the server was refused"

**Problema**: No hay conexión al cluster de Kubernetes.

**Solución**:
```bash
# Verificar que tienes un kubeconfig válido
kubectl cluster-info

# Verificar contexto actual
kubectl config current-context

# Listar contextos disponibles
kubectl config get-contexts

# Cambiar a otro contexto
kubectl config use-context <nombre-contexto>

# Si usas un kubeconfig específico
export KUBECONFIG=/path/to/your/kubeconfig
```

### ❌ Error: "error: You must be logged in to the server (Unauthorized)"

**Problema**: Credenciales inválidas o expiradas.

**Solución**:
```bash
# Verificar la configuración actual
kubectl config view

# Reautenticar con tu provider de cluster
# (el comando depende de tu proveedor: AWS, GCP, Azure, etc.)
```

### ❌ Pods en estado "Pending"

**Problema**: Los pods no se pueden programar.

**Diagnóstico**:
```bash
# Ver detalles del pod
kubectl describe pod <pod-name> -n <namespace>

# Verificar eventos
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Verificar recursos disponibles en los nodos
kubectl top nodes
kubectl describe nodes
```

**Causas comunes**:
1. **Recursos insuficientes**: No hay CPU/memoria disponible
   - Solución: Escalar el cluster o reducir requests/limits
   
2. **No hay nodos disponibles**: Todos los nodos tienen taints
   - Solución: Agregar tolerations o remover taints

3. **PVC no puede ser aprovisionado**: StorageClass no disponible
   - Solución: Instalar storage provisioner (NFS, etc.)

---

## Kubernetes Dashboard

### ❌ Error: "services 'kubernetes-dashboard' not found"

**Problem**: El dashboard no se instaló correctamente.

**Solución**:
```bash
# Verificar si el namespace existe
kubectl get namespace kubernetes-dashboard

# Verificar los recursos
kubectl get all -n kubernetes-dashboard

# Reinstalar si es necesario
./01-Monitoring/01-kubernetes-dashboard/kubernetes-dashboard.sh
```

### ❌ No puedo acceder a la URL del Dashboard

**Diagnóstico**:
```bash
# Verificar que el servicio esté en NodePort
kubectl get svc -n kubernetes-dashboard

# Verificar que el pod esté corriendo
kubectl get pods -n kubernetes-dashboard

# Ver logs del pod
kubectl logs -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard
```

**Soluciones**:
1. **Firewall bloqueando el puerto**
   - Verifica que el puerto 32000 esté abierto en el firewall
   
2. **Certificado SSL autofirmado**
   - En el navegador, acepta el riesgo de seguridad (solo para dev/test)
   - O usa port-forward: `kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8443:443`

### ❌ Token de acceso inválido

**Solución**:
```bash
# Crear un nuevo token
kubectl -n kubernetes-dashboard create token admin-user

# O crear token de larga duración (no recomendado en producción)
kubectl -n kubernetes-dashboard create token admin-user --duration=87600h
```

---

## Metrics Server

### ❌ Error: "the server could not find the requested resource (get services http:heapster:)"

**Problema**: Metrics Server aún no está completamente desplegado.

**Solución**:
```bash
# Esperar un momento y verificar el estado
kubectl rollout status deployment/metrics-server -n kube-system

# Verificar logs
kubectl logs -n kube-system -l k8s-app=metrics-server
```

### ❌ Error: "unable to get metrics for resource cpu"

**Problema**: Metrics Server no puede conectarse a los kubelets.

**Diagnóstico**:
```bash
# Verificar logs del Metrics Server
kubectl logs -n kube-system deployment/metrics-server

# Buscar errores de certificados
```

**Soluciones**:

1. **En ambientes de desarrollo** (ya aplicado en nuestro script):
   ```bash
   # El flag --kubelet-insecure-tls está configurado
   ```

2. **En producción**:
   - Configurar certificados válidos para los kubelets
   - Remover el flag `--kubelet-insecure-tls`

### ❌ "kubectl top" no muestra métricas

**Problema**: Las métricas aún no se han recopilado.

**Solución**:
```bash
# Esperar 1-2 minutos después de la instalación
# Las métricas se recopilan cada 60 segundos

# Verificar que el API de métricas esté disponible
kubectl get apiservices | grep metrics

# Debería mostrar:
# v1beta1.metrics.k8s.io         kube-system/metrics-server   True
```

---

## NFS Storage

### ❌ Error: "ping: cannot resolve <NFS_SERVER>"

**Problema**: No se puede alcanzar el servidor NFS.

**Solución**:
```bash
# Verificar conectividad desde tu máquina
ping <NFS_SERVER>

# Verificar desde un pod en el cluster
kubectl run -it --rm debug --image=busybox --restart=Never -- ping <NFS_SERVER>

# Verificar DNS
nslookup <NFS_SERVER>
```

### ❌ PVCs permanecen en estado "Pending"

**Diagnóstico**:
```bash
# Describir el PVC
kubectl describe pvc <pvc-name> -n <namespace>

# Ver eventos
kubectl get events -n <namespace> --field-selector involvedObject.name=<pvc-name>

# Verificar logs del provisioner
kubectl logs -n kube-system -l app=nfs-subdir-external-provisioner
```

**Causas comunes**:

1. **Servidor NFS no accesible desde los nodos**:
   ```bash
   # Probar montaje manual desde un nodo
   sudo mount -t nfs <NFS_SERVER>:<NFS_PATH> /mnt
   ```

2. **Paquetes NFS no instalados en los nodos**:
   ```bash
   # En cada nodo (Ubuntu/Debian)
   sudo apt-get install -y nfs-common
   
   # En cada nodo (RHEL/CentOS)
   sudo yum install -y nfs-utils
   ```

3. **Permisos en el servidor NFS**:
   - Verificar que el export tenga permisos correctos
   - Verificar `/etc/exports` en el servidor NFS

### ❌ Error: "mount.nfs: access denied by server"

**Problema**: Permisos de NFS incorrectos.

**Solución en el servidor NFS**:
```bash
# Editar /etc/exports
sudo nano /etc/exports

# Agregar o modificar la línea (ajustar subnet):
/data/nfs/monitoring 192.168.10.0/24(rw,sync,no_subtree_check,no_root_squash)

# Recargar exports
sudo exportfs -ra

# Verificar
sudo exportfs -v
```

---

## ArgoCD

### ❌ No puedo acceder a la UI de ArgoCD

**Diagnóstico**:
```bash
# Verificar servicio
kubectl get svc -n argocd

# Verificar pods
kubectl get pods -n argocd

# Ver logs del servidor
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

**Soluciones alternativas**:

1. **Port forwarding**:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   # Acceder en: https://localhost:8080
   ```

2. **Obtener contraseña nuevamente**:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret \
     -o jsonpath="{.data.password}" | base64 -d
   ```

### ❌ Error: "server certificate verification failed"

**Problema**: Certificado SSL autofirmado.

**Soluciones**:
1. Acepta el certificado en el navegador (dev/test)
2. Usa ArgoCD CLI con --insecure flag
3. Configura certificados válidos (producción)

### ❌ Git Repository connection failed

**Problema**: ArgoCD no puede conectarse al repositorio Git.

**Soluciones**:
```bash
# Desde la UI:
# Settings → Repositories → Test Connection

# Verificar conectividad desde un pod de ArgoCD:
kubectl exec -it -n argocd deployment/argocd-server -- \
  argocd repo list
```

Causas comunes:
- Credenciales Git incorrectas
- SSH key no configurad- Repository privado sin acceso
- Firewall bloqueando conexión

---

## Helm

### ❌ Error: "Error: INSTALLATION FAILED: chart requires kubeVersion..."

**Problema**: Versión de Kubernetes incompatible con el chart.

**Solución**:
```bash
# Verificar tu versión de Kubernetes
kubectl version --short

# Usar una versión compatible del chart
# Editar versions.conf y ajustar las versiones
```

### ❌ Error: "Error: release already exists"

**Problema**: Intentando instalar un release que ya existe.

**Soluciones**:
```bash
# Ver releases existentes
helm list -A

# Actualizar en lugar de instalar
helm upgrade <release-name> <chart> -n <namespace>

# O desinstalar primero (⚠️ perderás datos)
helm uninstall <release-name> -n <namespace>
```

### ❌ Error: "Error: repository not found"

**Problema**: Repositorio de Helm no agregado.

**Solución**:
```bash
# Nuestros scripts ya hacen esto, pero manualmente:
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

---

## 🔧 Herramientas de Diagnóstico

### Script de Diagnóstico General

```bash
#!/bin/bash
# diagnostic.sh - Recopila información del cluster

echo "=== Cluster Info ==="
kubectl cluster-info

echo -e "\n=== Nodes ==="
kubectl get nodes -o wide

echo -e "\n=== Namespaces ==="
kubectl get namespaces

echo -e "\n=== Pods en estado no Running ==="
kubectl get pods -A --field-selector=status.phase!=Running

echo -e "\n=== Eventos recientes ==="
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

echo -e "\n=== Storage Classes ==="
kubectl get storageclass

echo -e "\n=== PVCs ==="
kubectl get pvc -A
```

### Verificar Logs de Todos los Componentes

```bash
# Dashboard
kubectl logs -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard --tail=50

# Metrics Server
kubectl logs -n kube-system -l k8s-app=metrics-server --tail=50

# NFS Provisioner
kubectl logs -n kube-system -l app=nfs-subdir-external-provisioner --tail=50

# ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=50
```

---

## 📚 Recursos Adicionales

- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Dashboard](https://github.com/kubernetes/dashboard)
- [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

---

## 💡 ¿No encuentras tu problema?

1. Revisa los logs completos en `/tmp/k8s-tools-*.log`
2. Ejecuta el script de validación: `./scripts/validate.sh`
3. Busca en los Issues del repositorio
4. Abre un nuevo Issue con:
   - Comando ejecutado
   - Error completo
   - Output del script de diagnóstico
   - Versión de Kubernetes

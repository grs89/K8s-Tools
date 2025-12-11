# Componentes de Monitoring

Este directorio contiene scripts para instalar componentes de monitoreo en Kubernetes.

## 📦 Componentes Disponibles

### 1. Kubernetes Dashboard
Interfaz web para gestión visual del cluster de Kubernetes.

- **Ubicación**: `01-kubernetes-dashboard/`
- **Script**: `kubernetes-dashboard.sh`
- **Namespace**: `kubernetes-dashboard`
- **Acceso**: NodePort en puerto 32000 (configurable)

**Instalación**:
```bash
cd 01-kubernetes-dashboard
./kubernetes-dashboard.sh
```

**Uso**:
```bash
# Acceder al Dashboard
# URL: https://<node-ip>:32000

# Obtener token de acceso
kubectl -n kubernetes-dashboard create token admin-user
```

### 2. Metrics Server
Proporciona métricas de CPU y memoria para pods y nodos.

- **Ubicación**: `01-metrics-server/`
- **Script**: `metrics-server.sh`
- **Namespace**: `kube-system`
- **API**: `metrics.k8s.io/v1beta1`

**Instalación**:
```bash
cd 01-metrics-server
./metrics-server.sh
```

**Uso**:
```bash
# Ver métricas de nodos
kubectl top nodes

# Ver métricas de pods
kubectl top pods -A

# Ver métricas de un namespace específico
kubectl top pods -n <namespace>
```

## 🔗 Dependencias

- **Kubernetes**: v1.20+
- **kubectl**: Configurado con acceso al cluster
- **Permisos**: Acceso admin al cluster

## 📖 Más Información

- Ver [README principal](../README.md) para configuración general
- Ver [TROUBLESHOOTING](../docs/TROUBLESHOOTING.md) para solución de problemas
- Ver [ARCHITECTURE](../docs/ARCHITECTURE.md) para detalles de arquitectura

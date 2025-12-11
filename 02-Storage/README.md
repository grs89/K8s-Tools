# Storage Components

Este directorio contiene scripts para configurar almacenamiento dinámico en Kubernetes.

## 📦 Componentes Disponibles

### NFS Subdir External Provisioner

Provisioner dinámico que utiliza un servidor NFS para crear PersistentVolumes automáticamente.

- **Script**: `NFS-StorageClass.sh`
- **Namespace**: `kube-system`
- **StorageClass**: `nfs-client` (configurable)
- **Tipo**: Dynamic Provisioner

## 🚀 Instalación

### Prerrequisitos

1. **Servidor NFS** configurado y accesible desde todos los nodos del cluster
2. **Paquetes NFS** instalados en los nodos:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install -y nfs-common
   
   # RHEL/CentOS
   sudo yum install -y nfs-utils
   ```

### Configuración

1. Edita `config.env` (copia desde `config.env.example` si no existe):
   ```bash
   cp ../config.env.example ../config.env
   nano ../config.env
   ```

2. Configura las variables NFS:
   ```bash
   NFS_SERVER="192.168.10.112"          # IP de tu servidor NFS
   NFS_PATH="/data/nfs/monitoring"      # Ruta compartida en el servidor
   STORAGE_CLASS_NAME="nfs-client"      # Nombre de la StorageClass
   ```

3. Ejecuta el script:
   ```bash
   ./NFS-StorageClass.sh
   ```

## 📝 Uso

### Crear un PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mi-pvc
spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

```bash
kubectl apply -f mi-pvc.yaml
```

### Usar en un Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mi-app
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /usr/share/nginx/html
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: mi-pvc
```

## 🔍 Verificación

```bash
# Ver la StorageClass creada
kubectl get storageclass

# Ver PVs dinámicamente creados
kubectl get pv

# Ver PVCs
kubectl get pvc -A

# Ver deployment del provisioner
kubectl get deployment -n kube-system -l app=nfs-subdir-external-provisioner
```

## 🗂️ Estructura de Directorios en NFS

El provisioner crea subdirectorios en el servidor NFS con el formato:
```
<namespace>-<pvc-name>-<pv-name>
```

Ejemplo:
```
/data/nfs/monitoring/
├── default-mi-pvc-pvc-abc123/
├── databases-data-postgres-0-pvc-def456/
└── monitoring-prometheus-data-pvc-ghi789/
```

## ⚙️ Access Modes Soportados

- **ReadWriteOnce (RWO)**: Montable como read-write por un solo nodo
- **ReadWriteMany (RWX)**: Montable como read-write por múltiples nodos (ventaja de NFS)
- **ReadOnlyMany (ROX)**: Montable como read-only por múltiples nodos

## 🗑️ Reclaim Policy

Por defecto el provisioner usa `Delete`:
- Al eliminar el PVC, se elimina el PV **y los datos en NFS**
- Para retener datos, configura la reclaim policy a `Retain`

## 🔧 Troubleshooting

### PVC permanece en Pending
```bash
# Verificar eventos
kubectl describe pvc <pvc-name>

# Ver logs del provisioner
kubectl logs -n kube-system -l app=nfs-subdir-external-provisioner
```

### Error de montaje NFS
```bash
# Desde un nodo, probar montaje manual
sudo mount -t nfs <NFS_SERVER>:<NFS_PATH> /mnt

# Verificar que paquetes NFS estén instalados
dpkg -l | grep nfs-common  # Debian/Ubuntu
rpm -qa | grep nfs-utils   # RHEL/CentOS
```

## 📖 Más Información

- [NFS Provisioner GitHub](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner)
- Ver [TROUBLESHOOTING](../docs/TROUBLESHOOTING.md) para más ayuda
- Ver [ARCHITECTURE](../docs/ARCHITECTURE.md) para entender el flujo de aprovisionamiento

# K8s-Tools

> Colección de scripts automatizados para instalación de herramientas esenciales en Kubernetes

K8s-Tools es un conjunto de scripts de Bash que facilitan la instalación y configuración de componentes comunes en clusters de Kubernetes, incluyendo monitoring, almacenamiento dinámico y aplicaciones GitOps.

## 📦 Componentes Disponibles

| Categoría | Componente | Descripción | Script |
|-----------|------------|-------------|--------|
| **Monitoring** | Kubernetes Dashboard | UI web para gestión visual del cluster | [01-kubernetes-dashboard](01-Monitoring/01-kubernetes-dashboard/) |
| **Monitoring** | Metrics Server | Métricas de CPU/memoria para pods y nodos | [01-metrics-server](01-Monitoring/01-metrics-server/) |
| **Storage** | NFS Provisioner | Aprovisionamiento dinámico de volúmenes NFS | [NFS-StorageClass.sh](02-Storage/) |
| **Apps** | ArgoCD | Continuous Delivery basado en GitOps | [Argocd](03-Apps/Argocd/) |

## 🚀 Inicio Rápido

### Prerrequisitos

Antes de usar estos scripts, asegúrate de tener:

- ✅ **Kubernetes cluster** operativo (v1.20+)
- ✅ **kubectl** instalado y configurado
- ✅ **Helm 3** instalado (v3.0+)
- ✅ **Acceso admin** al cluster (kubeconfig configurado)
- ✅ **Servidor NFS** accesible (solo para storage NFS)<parameter name="bash">
# Verificar prerrequisitos
kubectl version --client
helm version
kubectl cluster-info
```

### Configuración

1. **Clona el repositorio** (o descarga los scripts):
   ```bash
   git clone <tu-repo>/K8s-Tools.git
   cd K8s-Tools
   ```

2. **Configura tus variables de entorno**:
   ```bash
   # Copia el archivo de ejemplo
   cp config.env.example config.env
   
   # Edita config.env con tus valores
   nano config.env
   ```

3. **Revisa las versiones** de componentes en `versions.conf` (opcional).

### Instalación de Componentes

#### Opción 1: Instalación Básica (un componente)

```bash
# Ejemplo: Instalar Kubernetes Dashboard
cd 01-Monitoring/01-kubernetes-dashboard
./kubernetes-dashboard.sh
```

#### Opción 2: Instalación Completa

```bash
# 1. Storage (requerido para otros componentes)
./02-Storage/NFS-StorageClass.sh

# 2. Monitoring
./01-Monitoring/01-metrics-server/metrics-server.sh
./01-Monitoring/01-kubernetes-dashboard/kubernetes-dashboard.sh

# 3. Applications
./03-Apps/Argocd/01-argo_cd.sh
```

### Validación

Después de instalar componentes, verifica que todo funcione:

```bash
# Ejecutar script de validación
./scripts/validate.sh
```

## 📖 Documentación Detallada

### Configuración (`config.env`)

El archivo `config.env` (creado desde `config.env.example`) contiene todas las variables configurables:

```bash
# Ejemplo de configuración NFS
NFS_SERVER="192.168.10.112"
NFS_PATH="/data/nfs/monitoring"
STORAGE_CLASS_NAME="nfs-client"

# Puertos NodePort
DASHBOARD_NODEPORT="32000"
ARGOCD_HTTP_PORT="32080"
```

### Versiones (`versions.conf`)

Control centralizado de versiones de todos los componentes. Edita este archivo para actualizar o fijar versiones específicas:

```bash
DASHBOARD_VERSION="v2.7.0"
ARGOCD_CHART_VERSION="5.51.6"
METRICS_SERVER_VERSION="v0.7.0"
```

## 🔧 Uso de Scripts Individuales

### Kubernetes Dashboard

```bash
cd 01-Monitoring/01-kubernetes-dashboard
./kubernetes-dashboard.sh

# Acceso: https://<node-ip>:32000
# Obtener token:
kubectl -n kubernetes-dashboard create token admin-user
```

### Metrics Server

```bash
cd 01-Monitoring/01-metrics-server
./metrics-server.sh

# Verificar métricas:
kubectl top nodes
kubectl top pods -A
```

### NFS Storage Class

```bash
# Edita config.env primero con tu servidor NFS
cd 02-Storage
./NFS-StorageClass.sh

# Verificar:
kubectl get storageclass
```

### ArgoCD

```bash
cd 03-Apps/Argocd
./01-argo_cd.sh

# Acceso: https://<node-ip>:32081
# Usuario: admin
# Contraseña: (mostrada al finalizar instalación)
```

## 🛠️ Scripts Utilitarios

### `scripts/common.sh`

Biblioteca de funciones compartidas:
- Logging estructurado
- Validación de prerrequisitos
- Gestión de Helm
- Utilidades de Kubernetes

### `scripts/validate.sh`

Valida que los componentes instalados estén funcionando:

```bash
./scripts/validate.sh
```

## 📁 Estructura del Proyecto

```
K8s-Tools/
├── README.md                           # Este archivo
├── config.env.example                  # Plantilla de configuración
├── versions.conf                       # Control de versiones
├── .gitignore                         
│
├── scripts/                           # Scripts compartidos
│   ├── common.sh                      # Funciones compartidas
│   └── validate.sh                    # Validación de instalaciones
│
├── 01-Monitoring/                     # Componentes de monitoreo
│   ├── 01-kubernetes-dashboard/
│   │   └── kubernetes-dashboard.sh
│   └── 01-metrics-server/
│       └── metrics-server.sh
│
├── 02-Storage/                        # Provisionamiento de storage
│   └── NFS-StorageClass.sh
│
├── 03-Apps/                           # Aplicaciones
│   └── Argocd/
│       └── 01-argo_cd.sh
│
└── docs/                              # Documentación adicional
    ├── TROUBLESHOOTING.md
    └── ARCHITECTURE.md
```

## 🐛 Troubleshooting

### Problemas Comunes

1. **Error: "kubectl: command not found"**
   - Instala kubectl: https://kubernetes.io/docs/tasks/tools/

2. **Error: "no hay conexión al cluster"**
   ```bash
   # Verifica tu kubeconfig
   kubectl cluster-info
   export KUBECONFIG=/path/to/your/kubeconfig
   ```

3. **Error en NFS Provisioner: "servidor no accesible"**
   - Verifica que el servidor NFS esté en la misma red
   - Comprueba que los paquetes NFS estén instalados en los nodos

4. **Pods en estado Pending**
   ```bash
   # Ver detalles del pod
   kubectl describe pod <pod-name> -n <namespace>
   
   # Verificar eventos del cluster
   kubectl get events -A --sort-by='.lastTimestamp'
   ```

Ver más en [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## 🔐 Seguridad

> ⚠️ **IMPORTANTE**: Estos scripts están diseñados para entornos de desarrollo y testing.

Para producción:
- ✅ Cambia todas las contraseñas por defecto
- ✅ Usa TLS en todos los servicios
- ✅ Configura RBAC apropiado
- ✅ No uses `--kubelet-insecure-tls` en Metrics Server
- ✅ Protege los archivos `config.env` (ya están en `.gitignore`)

## 🤝 Contribución

Las contribuciones son bienvenidas. Para cambios importantes:

1. Haz fork del proyecto
2. Crea una rama para tu feature (`git checkout -b feature/NuevaCaracteristica`)
3. Commit tus cambios (`git commit -m 'Agrega nueva característica'`)
4. Push a la rama (`git push origin feature/NuevaCaracteristica`)
5. Abre un Pull Request

## 📝 Licencia

Este proyecto está bajo licencia MIT. Ver archivo LICENSE para más detalles.

## 🙏 Reconocimientos

- Kubernetes Team por las excelentes herramientas
- Helm Community por facilitar el deployment
- Comunidad de código abierto

## 📞 Soporte

- 📖 [Documentación](docs/)
- 🐛 [Reportar Bugs](issues)
- 💡 [Solicitar Features](issues)

---

**Hecho con ❤️ para la comunidad de Kubernetes por GRS**

# Applications

Este directorio contiene scripts para instalar aplicaciones en Kubernetes.

## 📦 Aplicaciones Disponibles

### ArgoCD

ArgoCD es una herramienta de Continuous Delivery declarativa para Kubernetes que sigue el paradigma GitOps.

- **Ubicación**: `Argocd/`
- **Script**: `01-argo_cd.sh`
- **Namespace**: `argocd` (configurable)
- **Acceso**: NodePort en puertos 32080 (HTTP) y 32081 (HTTPS)

#### Instalación

```bash
cd Argocd
./01-argo_cd.sh
```

#### Configuración

Edita `../config.env` para personalizar:
```bash
ARGOCD_HTTP_PORT="32080"
ARGOCD_STORAGE_CLASS="nfs-client"
ARGOCD_REDIS_SIZE="1Gi"
```

#### Primer Acceso

1. **Accede a la UI**:
   - URL: `https://<node-ip>:32081`
   - Usuario: `admin`
   - Contraseña: Mostrada al final de la instalación, o ejecuta:
     ```bash
     kubectl -n argocd get secret argocd-initial-admin-secret \
       -o jsonpath="{.data.password}" | base64 -d
     ```

2. **Cambia la contraseña** (recomendado):
   ```bash
   # Usando ArgoCD CLI
   argocd login <node-ip>:32081
   argocd account update-password
   ```

#### Uso Básico

##### Conectar un Repositorio Git

Via UI:
1. Settings → Repositories → Connect Repo
2. Ingresa URL, método de autenticación y credenciales

Via CLI:
```bash
argocd repo add https://github.com/tu-usuario/tu-repo.git \
  --username <usuario> \
  --password <token>
```

##### Crear una Application

```yaml
# app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mi-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/tu-usuario/tu-repo.git
    targetRevision: main
    path: k8s/
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

```bash
kubectl apply -f app.yaml
```

##### CLI Commands

```bash
# Listar aplicaciones
argocd app list

# Ver estado de una aplicación
argocd app get mi-app

# Sincronizar manualmente
argocd app sync mi-app

# Ver logs de sync
argocd app sync mi-app --log
```

## 🔗 Dependencias

- **Storage**: Requiere un StorageClass (ej: nfs-client) para persistencia de Redis
- **Kubernetes**: v1.20+
- **Helm**: v3.0+

## 📂 Estructura de GitOps Recomendada

```
tu-repo/
├── apps/
│   ├── app1/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   └── app2/
│       └── ...
├── infrastructure/
│   └── ...
└── argocd/
    ├── apps.yaml       # ArgoCD Application definitions
    └── projects.yaml   # ArgoCD Projects
```

## 🎯 Próximos Pasos con ArgoCD

1. **Organiza tu repositorio** según GitOps best practices
2. **Crea Projects** para separar aplicaciones
3. **Configura RBAC** granular por equipos
4. **Implementa multi-cluster** si tienes varios clusters
5. **Integra con CI** para actualizar imágenes automáticamente

## 📖 Más Información

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://opengitops.dev/)
- Ver [ARCHITECTURE](../docs/ARCHITECTURE.md) para arquitectura de ArgoCD
- Ver [TROUBLESHOOTING](../docs/TROUBLESHOOTING.md) para problemas comunes

## 🚧 Aplicaciones Futuras

Este directorio está diseñado para expandirse con más aplicaciones. Algunas opciones:

- **GitLab**: Sistema completo de CI/CD y repositorio Git
- **PostgreSQL**: Base de datos relacional
- **Jenkins**: Servidor de CI/CD
- **Harbor**: Registry de contenedores

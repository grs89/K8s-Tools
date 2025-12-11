#!/bin/bash
#
# NFS-StorageClass.sh - Instalación de NFS Subdir External Provisioner
# Este script instala el provisioner dinámico de NFS para Kubernetes
#

set -euo pipefail

# =============================================================================
# Configuración
# =============================================================================

# Determinar directorio del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Cargar funciones comunes
# shellcheck source=../scripts/common.sh
source "$PROJECT_ROOT/scripts/common.sh"

# Configurar manejo de errores
setup_error_handling

# Cargar configuración
load_config
load_versions

# Variables (con valores por defecto o desde config.env)
NFS_SERVER="${NFS_SERVER:-192.168.10.112}"
NFS_PATH="${NFS_PATH:-/data/nfs/monitoring}"
STORAGE_CLASS_NAME="${STORAGE_CLASS_NAME:-nfs-client}"
NAMESPACE="kube-system"
CHART_VERSION="${NFS_PROVISIONER_CHART_VERSION:-4.0.18}"

# =============================================================================
# Función Principal
# =============================================================================

main() {
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "  Instalando NFS Subdir External Provisioner"
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "  Servidor NFS: $NFS_SERVER"
    log INFO "  Ruta NFS: $NFS_PATH"
    log INFO "  StorageClass: $STORAGE_CLASS_NAME"
    log INFO "  Namespace: $NAMESPACE"
    log INFO "  Chart Version: $CHART_VERSION"
    log INFO "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Verificar prerrequisitos
    check_prerequisites
    echo ""
    
    # Validar configuración NFS
    validate_nfs_config
    echo ""
    
    # Configurar repositorio Helm
    log INFO "🔧 Agregando repositorio Helm para NFS provisioner..."
    helm repo add nfs-subdir-external-provisioner \
        "${HELM_REPO_NFS:-https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/}"
    helm repo update
    echo ""
    
    # Instalar con Helm
    install_nfs_provisioner
    echo ""
    
    # Verificar instalación
    verify_installation
    
    log INFO "✅ Instalación completada exitosamente"
    log INFO "📄 Log completo: $LOG_FILE"
}

# =============================================================================
# Funciones Auxiliares
# =============================================================================

validate_nfs_config() {
    log INFO "🔍 Validando configuración NFS..."
    
    # Verificar que las variables estén definidas
    if [ -z "$NFS_SERVER" ] || [ -z "$NFS_PATH" ]; then
        log ERROR "❌ Variables NFS_SERVER o NFS_PATH no están definidas"
        log INFO "💡 Crea un archivo config.env basado en config.env.example"
        exit 1
    fi
    
    # Intentar verificar conectividad al servidor NFS (solo warning si falla)
    log INFO "Verificando conectividad al servidor NFS: $NFS_SERVER..."
    if ping -c 1 -W 2 "$NFS_SERVER" >/dev/null 2>&1; then
        log INFO "✅ Servidor NFS alcanzable"
    else
        log WARN "⚠️  No se pudo hacer ping al servidor NFS $NFS_SERVER"
        log WARN "    Asegúrate de que el servidor esté accesible desde los nodos del cluster"
        log WARN "    La instalación continuará, pero puede fallar si el servidor no es accesible"
        echo ""
        
        if ! confirm "¿Deseas continuar de todas formas?"; then
            log INFO "Instalación cancelada por el usuario"
            exit 0
        fi
    fi
    
    log INFO "✅ Configuración NFS validada"
}

install_nfs_provisioner() {
    log INFO "📦 Instalando NFS Subdir External Provisioner..."
    
    helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
        --namespace "$NAMESPACE" \
        --create-namespace \
        --version "$CHART_VERSION" \
        --set nfs.server="$NFS_SERVER" \
        --set nfs.path="$NFS_PATH" \
        --set storageClass.name="$STORAGE_CLASS_NAME" \
        --set storageClass.defaultClass=true
    
    log INFO "✅ Helm chart instalado"
}

verify_installation() {
    log INFO "🔍 Verificando instalación..."
    echo ""
    
    # Esperar a que el deployment esté listo
    log INFO "⏳ Esperando que el provisioner esté listo..."
    sleep 5
    
    # Buscar el deployment (el nombre puede variar)
    local deployment
    deployment=$(kubectl get deployment -n "$NAMESPACE" -l app=nfs-subdir-external-provisioner -o name 2>/dev/null | head -1)
    
    if [ -n "$deployment" ]; then
        kubectl rollout status "$deployment" -n "$NAMESPACE" --timeout=120s
    else
        log WARN "⚠️  No se pudo encontrar el deployment del provisioner"
    fi
    
    echo ""
    
    # Verificar StorageClass
    if kubectl get storageclass "$STORAGE_CLASS_NAME" >/dev/null 2>&1; then
        log INFO "✅ StorageClass '$STORAGE_CLASS_NAME' creada correctamente"
        echo ""
        log INFO "Detalles de la StorageClass:"
        kubectl get storageclass "$STORAGE_CLASS_NAME"
    else
        log ERROR "❌ StorageClass '$STORAGE_CLASS_NAME' no encontrada"
        exit 1
    fi
    
    echo ""
    print_separator
    log INFO "💡 Información útil:"
    log INFO ""
    log INFO "  Para usar este StorageClass en un PVC:"
    log INFO ""
    echo "  apiVersion: v1"
    echo "  kind: PersistentVolumeClaim"
    echo "  metadata:"
    echo "    name: mi-pvc"
    echo "  spec:"
    echo "    storageClassName: $STORAGE_CLASS_NAME"
    echo "    accessModes:"
    echo "      - ReadWriteOnce"
    echo "    resources:"
    echo "      requests:"
    echo "        storage: 1Gi"
    log INFO ""
    print_separator
}

# Ejecutar función principal
main "$@"

#!/bin/bash
#
# 01-argo_cd.sh - Instalación de ArgoCD
# Este script instala ArgoCD para GitOps continuous delivery
#

set -euo pipefail

# =============================================================================
# Configuración
# =============================================================================

# Determinar directorio del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Cargar funciones comunes
# shellcheck source=../../scripts/common.sh
source "$PROJECT_ROOT/scripts/common.sh"

# Configurar manejo de errores
setup_error_handling

# Cargar configuración
load_config
load_versions

# Variables (con valores por defecto o desde config.env)
NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
RELEASE_NAME="argocd"
HTTP_PORT="${ARGOCD_HTTP_PORT:-32080}"
HTTPS_PORT=$((HTTP_PORT + 1))
STORAGE_CLASS="${ARGOCD_STORAGE_CLASS:-nfs-client}"
REDIS_SIZE="${ARGOCD_REDIS_SIZE:-1Gi}"
CHART_VERSION="${ARGOCD_CHART_VERSION:-5.51.6}"

# =============================================================================
# Función Principal
# =============================================================================

main() {
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "  Instalando ArgoCD"
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "  Namespace: $NAMESPACE"
    log INFO "  HTTP Port: $HTTP_PORT"
    log INFO "  HTTPS Port: $HTTPS_PORT"
    log INFO "  StorageClass: $STORAGE_CLASS"
    log INFO "  Chart Version: $CHART_VERSION"
    log INFO "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Verificar prerrequisitos
    check_prerequisites
    echo ""
    
    # Crear namespace
    ensure_namespace "$NAMESPACE"
    echo ""
    
    # Configurar repositorio Helm
    log INFO "🔧 Agregando repositorio Helm de ArgoCD..."
    helm repo add argo "${HELM_REPO_ARGO:-https://argoproj.github.io/argo-helm}"
    helm repo update
    echo ""
    
    # Crear archivo de valores
    create_values_file
    echo ""
    
    # Instalar ArgoCD
    install_argocd
    echo ""
    
    # Esperar a que esté listo
    wait_for_argocd
    echo ""
    
    # Mostrar información de acceso
    show_access_info
    
    log INFO "✅ Instalación completada exitosamente"
    log INFO "📄 Log completo: $LOG_FILE"
}

# =============================================================================
# Funciones Auxiliares
# =============================================================================

create_values_file() {
    log INFO "📝 Creando archivo de configuración de Helm..."
    
    local values_file="$SCRIPT_DIR/argocd-values.yaml"
    
    cat > "$values_file" <<EOF
# Configuración generada automáticamente para ArgoCD
# Generado: $(date)

server:
  service:
    type: NodePort
    nodePortHttp: $HTTP_PORT
    nodePortHttps: $HTTPS_PORT
    ports:
      http: 80
      https: 443

redis:
  metrics:
    enabled: true
  persistence:
    enabled: true
    size: $REDIS_SIZE
    storageClass: $STORAGE_CLASS
EOF
    
    log DEBUG "Archivo de valores creado en: $values_file"
}

install_argocd() {
    log INFO "📦 Instalando ArgoCD con Helm..."
    
    local values_file="$SCRIPT_DIR/argocd-values.yaml"
    
    helm install "$RELEASE_NAME" argo/argo-cd \
        -n "$NAMESPACE" \
        --version "$CHART_VERSION" \
        -f "$values_file"
    
    log INFO "✅ Helm chart instalado"
}

wait_for_argocd() {
    log INFO "⏳ Esperando que ArgoCD esté listo..."
    
    # Esperar un momento para que se creen los recursos
    sleep 10
    
    # Esperar al servidor de ArgoCD
    if kubectl get deployment argocd-server -n "$NAMESPACE" >/dev/null 2>&1; then
        wait_for_deployment argocd-server "$NAMESPACE" 300
    else
        log WARN "⚠️  Deployment argocd-server no encontrado inmediatamente, esperando..."
        sleep 10
        wait_for_deployment argocd-server "$NAMESPACE" 300
    fi
}

show_access_info() {
    local node_ip
    node_ip=$(get_node_ip)
    
    # Esperar un poco más para que se cree el secret
    log INFO "⏳ Esperando que se genere la contraseña inicial..."
    sleep 5
    
    # Obtener contraseña inicial
    local initial_password
    if kubectl -n "$NAMESPACE" get secret argocd-initial-admin-secret >/dev/null 2>&1; then
        initial_password=$(kubectl -n "$NAMESPACE" get secret argocd-initial-admin-secret \
            -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
    else
        initial_password="<secret no disponible aún>"
        log WARN "⚠️  El secret de contraseña inicial aún no está disponible"
        log INFO "    Espera unos momentos y obtén la contraseña con:"
        log INFO "    kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
    fi
    
    print_separator
    log INFO "🌐 Información de Acceso a ArgoCD"
    print_separator
    log INFO ""
    log INFO "  URL: https://${node_ip}:${HTTPS_PORT}"
    log INFO "  Usuario: admin"
    if [ "$initial_password" != "<secret no disponible aún>" ]; then
        log INFO "  Contraseña: $initial_password"
    else
        log INFO "  Contraseña: (ver comando arriba)"
    fi
    log INFO ""
    log INFO "  💡 También puedes acceder vía HTTP en: http://${node_ip}:${HTTP_PORT}"
    log INFO ""
    print_separator
    
    echo ""
    log INFO "📚 Próximos pasos:"
    log INFO "  1. Accede a la UI con las credenciales anteriores"
    log INFO "  2. Cambia la contraseña del admin (recomendado)"
    log INFO "  3. Configura tus repositorios Git"
    log INFO "  4. Crea tu primera Application en ArgoCD"
    echo ""
}

# Ejecutar función principal
main "$@"

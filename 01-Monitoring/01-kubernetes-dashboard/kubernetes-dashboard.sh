#!/bin/bash
#
# kubernetes-dashboard.sh - Instalación de Kubernetes Dashboard
# Este script instala el Kubernetes Dashboard en el cluster y crea un usuario admin
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

# Variables (con valores por defecto)
NAMESPACE="kubernetes-dashboard"
NODEPORT="${DASHBOARD_NODEPORT:-32000}"
VERSION="${DASHBOARD_VERSION:-v2.7.0}"
MANIFEST_URL="${DASHBOARD_MANIFEST_URL:-https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION}/aio/deploy/recommended.yaml}"

# =============================================================================
# Función Principal
# =============================================================================

main() {
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "  Instalando Kubernetes Dashboard"
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "  Versión: $VERSION"
    log INFO "  Namespace: $NAMESPACE"
    log INFO "  NodePort: $NODEPORT"
    log INFO "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Verificar prerrequisitos
    check_prerequisites
    echo ""
    
    # Instalar Dashboard
    log INFO "🚀 Instalando Kubernetes Dashboard..."
    kubectl apply -f "$MANIFEST_URL"
    echo ""
    
    # Esperar a que el deployment esté disponible
    log INFO "⏳ Esperando que el Dashboard esté disponible..."
    sleep 5  # Dar tiempo para que se cree el deployment
    wait_for_deployment kubernetes-dashboard "$NAMESPACE" 300
    echo ""
    
    # Cambiar servicio a NodePort
    log INFO "✅ Configurando servicio como NodePort (puerto $NODEPORT)..."
    kubectl -n "$NAMESPACE" patch service kubernetes-dashboard \
        -p "{\"spec\": {\"type\": \"NodePort\", \"ports\": [{\"port\": 443, \"targetPort\": 8443, \"nodePort\": $NODEPORT}]}}"
    echo ""
    
    # Crear usuario admin
    create_admin_user
    echo ""
    
    # Obtener información de acceso
    show_access_info
    
    log INFO "✅ Instalación completada exitosamente"
    log INFO "📄 Log completo: $LOG_FILE"
}

# =============================================================================
# Funciones Auxiliares
# =============================================================================

create_admin_user() {
    log INFO "📝 Creando usuario admin..."
    
    local admin_yaml="$PROJECT_ROOT/01-Monitoring/01-kubernetes-dashboard/dashboard-admin.yaml"
    
    cat > "$admin_yaml" <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: $NAMESPACE
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
  namespace: $NAMESPACE
EOF
    
    log DEBUG "Aplicando configuración de usuario admin..."
    kubectl apply -f "$admin_yaml"
    
    log INFO "✅ Usuario admin creado"
}

show_access_info() {
    local node_ip
    node_ip=$(get_node_ip)
    
    print_separator
    log INFO "🌐 Información de Acceso al Dashboard"
    print_separator
    log INFO ""
    log INFO "  URL: https://${node_ip}:${NODEPORT}"
    log INFO ""
    log INFO "  Para obtener el token de acceso, ejecuta:"
    log INFO "  kubectl -n $NAMESPACE create token admin-user"
    log INFO ""
    print_separator
}

# Ejecutar función principal
main "$@"

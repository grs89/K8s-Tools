#!/bin/bash
#
# metrics-server.sh - Instalación de Metrics Server
# Este script instala Metrics Server para proporcionar métricas de recursos del cluster
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
NAMESPACE="kube-system"
VERSION="${METRICS_SERVER_VERSION:-v0.7.0}"
MANIFEST_URL="${METRICS_SERVER_MANIFEST_URL:-https://github.com/kubernetes-sigs/metrics-server/releases/download/${VERSION}/components.yaml}"

# =============================================================================
# Función Principal
# =============================================================================

main() {
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "  Instalando Metrics Server"
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "  Versión: $VERSION"
    log INFO "  Namespace: $NAMESPACE"
    log INFO "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Verificar prerrequisitos
    check_prerequisites
    echo ""
    
    # Instalar Metrics Server
    log INFO "🚀 Instalando Metrics Server..."
    kubectl apply -f "$MANIFEST_URL"
    echo ""
    
    # Aplicar patch para permitir conexiones inseguras al kubelet
    log INFO "✅ Aplicando configuración para permitir conexiones inseguras al kubelet..."
    log WARN "⚠️  Esta configuración es para entornos de desarrollo/prueba"
    
    # Esperar un momento para que se cree el deployment
    sleep 5
    
    kubectl patch deployment metrics-server -n "$NAMESPACE" \
        --type='json' \
        -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
    echo ""
    
    # Esperar a que los pods estén listos
    log INFO "⏳ Esperando que los pods del Metrics Server estén listos..."
    wait_for_deployment metrics-server "$NAMESPACE" 300
    echo ""
    
    # Verificar que las métricas funcionen
    verify_metrics
    
    log INFO "✅ Instalación completada exitosamente"
    log INFO "📄 Log completo: $LOG_FILE"
}

# =============================================================================
# Funciones Auxiliares
# =============================================================================

verify_metrics() {
    log INFO "📊 Verificando que las métricas estén disponibles..."
    
    # Esperar un momento para que las métricas se recopilen
    log INFO "Esperando 10 segundos para que se recopilen métricas iniciales..."
    sleep 10
    
    # Intentar obtener métricas de nodos
    if kubectl top nodes 2>/dev/null; then
        log INFO "✅ Métricas de nodos disponibles"
    else
        log WARN "⚠️  Las métricas de nodos aún no están disponibles"
        log INFO "Esto puede tardar algunos minutos. Intenta ejecutar 'kubectl top nodes' más tarde."
    fi
    
    echo ""
    
    # Intentar obtener métricas de pods
    log INFO "Métricas de pods en todos los namespaces:"
    if kubectl top pods -A 2>/dev/null | head -10; then
        log INFO "✅ Métricas de pods disponibles"
    else
        log WARN "⚠️  Las métricas de pods aún no están disponibles"
    fi
    
    echo ""
    print_separator
    log INFO "💡 Comandos útiles:"
    log INFO "  kubectl top nodes           # Métricas de nodos"
    log INFO "  kubectl top pods -A         # Métricas de todos los pods"
    log INFO "  kubectl top pods -n <ns>    # Métricas de pods en namespace específico"
    print_separator
}

# Ejecutar función principal
main "$@"

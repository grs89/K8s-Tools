#!/bin/bash
#
# validate.sh - Script de validación post-instalación para K8s-Tools
# Verifica que los componentes instalados estén funcionando correctamente
#

set -euo pipefail

# Cargar funciones comunes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

# =============================================================================
# Funciones de Validación
# =============================================================================

validate_dashboard() {
    log INFO "🔍 Validando Kubernetes Dashboard..."
    
    local namespace="kubernetes-dashboard"
    
    # Verificar namespace
    if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
        log WARN "⚠️  Namespace '$namespace' no existe - Dashboard no instalado"
        return 1
    fi
    
    # Verificar deployment
    if ! kubectl get deployment kubernetes-dashboard -n "$namespace" >/dev/null 2>&1; then
        log WARN "⚠️  Deployment de Dashboard no encontrado"
        return 1
    fi
    
    # Verificar pods
    local ready_pods
    ready_pods=$(kubectl get pods -n "$namespace" -l k8s-app=kubernetes-dashboard --field-selector=status.phase=Running -o name | wc -l)
    
    if [ "$ready_pods" -gt 0 ]; then
        log INFO "✅ Kubernetes Dashboard: OK ($ready_pods pods running)"
        return 0
    else
        log ERROR "❌ Kubernetes Dashboard: No hay pods running"
        return 1
    fi
}

validate_metrics_server() {
    log INFO "🔍 Validando Metrics Server..."
    
    local namespace="kube-system"
    
    # Verificar deployment
    if ! kubectl get deployment metrics-server -n "$namespace" >/dev/null 2>&1; then
        log WARN "⚠️  Metrics Server no encontrado"
        return 1
    fi
    
    # Probar obtener métricas
    if kubectl top nodes >/dev/null 2>&1; then
        log INFO "✅ Metrics Server: OK (métricas disponibles)"
        return 0
    else
        log WARN "⚠️  Metrics Server desplegado pero métricas no disponibles aún"
        return 1
    fi
}

validate_nfs_provisioner() {
    log INFO "🔍 Validando NFS Provisioner..."
    
    local namespace="kube-system"
    
    # Verificar deployment
    if ! kubectl get deployment -n "$namespace" -l app=nfs-subdir-external-provisioner >/dev/null 2>&1; then
        log WARN "⚠️  NFS Provisioner no encontrado"
        return 1
    fi
    
    # Verificar StorageClass
    if kubectl get storageclass nfs-client >/dev/null 2>&1; then
        log INFO "✅ NFS Provisioner: OK (StorageClass 'nfs-client' disponible)"
        return 0
    else
        log WARN "⚠️  NFS Provisioner desplegado pero StorageClass no encontrada"
        return 1
    fi
}

validate_argocd() {
    log INFO "🔍 Validando ArgoCD..."
    
    local namespace="argocd"
    
    # Verificar namespace
    if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
        log WARN "⚠️  Namespace '$namespace' no existe - ArgoCD no instalado"
        return 1
    fi
    
    # Verificar server deployment
    if ! kubectl get deployment argocd-server -n "$namespace" >/dev/null 2>&1; then
        log WARN "⚠️  ArgoCD server deployment no encontrado"
        return 1
    fi
    
    # Verificar pods
    local ready_pods
    ready_pods=$(kubectl get pods -n "$namespace" --field-selector=status.phase=Running -o name | wc -l)
    
    if [ "$ready_pods" -gt 0 ]; then
        log INFO "✅ ArgoCD: OK ($ready_pods pods running)"
        return 0
    else
        log ERROR "❌ ArgoCD: No hay pods running"
        return 1
    fi
}

validate_prometheus_stack() {
    log INFO "🔍 Validando Prometheus Stack..."
    
    local namespace="monitoring"
    
    # Verificar namespace
    if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
        log WARN "⚠️  Namespace '$namespace' no existe - Prometheus Stack no instalado"
        return 1
    fi
    
    # Verificar Prometheus
    if kubectl get statefulset -n "$namespace" -l app.kubernetes.io/name=prometheus >/dev/null 2>&1; then
        log INFO "  ✓ Prometheus encontrado"
    else
        log WARN "  ⚠️  Prometheus no encontrado"
        return 1
    fi
    
    # Verificar Grafana
    if kubectl get deployment -n "$namespace" -l app.kubernetes.io/name=grafana >/dev/null 2>&1; then
        log INFO "  ✓ Grafana encontrado"
    else
        log WARN "  ⚠️  Grafana no encontrado"
    fi
    
    log INFO "✅ Prometheus Stack: OK"
    return 0
}

# =============================================================================
# Función Principal
# =============================================================================

main() {
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "  K8s-Tools - Validación de Componentes"
    log INFO "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Verificar prerrequisitos
    check_prerequisites
    echo ""
    
    # Contadores de resultados
    local total=0
    local passed=0
    local failed=0
    
    # Validar cada componente
    local components=(
        "validate_dashboard"
        "validate_metrics_server"
        "validate_nfs_provisioner"
        "validate_argocd"
        "validate_prometheus_stack"
    )
    
    for component in "${components[@]}"; do
        ((total++))
        if $component; then
            ((passed++))
        else
            ((failed++))
        fi
        echo ""
    done
    
    # Resumen
    print_separator
    log INFO "📊 Resumen de Validación:"
    log INFO "   Total de componentes verificados: $total"
    log INFO "   ✅ Pasaron: $passed"
    if [ $failed -gt 0 ]; then
        log WARN "   ❌ Fallaron: $failed"
    else
        log INFO "   ❌ Fallaron: $failed"
    fi
    print_separator
    
    if [ $failed -eq 0 ]; then
        log INFO "🎉 ¡Todos los componentes instalados están funcionando correctamente!"
        exit 0
    else
        log WARN "⚠️  Algunos componentes no están instalados o no están funcionando"
        log INFO "Esto es normal si no has instalado todos los componentes disponibles"
        exit 0
    fi
}

# Ejecutar
main "$@"

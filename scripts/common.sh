#!/bin/bash
#
# common.sh - Biblioteca de funciones compartidas para scripts de K8s-Tools
# Este archivo debe ser sourced por otros scripts de instalación
#

# =============================================================================
# Variables Globales
# =============================================================================

# Directorio base del proyecto (2 niveles arriba desde scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Archivo de log (se puede sobreescribir desde el script que llama)
LOG_FILE="${LOG_FILE:-/tmp/k8s-tools-$(date +%Y%m%d-%H%M%S).log}"

# Nivel de log por defecto
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# =============================================================================
# Funciones de Logging
# =============================================================================

# Función de logging con niveles
# Uso: log LEVEL "mensaje"
log() {
    local level=$1
    shift
    local msg="$*"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    
    # Colores para terminal
    local color_reset="\033[0m"
    local color_debug="\033[0;36m"    # Cyan
    local color_info="\033[0;32m"     # Green
    local color_warn="\033[0;33m"     # Yellow
    local color_error="\033[0;31m"    # Red
    
    local color=""
    case "$level" in
        DEBUG) color="$color_debug" ;;
        INFO)  color="$color_info" ;;
        WARN)  color="$color_warn" ;;
        ERROR) color="$color_error" ;;
    esac
    
    # Escribir a log file
    echo "[$timestamp] [$level] $msg" >> "$LOG_FILE"
    
    # Escribir a terminal con colores
    echo -e "${color}[$level]${color_reset} $msg"
}

# =============================================================================
# Validación de Prerrequisitos
# =============================================================================

# Verificar que una herramienta esté instalada
check_command() {
    local cmd=$1
    local msg=${2:-"$cmd no está instalado"}
    
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log ERROR "$msg"
        return 1
    fi
    log DEBUG "$cmd encontrado: $(command -v $cmd)"
    return 0
}

# Validar todos los prerrequisitos necesarios
check_prerequisites() {
    log INFO "🔍 Validando prerrequisitos..."
    
    local all_ok=true
    
    # Verificar kubectl
    if ! check_command kubectl "kubectl no está instalado. Instálalo desde https://kubernetes.io/docs/tasks/tools/"; then
        all_ok=false
    fi
    
    # Verificar helm
    if ! check_command helm "helm no está instalado. Instálalo desde https://helm.sh/docs/intro/install/"; then
        all_ok=false
    fi
    
    # Verificar conectividad al cluster
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log ERROR "No hay conexión al cluster de Kubernetes. Verifica tu kubeconfig."
        all_ok=false
    else
        log DEBUG "Conexión al cluster verificada"
    fi
    
    if [ "$all_ok" = false ]; then
        log ERROR "❌ Faltan prerrequisitos. Corrígelos antes de continuar."
        exit 1
    fi
    
    log INFO "✅ Prerrequisitos validados correctamente"
}

# =============================================================================
# Gestión de Helm
# =============================================================================

# Configurar repositorios de Helm
setup_helm_repos() {
    log INFO "🔧 Configurando repositorios de Helm..."
    
    # Cargar URLs de repositorios desde versions.conf si existe
    if [ -f "$PROJECT_ROOT/versions.conf" ]; then
        source "$PROJECT_ROOT/versions.conf"
    fi
    
    helm repo add prometheus-community "${HELM_REPO_PROMETHEUS:-https://prometheus-community.github.io/helm-charts}" 2>/dev/null || true
    helm repo add grafana "${HELM_REPO_GRAFANA:-https://grafana.github.io/helm-charts}" 2>/dev/null || true
    helm repo add argo "${HELM_REPO_ARGO:-https://argoproj.github.io/argo-helm}" 2>/dev/null || true
    helm repo add nfs-subdir-external-provisioner "${HELM_REPO_NFS:-https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/}" 2>/dev/null || true
    
    helm repo update
    
    log INFO "✅ Repositorios de Helm configurados"
}

# =============================================================================
# Funciones de Espera y Validación
# =============================================================================

# Esperar a que un deployment esté listo
# Uso: wait_for_deployment NOMBRE NAMESPACE [TIMEOUT]
wait_for_deployment() {
    local name=$1
    local namespace=$2
    local timeout=${3:-300}
    
    log INFO "⏳ Esperando que el deployment '$name' en namespace '$namespace' esté listo..."
    
    if kubectl rollout status deployment/"$name" -n "$namespace" --timeout="${timeout}s"; then
        log INFO "✅ Deployment '$name' está listo"
        return 0
    else
        log ERROR "❌ Timeout esperando el deployment '$name'"
        return 1
    fi
}

# Esperar a que los pods de un selector estén listos
# Uso: wait_for_pods SELECTOR NAMESPACE [TIMEOUT]
wait_for_pods() {
    local selector=$1
    local namespace=$2
    local timeout=${3:-300}
    
    log INFO "⏳ Esperando que los pods con selector '$selector' en namespace '$namespace' estén listos..."
    
    if kubectl wait --for=condition=ready pod -l "$selector" -n "$namespace" --timeout="${timeout}s" 2>/dev/null; then
        log INFO "✅ Pods están listos"
        return 0
    else
        log WARN "⚠️  Timeout o no se encontraron pods con selector '$selector'"
        return 1
    fi
}

# Verificar que un namespace existe, si no, crearlo
ensure_namespace() {
    local namespace=$1
    
    if kubectl get namespace "$namespace" >/dev/null 2>&1; then
        log DEBUG "Namespace '$namespace' ya existe"
    else
        log INFO "➡️ Creando namespace '$namespace'..."
        kubectl create namespace "$namespace"
        log INFO "✅ Namespace '$namespace' creado"
    fi
}

# =============================================================================
# Utilidades de Red
# =============================================================================

# Obtener IP interna del primer nodo
get_node_ip() {
    local ip
    ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
    
    if [ -z "$ip" ]; then
        # Fallback: intentar con awk
        ip=$(kubectl get nodes -o wide 2>/dev/null | awk 'NR==2{print $6}')
    fi
    
    if [ -z "$ip" ]; then
        log WARN "No se pudo obtener la IP del nodo automáticamente"
        echo "NODE_IP"
    else
        echo "$ip"
    fi
}

# =============================================================================
# Gestión de Configuración
# =============================================================================

# Cargar configuración desde config.env
load_config() {
    local config_file="${1:-$PROJECT_ROOT/config.env}"
    
    if [ -f "$config_file" ]; then
        log INFO "📝 Cargando configuración desde $config_file"
        # shellcheck source=/dev/null
        source "$config_file"
        log DEBUG "Configuración cargada"
    else
        log WARN "⚠️  Archivo de configuración no encontrado: $config_file"
        log WARN "    Usando config.env.example como referencia puede ser necesario"
        if [ -f "$PROJECT_ROOT/config.env.example" ]; then
            log INFO "💡 Crea tu config.env copiando: cp config.env.example config.env"
        fi
    fi
}

# Cargar versiones desde versions.conf
load_versions() {
    local versions_file="${1:-$PROJECT_ROOT/versions.conf}"
    
    if [ -f "$versions_file" ]; then
        log DEBUG "Cargando versiones desde $versions_file"
        # shellcheck source=/dev/null
        source "$versions_file"
    else
        log WARN "⚠️  Archivo de versiones no encontrado: $versions_file"
    fi
}

# =============================================================================
# Limpieza y Manejo de Errores
# =============================================================================

# Función de limpieza en caso de error
cleanup_on_error() {
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        log ERROR "❌ Error detectado (código: $exit_code)"
        log INFO "📄 Revisa el log completo en: $LOG_FILE"
        
        # Aquí se puede agregar lógica de limpieza específica
        # Por ejemplo, eliminar recursos parcialmente creados
    fi
}

# Configurar trap para limpieza automática
setup_error_handling() {
    trap cleanup_on_error EXIT
    set -euo pipefail  # Exit on error, undefined vars, pipe failures
}

# =============================================================================
# Utilidades Varias
# =============================================================================

# Imprimir un separador visual
print_separator() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo ""
}

# Confirmar acción del usuario
confirm() {
    local prompt="${1:-¿Continuar?}"
    local response
    
    read -r -p "$prompt (y/n): " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# =============================================================================
# Inicialización
# =============================================================================

log DEBUG "common.sh cargado desde $SCRIPT_DIR"
log DEBUG "Proyecto root: $PROJECT_ROOT"
log DEBUG "Log file: $LOG_FILE"

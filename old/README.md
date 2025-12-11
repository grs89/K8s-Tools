# Contenido Legacy - old/

Este directorio contiene scripts y configuraciones antiguas que han sido reemplazadas por la nueva estructura de K8s-Tools.

## ⚠️ Deprecado

**Este directorio está deprecado y será eliminado en futuras versiones.**

El contenido aquí es mantenido temporalmente para referencia histórica, pero **no debe ser usado** en nuevas instalaciones.

## 📋 Migración

### Scripts de Monitoring Prometheus/Grafana

El contenido de `old/monitoring-prometheus_grafana/` ha sido reemplazado por componentes individuales:

- ✅ **Dashboard de Kubernetes**: Usa `01-Monitoring/01-kubernetes-dashboard/`
- ✅ **Métricas**: Usa `01-Monitoring/01-metrics-server/`
- 🚧 **Prometheus/Grafana Stack completo**: En desarrollo para nueva estructura

**Para instalar Prometheus/Grafana actualmente**, usa los scripts en `old/monitoring-prometheus_grafana/` pero ten en cuenta que:
1. No están integrados con el nuevo `common.sh`
2. No usan `config.env`
3. Pueden tener configuraciones hardcodeadas

### PostgreSQL

El archivo `old/db-postgresql/postgresql-values.yaml` es un Helm values file de ejemplo.

**Para usar PostgreSQL**:
1. Copia el archivo a tu directorio de trabajo
2. Ajusta los valores según tus necesidades
3. Instala con Helm:
   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm install postgresql bitnami/postgresql -f postgresql-values.yaml
   ```

### ELK Stack y Zabbix

Estos componentes están deprecados en este proyecto. Recomendaciones:

- **ELK/Elastic**: Usa Elastic Cloud o instala usando los charts oficiales de Elastic
- **Zabbix**: Considera alternativas modernas como Prometheus/Grafana

## 🗑️ Plan de Eliminación

1. **v2.0**: Marcar directorio como deprecado (✅ actual)
2. **v2.1**: Mover a branch `legacy` 
3. **v3.0**: Eliminar completamente del main branch

## 📖 Referencia

Si necesitas algo de este directorio:
1. Revisa primero si existe una alternativa en la nueva estructura
2. Consulta la [documentación](../docs/) para componentes equivalentes
3. Abre un Issue si necesitas ayuda con la migración

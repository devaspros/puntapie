#!/bin/bash

# configure the crontab for ubuntu
# crontab -e
#
# will run every twenty three hours.
#
# 0 */23 * * * bash /home/ubuntu/PUNTAPIE/app/scripts/backup_logs.sh >> /home/ubuntu/PUNTAPIE/deployments/logs/100_cron.log 2>&1
#
# Backup logs a Cloudflare R2 con rclone

# ============================================
# CONFIGURACIÓN (EDITA ESTOS VALORES)
# ============================================

# Archivo de log de producción
LOG_FILE="/home/ubuntu/PUNTAPIE/app/log/production.log"

# Directorio temporal para backups
TEMP_DIR="/home/ubuntu/PUNTAPIE/backups"

# Nombre del remote de rclone (el que creaste)
RCLONE_REMOTE="cloudflare_r2"

# Nombre del bucket en Cloudflare R2
R2_BUCKET="PUNTAPIE-backups"

# Estructura de carpetas en R2
R2_PATH="logs"

# ============================================
# NO EDITAR A PARTIR DE AQUÍ (normalmente)
# ============================================

# Colores para output (opcional)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mensajes
info() { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }

# Crear directorio temporal si no existe
mkdir -p "$TEMP_DIR"

# Nombre del archivo de backup
BACKUP_NAME="PUNTAPIE_log_$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${TEMP_DIR}/${BACKUP_NAME}.tgz"

info "Iniciando backup de logs..."

# ============================================
# 1. VERIFICAR QUE EXISTE EL ARCHIVO DE LOG
# ============================================
if [ ! -f "$LOG_FILE" ]; then
    error "No se encuentra el archivo de log: $LOG_FILE"
    exit 1
fi

info "Archivo de log encontrado: $(du -h "$LOG_FILE" | cut -f1)"

# ============================================
# 2. CREAR BACKUP CON TAR
# ============================================
info "Creando backup comprimido con tar..."
if tar czf "$BACKUP_FILE" "$LOG_FILE"; then
    info "✓ Backup creado y comprimido: $BACKUP_FILE"
    info "Tamaño: $(du -h "$BACKUP_FILE" | cut -f1)"
else
    error "✗ Falló la creación del backup"
    exit 1
fi

# ============================================
# 3. SUBIR A CLOUDFLARE R2 CON RCLONE
# ============================================
info "Subiendo a Cloudflare R2..."
if rclone copy "$BACKUP_FILE" "${RCLONE_REMOTE}:${R2_BUCKET}/${R2_PATH}/" --s3-no-check-bucket; then
    info "✓ Backup subido exitosamente a Cloudflare R2"
    info "Ruta: ${RCLONE_REMOTE}:${R2_BUCKET}/${R2_PATH}/$(basename $BACKUP_FILE)"
else
    error "✗ Falló la subida a Cloudflare R2"
    error "Detalle del error:"
    rclone copy "$BACKUP_FILE" "${RCLONE_REMOTE}:${R2_BUCKET}/${R2_PATH}/" --s3-no-check-bucket -v 2>&1 | while read line; do error "  $line"; done
    # No salimos aquí, continuamos para limpiar
fi

# ============================================
# 4. VERIFICAR QUE SE SUBIÓ CORRECTAMENTE
# ============================================
if [ $? -eq 0 ]; then
    info "Verificando subida..."
    if rclone lsf "${RCLONE_REMOTE}:${R2_BUCKET}/${R2_PATH}/" --s3-no-check-bucket | grep -q "$(basename $BACKUP_FILE)"; then
        info "✓ Verificación exitosa: archivo encontrado en R2"
    else
        warn "⚠ Archivo no encontrado en R2 (pero rclone reportó éxito)"
    fi
fi

# ============================================
# 5. LIMPIAR ARCHIVOS TEMPORALES
# ============================================
info "Limpiando archivos temporales..."
rm -f "$BACKUP_FILE"

# Limpiar backups temporales antiguos (> 1 día)
find "$TEMP_DIR" -name "*.tgz" -mtime +1 -delete 2>/dev/null
info "Limpieza completada"

# ============================================
# 6. REPORTE FINAL
# ============================================
echo "========================================="
info "✅ BACKUP COMPLETADO EXITOSAMENTE"
info "Archivo de log: $(basename $LOG_FILE)"
info "Backup creado: $(basename $BACKUP_FILE)"
info "Destino: Cloudflare R2 (${RCLONE_REMOTE}:${R2_BUCKET}/${R2_PATH}/)"
info "Fecha: $(date)"
echo "========================================="

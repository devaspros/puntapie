#!/bin/bash

# configure the crontab for ubuntu
# crontab -e
#
# will run every four hours.
#
# 0 */4 * * * bash /home/ubuntu/PUNTAPIE/app/scripts/backup_db.sh >> /home/ubuntu/PUNTAPIE/deployments/logs/100_cron.log 2>&1
#
# Backup SQLite a Cloudflare R2 con rclone

# ============================================
# CONFIGURACIÓN (EDITA ESTOS VALORES)
# ============================================

# Tu base de datos SQLite
DB_FILE="/home/ubuntu/PUNTAPIE/db/PUNTAPIE.sqlite"

# Directorio temporal para backups
TEMP_DIR="/home/ubuntu/PUNTAPIE/backups"

# Nombre del remote de rclone (el que creaste)
RCLONE_REMOTE="cloudflare_r2"

# Nombre del bucket en Cloudflare R2
R2_BUCKET="PUNTAPIE-backups"

# Estructura de carpetas en R2
R2_PATH="databases"

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
BACKUP_NAME="PUNTAPIE_db_$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${TEMP_DIR}/${BACKUP_NAME}.db"

info "Iniciando backup de la base de datos..."

# ============================================
# 1. VERIFICAR QUE EXISTE LA BASE DE DATOS
# ============================================
if [ ! -f "$DB_FILE" ]; then
    error "No se encuentra la base de datos: $DB_FILE"
    exit 1
fi

info "Base de datos encontrada: $(du -h "$DB_FILE" | cut -f1)"

# ============================================
# 2. CREAR BACKUP CON SQLITE (MÁS SEGURO)
# ============================================
info "Creando backup con SQLite..."
if sqlite3 "$DB_FILE" ".backup '$BACKUP_FILE'"; then
    info "✓ Backup SQLite creado: $BACKUP_FILE"
else
    error "✗ Falló el comando de backup SQLite"
    exit 1
fi

# ============================================
# 3. COMPRIMIR EL BACKUP
# ============================================
COMPRESSED_FILE="${BACKUP_FILE}.gz"
info "Comprimiendo backup..."
if gzip -9 "$BACKUP_FILE"; then
    info "✓ Backup comprimido: $COMPRESSED_FILE"
    info "Tamaño: $(du -h "$COMPRESSED_FILE" | cut -f1)"
else
    error "✗ Falló la compresión"
    exit 1
fi

# ============================================
# 4. SUBIR A CLOUDFLARE R2 CON RCLONE
# ============================================
info "Subiendo a Cloudflare R2..."
if rclone copy "$COMPRESSED_FILE" "${RCLONE_REMOTE}:${R2_BUCKET}/${R2_PATH}/" --s3-no-check-bucket; then
    info "✓ Backup subido exitosamente a Cloudflare R2"
    info "Ruta: ${RCLONE_REMOTE}:${R2_BUCKET}/${R2_PATH}/$(basename $COMPRESSED_FILE)"
else
    error "✗ Falló la subida a Cloudflare R2"
    error "Detalle del error:"
    rclone copy "$COMPRESSED_FILE" "${RCLONE_REMOTE}:${R2_BUCKET}/${R2_PATH}/" --s3-no-check-bucket -v 2>&1 | while read line; do error "  $line"; done
    # No salimos aquí, continuamos para limpiar
fi

# ============================================
# 5. VERIFICAR QUE SE SUBIÓ CORRECTAMENTE
# ============================================
if [ $? -eq 0 ]; then
    info "Verificando subida..."
    if rclone lsf "${RCLONE_REMOTE}:${R2_BUCKET}/${R2_PATH}/" --s3-no-check-bucket | grep -q "$(basename $COMPRESSED_FILE)"; then
        info "✓ Verificación exitosa: archivo encontrado en R2"
    else
        warn "⚠ Archivo no encontrado en R2 (pero rclone reportó éxito)"
    fi
fi

# ============================================
# 6. LIMPIAR ARCHIVOS TEMPORALES
# ============================================
info "Limpiando archivos temporales..."
rm -f "$COMPRESSED_FILE"

# Limpiar backups temporales antiguos (> 1 día)
find "$TEMP_DIR" -name "*.db.gz" -mtime +1 -delete 2>/dev/null
info "Limpieza completada"

# ============================================
# 7. REPORTE FINAL
# ============================================
echo "========================================="
info "✅ BACKUP COMPLETADO EXITOSAMENTE"
info "Base de datos: $(basename $DB_FILE)"
info "Backup creado: $(basename $COMPRESSED_FILE)"
info "Destino: Cloudflare R2 (${RCLONE_REMOTE}:${R2_BUCKET}/${R2_PATH}/)"
info "Fecha: $(date)"
echo "========================================="

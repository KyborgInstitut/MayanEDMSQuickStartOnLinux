#!/bin/bash
# =============================================================================
# Mayan EDMS Backup Script / Backup-Script
# - Kyborg setup (/srv/mayan, /var/lib/mayan_postgres)
# - Creates tar.gz with / Erstellt tar.gz mit:
#     * PostgreSQL-Dump (mayan_db.sql)
#     * /srv/mayan/app_data, staging, watch, redis_data, elasticsearch_data
#     * /var/lib/mayan_postgres
#     * docker-compose.yml
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load language messages
if [[ -f "${SCRIPT_DIR}/lang_messages.sh" ]]; then
    source "${SCRIPT_DIR}/lang_messages.sh"
else
    echo "ERROR: lang_messages.sh not found!"
    exit 1
fi

# Use language from environment or default to English
LANG_CODE="${MAYAN_LANG:-en}"

STACK_DIR="/srv/mayan"
BACKUP_ROOT="/srv/mayan_backups"
PG_SERVICE="mayan_postgres"
PG_DB="mayan"
PG_USER="mayan"

TIMESTAMP="$(date +%F_%H-%M-%S)"
BACKUP_NAME="mayan-backup-${TIMESTAMP}.tar.gz"

echo "=== $(msg BACKUP_TITLE) ==="
echo "$(msg BACKUP_STACK_DIR): ${STACK_DIR}"
echo "$(msg BACKUP_DIR): ${BACKUP_ROOT}"
echo

# 1. Checks / Prüfungen
if [[ ! -d "${STACK_DIR}" ]]; then
  echo "$(msg ERROR): $(msg ERROR_STACK_NOT_FOUND) ${STACK_DIR}"
  exit 1
fi

cd "${STACK_DIR}"

if ! command -v docker >/dev/null 2>&1; then
  echo "$(msg ERROR): $(msg ERROR_DOCKER_NOT_FOUND)"
  exit 1
fi

# 2. Temp directory / Temp-Verzeichnis
WORK_DIR="$(mktemp -d)"
echo "$(msg BACKUP_WORK_DIR): ${WORK_DIR}"
mkdir -p "${BACKUP_ROOT}"
echo

# 3. PostgreSQL dump from container / PostgreSQL-Dump aus dem Container
echo "$(msg BACKUP_CREATING_DUMP) '${PG_SERVICE}'..."
docker compose exec -T "${PG_SERVICE}" \
  pg_dump -U "${PG_USER}" "${PG_DB}" > "${WORK_DIR}/mayan_db.sql"
echo "$(msg BACKUP_DB_DUMP): ${WORK_DIR}/mayan_db.sql"
echo

# 4. Backup docker-compose.yml / docker-compose.yml sichern
if [[ -f "${STACK_DIR}/docker-compose.yml" ]]; then
  cp "${STACK_DIR}/docker-compose.yml" "${WORK_DIR}/docker-compose.yml"
  echo "$(msg BACKUP_COMPOSE_ADDED)"
else
  echo "$(msg WARNING): $(msg BACKUP_COMPOSE_WARNING)"
  touch "${WORK_DIR}/docker-compose.yml"
fi
echo

# 5. Create archive / Archiv erstellen
echo "$(msg BACKUP_CREATING_ARCHIVE) ${BACKUP_ROOT}/${BACKUP_NAME} ..."
tar czf "${BACKUP_ROOT}/${BACKUP_NAME}" \
  -C "${WORK_DIR}" mayan_db.sql docker-compose.yml \
  -C /srv/mayan app_data staging watch redis_data elasticsearch_data \
  -C /var/lib mayan_postgres

echo "$(msg BACKUP_ARCHIVE_READY): ${BACKUP_ROOT}/${BACKUP_NAME}"
echo

# 6. Cleanup / Aufräumen
rm -rf "${WORK_DIR}"

# 7. Rotation (keep last 7 backups / nur die letzten 7 Backups behalten)
KEEP=7
echo "$(msg BACKUP_CLEANUP) ($(msg BACKUP_KEEP) ${KEEP})..."
BACKUPS=( $(ls -1t "${BACKUP_ROOT}"/mayan-backup-*.tar.gz 2>/dev/null || true) )

if (( ${#BACKUPS[@]} > KEEP )); then
  TO_DELETE=( "${BACKUPS[@]:KEEP}" )
  for f in "${TO_DELETE[@]}"; do
    echo "$(msg BACKUP_DELETE_OLD): $f"
    rm -f "$f"
  done
else
  echo "$(msg BACKUP_NO_OLD)"
fi

echo
echo "=== $(msg BACKUP_COMPLETE) ==="
#!/bin/bash
# =============================================================================
# Mayan EDMS Restore Script / Restore-Script
# - Matches backup script /srv/mayan_backups/mayan-backup-*.tar.gz
# - Restores / Stellt wieder her:
#     * PostgreSQL dump (mayan_db.sql)
#     * /srv/mayan/app_data, staging, watch, redis_data, elasticsearch_data
#     * optional /var/lib/mayan_postgres
#     * docker-compose.yml (if missing / falls fehlt)
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

echo "=== $(msg RESTORE_TITLE) ==="
echo "$(msg BACKUP_STACK_DIR): ${STACK_DIR}"
echo "$(msg BACKUP_DIR): ${BACKUP_ROOT}"
echo

# 1. Select backup file / Backup-Datei auswählen
if [[ ! -d "${BACKUP_ROOT}" ]]; then
  echo "$(msg ERROR): $(msg ERROR_BACKUP_DIR_NOT_FOUND) ${BACKUP_ROOT}"
  exit 1
fi

LATEST_BACKUP="$(ls -1t "${BACKUP_ROOT}"/mayan-backup-*.tar.gz 2>/dev/null | head -n 1 || true)"

if [[ -z "${LATEST_BACKUP}" ]]; then
  echo "$(msg ERROR): $(msg ERROR_NO_BACKUPS) ${BACKUP_ROOT}"
  exit 1
fi

echo "$(msg RESTORE_LATEST): ${LATEST_BACKUP}"
read -r -p "$(msg RESTORE_PATH_PROMPT) " BACKUP_FILE
BACKUP_FILE=${BACKUP_FILE:-${LATEST_BACKUP}}

if [[ ! -f "${BACKUP_FILE}" ]]; then
  echo "$(msg ERROR): $(msg ERROR_BACKUP_NOT_FOUND) ${BACKUP_FILE}"
  exit 1
fi

echo
echo "$(msg RESTORE_USING): ${BACKUP_FILE}"
echo

# 2. Safety confirmation / Sicherheitsabfrage
echo "$(msg WARNING): $(msg RESTORE_WARNING) '${PG_DB}'"
read -r -p "$(msg RESTORE_CONFIRM) " CONFIRM
[[ "$LANG_CODE" == "en" ]] && CONFIRM=${CONFIRM:-NO} || CONFIRM=${CONFIRM:-NEIN}

if [[ "$LANG_CODE" == "en" ]]; then
  if [[ "${CONFIRM}" != "yes" ]] && [[ "${CONFIRM}" != "YES" ]]; then
    echo "$(msg ABORTED)"
    exit 0
  fi
else
  if [[ "${CONFIRM}" != "ja" ]] && [[ "${CONFIRM}" != "JA" ]]; then
    echo "$(msg ABORTED)"
    exit 0
  fi
fi

# 3. Stop services / Dienste stoppen
echo "$(msg RESTORE_STOPPING)"
cd "${STACK_DIR}" || { echo "$(msg ERROR): ${STACK_DIR}"; exit 1; }
docker compose down || true
echo

# 4. Temp directory & extract backup / Temp-Verzeichnis & Backup entpacken
WORK_DIR="$(mktemp -d)"
echo "$(msg BACKUP_WORK_DIR): ${WORK_DIR}"
echo "$(msg RESTORE_EXTRACTING)"
tar xzf "${BACKUP_FILE}" -C "${WORK_DIR}"
echo "$(msg RESTORE_EXTRACTED)"
echo

# 5. Restore docker-compose.yml (if needed) / docker-compose.yml wiederherstellen (wenn nötig)
if [[ ! -f "${STACK_DIR}/docker-compose.yml" ]]; then
  if [[ -f "${WORK_DIR}/docker-compose.yml" ]]; then
    echo "$(msg RESTORE_COMPOSE)"
    cp "${WORK_DIR}/docker-compose.yml" "${STACK_DIR}/docker-compose.yml"
  else
    echo "$(msg WARNING): $(msg RESTORE_NO_COMPOSE)"
  fi
else
  echo "$(msg RESTORE_KEEP_COMPOSE)"
fi
echo

# 6. Restore files/directories / Dateien/Verzeichnisse wiederherstellen
echo "$(msg RESTORE_DIRECTORIES)"

mkdir -p /srv/mayan/{app_data,staging,watch,redis_data,elasticsearch_data}
mkdir -p /var/lib/mayan_postgres

for DIR in app_data staging watch redis_data elasticsearch_data; do
  if [[ -d "${WORK_DIR}/${DIR}" ]]; then
    [[ "$LANG_CODE" == "en" ]] && echo "  -> ${DIR} to /srv/mayan/${DIR}" || echo "  -> ${DIR} nach /srv/mayan/${DIR}"
    rm -rf "/srv/mayan/${DIR}"
    mkdir -p "/srv/mayan/${DIR}"
    cp -a "${WORK_DIR}/${DIR}/." "/srv/mayan/${DIR}/"
  else
    [[ "$LANG_CODE" == "en" ]] && echo "  (Note: ${DIR} not found in backup – skipped)" || echo "  (Hinweis: ${DIR} nicht im Backup gefunden – übersprungen)"
  fi
done

if [[ -d "${WORK_DIR}/mayan_postgres" ]]; then
  [[ "$LANG_CODE" == "en" ]] && echo "  -> PostgreSQL data directory to /var/lib/mayan_postgres (optional)" || echo "  -> PostgreSQL-Datenverzeichnis nach /var/lib/mayan_postgres (optional)"
  rm -rf /var/lib/mayan_postgres
  mkdir -p /var/lib/mayan_postgres
  cp -a "${WORK_DIR}/mayan_postgres/." /var/lib/mayan_postgres/
else
  [[ "$LANG_CODE" == "en" ]] && echo "  (Note: mayan_postgres not found in backup – physical PG directory remains unchanged)" || echo "  (Hinweis: mayan_postgres nicht im Backup gefunden – physisches PG-Verzeichnis bleibt unverändert)"
fi

echo "$(msg RESTORE_DIR_COMPLETE)"
echo

# 7. Fix permissions / Berechtigungen korrigieren
echo "$(msg RESTORE_PERMISSIONS)"

chown 999:999   /var/lib/mayan_postgres
chown 100:100   /srv/mayan/redis_data
chown 1000:1000 /srv/mayan/elasticsearch_data
chown 1001:1001 /srv/mayan/app_data /srv/mayan/staging /srv/mayan/watch

echo "$(msg RESTORE_PERMISSIONS_SET)"
echo

# 8. Restore PostgreSQL database / PostgreSQL-Datenbank wiederherstellen
if [[ ! -f "${WORK_DIR}/mayan_db.sql" ]]; then
  echo "$(msg ERROR): $(msg ERROR_NO_DB_DUMP)"
  rm -rf "${WORK_DIR}"
  exit 1
fi

echo "$(msg RESTORE_START_PG)"
docker compose up -d "${PG_SERVICE}"

echo -n "$(msg RESTORE_WAIT_PG)"
for i in {1..60}; do
    if docker compose logs "${PG_SERVICE}" 2>/dev/null | grep -q "database system is ready to accept connections"; then
        echo ""
        echo "$(msg RESTORE_PG_READY)"
        break
    fi
    echo -n "."
    sleep 1
done
echo

echo "$(msg RESTORE_DB) '${PG_DB}'..."

docker compose exec -T "${PG_SERVICE}" \
  psql -U "${PG_USER}" -d postgres -c "DROP DATABASE IF EXISTS ${PG_DB};"

docker compose exec -T "${PG_SERVICE}" \
  psql -U "${PG_USER}" -d postgres -c "CREATE DATABASE ${PG_DB} OWNER ${PG_USER};"

cat "${WORK_DIR}/mayan_db.sql" | \
  docker compose exec -T "${PG_SERVICE}" \
  psql -U "${PG_USER}" "${PG_DB}"

echo "$(msg RESTORE_DB_COMPLETE)"
echo

# 9. Start complete stack / Gesamt-Stack starten
echo "$(msg RESTORE_START_STACK)"
docker compose up -d
echo "$(msg RESTORE_STACK_STARTED)"
echo

# 10. Cleanup / Aufräumen
rm -rf "${WORK_DIR}"

IP_ADDR=$(hostname -I | awk '{print $1}' | head -1)
echo "=== $(msg RESTORE_COMPLETE) ==="
echo "$(msg RESTORE_ACCESS) http://${IP_ADDR}"
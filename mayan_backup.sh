#!/bin/bash
# =============================================================================
# Mayan EDMS Backup-Script
# - Passend zum Kyborg-Setup (/srv/mayan, /var/lib/mayan_postgres)
# - Erstellt tar.gz mit:
#     * PostgreSQL-Dump (mayan_db.sql)
#     * /srv/mayan/app_data, staging, watch, redis_data, elasticsearch_data
#     * /var/lib/mayan_postgres
#     * docker-compose.yml
# =============================================================================

set -euo pipefail

STACK_DIR="/srv/mayan"
BACKUP_ROOT="/srv/mayan_backups"
PG_SERVICE="mayan_postgres"
PG_DB="mayan"
PG_USER="mayan"

TIMESTAMP="$(date +%F_%H-%M-%S)"
BACKUP_NAME="mayan-backup-${TIMESTAMP}.tar.gz"

echo "=== Mayan EDMS Backup ==="
echo "Stack-Verzeichnis : ${STACK_DIR}"
echo "Backup-Verzeichnis: ${BACKUP_ROOT}"
echo

# 1. Prüfungen
if [[ ! -d "${STACK_DIR}" ]]; then
  echo "FEHLER: Stack-Verzeichnis ${STACK_DIR} existiert nicht."
  exit 1
fi

cd "${STACK_DIR}"

if ! command -v docker >/dev/null 2>&1; then
  echo "FEHLER: docker nicht gefunden."
  exit 1
fi

# 2. Temp-Verzeichnis
WORK_DIR="$(mktemp -d)"
echo "Arbeitsverzeichnis: ${WORK_DIR}"
mkdir -p "${BACKUP_ROOT}"
echo

# 3. PostgreSQL-Dump aus dem Container
echo "Erstelle PostgreSQL-Dump aus Container '${PG_SERVICE}'..."
docker compose exec -T "${PG_SERVICE}" \
  pg_dump -U "${PG_USER}" "${PG_DB}" > "${WORK_DIR}/mayan_db.sql"
echo "Datenbank-Dump: ${WORK_DIR}/mayan_db.sql"
echo

# 4. docker-compose.yml sichern
if [[ -f "${STACK_DIR}/docker-compose.yml" ]]; then
  cp "${STACK_DIR}/docker-compose.yml" "${WORK_DIR}/docker-compose.yml"
  echo "docker-compose.yml hinzugefügt."
else
  echo "WARNUNG: ${STACK_DIR}/docker-compose.yml nicht gefunden – lege Platzhalter an."
  touch "${WORK_DIR}/docker-compose.yml"
fi
echo

# 5. Archiv erstellen
echo "Erstelle Archiv ${BACKUP_ROOT}/${BACKUP_NAME} ..."
tar czf "${BACKUP_ROOT}/${BACKUP_NAME}" \
  -C "${WORK_DIR}" mayan_db.sql docker-compose.yml \
  -C /srv/mayan app_data staging watch redis_data elasticsearch_data \
  -C /var/lib mayan_postgres

echo "Archiv fertig: ${BACKUP_ROOT}/${BACKUP_NAME}"
echo

# 6. Aufräumen
rm -rf "${WORK_DIR}"

# 7. Rotation (nur die letzten 7 Backups behalten)
KEEP=7
echo "Bereinige alte Backups (behalte die letzten ${KEEP})..."
BACKUPS=( $(ls -1t "${BACKUP_ROOT}"/mayan-backup-*.tar.gz 2>/dev/null || true) )

if (( ${#BACKUPS[@]} > KEEP )); then
  TO_DELETE=( "${BACKUPS[@]:KEEP}" )
  for f in "${TO_DELETE[@]}"; do
    echo "Lösche altes Backup: $f"
    rm -f "$f"
  done
else
  echo "Keine alten Backups zu löschen."
fi

echo
echo "=== Backup abgeschlossen ==="
#!/bin/bash
# =============================================================================
# Mayan EDMS Backup-Script
# - Für Stack nach deinem Installationsscript (/srv/mayan, externe Postgres)
# - Erstellt tar.gz mit:
#     * PostgreSQL-Dump
#     * /srv/mayan/app_data, staging, watch, redis_data, elasticsearch_data
#     * /var/lib/mayan_postgres
#     * docker-compose.yml
# =============================================================================

set -euo pipefail

STACK_DIR="/srv/mayan"
BACKUP_ROOT="/srv/mayan_backups"
TIMESTAMP="$(date +%F_%H-%M-%S)"
BACKUP_NAME="mayan-backup-${TIMESTAMP}.tar.gz"

# Name des Postgres-Services und DB/User (lt. Installationsscript)
PG_SERVICE="mayan_postgres"
PG_DB="mayan"
PG_USER="mayan"

echo "=== Mayan EDMS Backup ==="
echo "Stack-Verzeichnis: ${STACK_DIR}"
echo "Backup-Ziel:       ${BACKUP_ROOT}/${BACKUP_NAME}"
echo

# ---------------------------------------------------------------------------
# 1. Temp-Verzeichnis für Zwischendaten (DB-Dump, Compose-Datei)
# ---------------------------------------------------------------------------
WORK_DIR="$(mktemp -d)"
echo "Arbeitsverzeichnis: ${WORK_DIR}"
echo

# ---------------------------------------------------------------------------
# 2. PostgreSQL-Dump aus dem Container ziehen
# ---------------------------------------------------------------------------
echo "Erstelle PostgreSQL-Dump aus Container '${PG_SERVICE}'..."

cd "${STACK_DIR}"

# -T: kein TTY (cron-freundlich)
docker compose exec -T "${PG_SERVICE}" \
  pg_dump -U "${PG_USER}" "${PG_DB}" > "${WORK_DIR}/mayan_db.sql"

echo "Datenbank-Dump gespeichert unter: ${WORK_DIR}/mayan_db.sql"
echo

# ---------------------------------------------------------------------------
# 3. docker-compose.yml sichern
# ---------------------------------------------------------------------------
if [[ -f "${STACK_DIR}/docker-compose.yml" ]]; then
  cp "${STACK_DIR}/docker-compose.yml" "${WORK_DIR}/docker-compose.yml"
  echo "docker-compose.yml hinzugefügt."
else
  echo "WARNUNG: ${STACK_DIR}/docker-compose.yml nicht gefunden!"
fi
echo

# ---------------------------------------------------------------------------
# 4. tar.gz Archiv erstellen
# ---------------------------------------------------------------------------
mkdir -p "${BACKUP_ROOT}"

echo "Erstelle Archiv ${BACKUP_ROOT}/${BACKUP_NAME} ..."
tar czf "${BACKUP_ROOT}/${BACKUP_NAME}" \
  -C "${WORK_DIR}" mayan_db.sql docker-compose.yml 2>/dev/null || true

# Mayan-Daten & Volumes hinzufügen
tar --append -zf "${BACKUP_ROOT}/${BACKUP_NAME}" \
  -C /srv/mayan app_data staging watch redis_data elasticsearch_data 2>/dev/null || true

# PostgreSQL-Datendirectory (physisch) – optional, „Bonus“ neben pg_dump
tar --append -zf "${BACKUP_ROOT}/${BACKUP_NAME}" \
  -C /var/lib mayan_postgres 2>/dev/null || true

echo "Archiv fertig."
echo

# ---------------------------------------------------------------------------
# 5. Aufräumen
# ---------------------------------------------------------------------------
rm -rf "${WORK_DIR}"

# ---------------------------------------------------------------------------
# 6. Optionale Rotation (z.B. nur die letzten 7 Backups behalten)
# ---------------------------------------------------------------------------
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
echo "Datei: ${BACKUP_ROOT}/${BACKUP_NAME}"
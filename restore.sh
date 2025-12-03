#!/bin/bash
# =============================================================================
# Mayan EDMS Restore-Script
# - Passend zum Backup-Script /srv/mayan_backups/mayan-backup-*.tar.gz
# - Stellt:
#     * PostgreSQL-Dump (mayan_db.sql)
#     * /srv/mayan/app_data, staging, watch, redis_data, elasticsearch_data
#     * optional /var/lib/mayan_postgres
#     * docker-compose.yml (falls fehlt)
#   wieder her und importiert die DB.
# =============================================================================

set -euo pipefail

STACK_DIR="/srv/mayan"
BACKUP_ROOT="/srv/mayan_backups"
PG_SERVICE="mayan_postgres"
PG_DB="mayan"
PG_USER="mayan"

echo "=== Mayan EDMS Restore ==="
echo "Stack-Verzeichnis: ${STACK_DIR}"
echo "Backup-Verzeichnis: ${BACKUP_ROOT}"
echo

# ---------------------------------------------------------------------------
# 1. Backup-Datei auswählen
# ---------------------------------------------------------------------------
if [[ ! -d "${BACKUP_ROOT}" ]]; then
  echo "FEHLER: Backup-Verzeichnis ${BACKUP_ROOT} existiert nicht."
  exit 1
fi

LATEST_BACKUP="$(ls -1t "${BACKUP_ROOT}"/mayan-backup-*.tar.gz 2>/dev/null | head -n 1 || true)"

if [[ -z "${LATEST_BACKUP}" ]]; then
  echo "FEHLER: Keine Backup-Dateien unter ${BACKUP_ROOT} gefunden."
  exit 1
fi

echo "Neueste Backup-Datei: ${LATEST_BACKUP}"
read -r -p "Pfad zur Backup-Datei (Enter = neuestes Backup verwenden): " BACKUP_FILE
BACKUP_FILE=${BACKUP_FILE:-${LATEST_BACKUP}}

if [[ ! -f "${BACKUP_FILE}" ]]; then
  echo "FEHLER: Backup-Datei ${BACKUP_FILE} existiert nicht."
  exit 1
fi

echo
echo "Verwende Backup-Datei: ${BACKUP_FILE}"
echo

# ---------------------------------------------------------------------------
# 2. Sicherheitsabfrage
# ---------------------------------------------------------------------------
echo "WARNUNG: Der Restore überschreibt bestehende Mayan-Daten und die Datenbank '${PG_DB}'."
read -r -p "Fortfahren? (ja/NEIN): " CONFIRM
CONFIRM=${CONFIRM:-NEIN}

if [[ "${CONFIRM}" != "ja" ]]; then
  echo "Abgebrochen."
  exit 0
fi

# ---------------------------------------------------------------------------
# 3. Dienste stoppen
# ---------------------------------------------------------------------------
echo "Stoppe laufende Docker-Services..."
cd "${STACK_DIR}"
sudo docker compose down || true
echo

# ---------------------------------------------------------------------------
# 4. Temp-Verzeichnis anlegen & Backup entpacken
# ---------------------------------------------------------------------------
WORK_DIR="$(mktemp -d)"
echo "Arbeitsverzeichnis: ${WORK_DIR}"
echo "Entpacke Backup..."
tar xzf "${BACKUP_FILE}" -C "${WORK_DIR}"
echo "Entpacken erledigt."
echo

# ---------------------------------------------------------------------------
# 5. docker-compose.yml wiederherstellen (wenn nötig)
# ---------------------------------------------------------------------------
if [[ ! -f "${STACK_DIR}/docker-compose.yml" ]]; then
  if [[ -f "${WORK_DIR}/docker-compose.yml" ]]; then
    echo "docker-compose.yml aus Backup wiederherstellen..."
    sudo cp "${WORK_DIR}/docker-compose.yml" "${STACK_DIR}/docker-compose.yml"
  else
    echo "WARNUNG: Keine docker-compose.yml im Backup gefunden."
  fi
else
  echo "docker-compose.yml im Stack-Verzeichnis vorhanden – belasse aktuelle Datei."
fi
echo

# ---------------------------------------------------------------------------
# 6. Dateien/Verzeichnisse wiederherstellen
#    (Mayan-Daten & optionale Backend-Daten)
# ---------------------------------------------------------------------------
echo "Stelle Mayan-Dateiverzeichnisse wieder her..."

# Zielverzeichnisse sicherstellen
sudo mkdir -p /srv/mayan/{app_data,staging,watch,redis_data,elasticsearch_data}
sudo mkdir -p /var/lib/mayan_postgres

# app_data, staging, watch, redis_data, elasticsearch_data
for DIR in app_data staging watch redis_data elasticsearch_data; do
  if [[ -d "${WORK_DIR}/${DIR}" ]]; then
    echo "  -> ${DIR} nach /srv/mayan/${DIR}"
    sudo rm -rf "/srv/mayan/${DIR}"
    sudo mkdir -p "/srv/mayan/${DIR}"
    sudo cp -a "${WORK_DIR}/${DIR}/." "/srv/mayan/${DIR}/"
  else
    echo "  (Hinweis: ${DIR} nicht im Backup gefunden – übersprungen)"
  fi
done

# Physische Postgres-Daten (optional)
if [[ -d "${WORK_DIR}/mayan_postgres" ]]; then
  echo "  -> PostgreSQL-Datenverzeichnis nach /var/lib/mayan_postgres (optional, Bonus)"
  sudo rm -rf /var/lib/mayan_postgres
  sudo mkdir -p /var/lib/mayan_postgres
  sudo cp -a "${WORK_DIR}/mayan_postgres/." /var/lib/mayan_postgres/
else
  echo "  (Hinweis: mayan_postgres nicht im Backup gefunden – physisches PG-Verzeichnis bleibt unverändert/leer)"
fi

echo "Datei- und Verzeichnisrestore abgeschlossen."
echo

# ---------------------------------------------------------------------------
# 7. Berechtigungen korrigieren
# ---------------------------------------------------------------------------
echo "Setze Dateiberechtigungen..."

sudo chown 999:999   /var/lib/mayan_postgres
sudo chown 100:100   /srv/mayan/redis_data
sudo chown 1000:1000 /srv/mayan/elasticsearch_data
sudo chown 1001:1001 /srv/mayan/app_data /srv/mayan/staging /srv/mayan/watch

echo "Berechtigungen gesetzt."
echo

# ---------------------------------------------------------------------------
# 8. PostgreSQL-Datenbank aus Dump wiederherstellen
# ---------------------------------------------------------------------------
if [[ ! -f "${WORK_DIR}/mayan_db.sql" ]]; then
  echo "FEHLER: mayan_db.sql im Backup nicht gefunden. Kein DB-Restore möglich."
  rm -rf "${WORK_DIR}"
  exit 1
fi

echo "Starte nur den PostgreSQL-Service..."
sudo docker compose up -d "${PG_SERVICE}"

echo -n "Warte auf PostgreSQL"
for i in {1..60}; do
    if sudo docker compose logs "${PG_SERVICE}" 2>/dev/null | grep -q "database system is ready to accept connections"; then
        echo -e "\nPostgreSQL ist bereit."
        break
    fi
    echo -n "."
    sleep 1
done
echo

echo "Stelle Datenbank '${PG_DB}' wieder her (DROP & CREATE + Import)..."

# DB droppen und neu anlegen
sudo docker compose exec -T "${PG_SERVICE}" \
  psql -U "${PG_USER}" -d postgres -c "DROP DATABASE IF EXISTS ${PG_DB};"

sudo docker compose exec -T "${PG_SERVICE}" \
  psql -U "${PG_USER}" -d postgres -c "CREATE DATABASE ${PG_DB} OWNER ${PG_USER};"

# Dump einspielen
cat "${WORK_DIR}/mayan_db.sql" | \
  sudo docker compose exec -T "${PG_SERVICE}" \
  psql -U "${PG_USER}" "${PG_DB}"

echo "Datenbank-Import abgeschlossen."
echo

# ---------------------------------------------------------------------------
# 9. Gesamt-Stack wieder hochfahren
# ---------------------------------------------------------------------------
echo "Starte kompletten Mayan-Stack..."
sudo docker compose up -d

echo "Stack gestartet."
echo

# ---------------------------------------------------------------------------
# 10. Aufräumen
# ---------------------------------------------------------------------------
rm -rf "${WORK_DIR}"

IP_ADDR=$(hostname -I | awk '{print $1}' | head -1)
echo "=== Restore abgeschlossen ==="
echo "Mayan EDMS sollte unter http://${IP_ADDR} erreichbar sein."
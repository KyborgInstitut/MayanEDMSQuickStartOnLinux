#!/bin/bash
# =============================================================================
# Mayan EDMS – Management & Installation Script
# Für Ubuntu 22.04 / 24.04 auf dedizierter VM oder Proxmox KVM (kein LXC!)
# Stand: 03.12.2024
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAYAN_DIR="/srv/mayan"
BACKUP_DIR="/srv/mayan_backups"

# =============================================================================
# Helper Functions
# =============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Dieses Script muss als root ausgeführt werden!${NC}"
        echo "Bitte verwenden: sudo $0"
        exit 1
    fi
}

check_mayan_installed() {
    if [[ -f "${MAYAN_DIR}/docker-compose.yml" ]] && docker compose -f "${MAYAN_DIR}/docker-compose.yml" ps -q mayan_app &>/dev/null; then
        return 0  # Installed
    else
        return 1  # Not installed
    fi
}

press_enter() {
    echo ""
    read -p "Drücke Enter zum Fortfahren..."
}

# =============================================================================
# Main Menu
# =============================================================================

show_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}Mayan EDMS – Management & Installation Script${NC}         ${BLUE}║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"

    if check_mayan_installed; then
        echo -e "${BLUE}║${NC}  ${GREEN}Status: Mayan EDMS ist installiert ✓${NC}                    ${BLUE}║${NC}"
    else
        echo -e "${BLUE}║${NC}  ${YELLOW}Status: Mayan EDMS ist NICHT installiert${NC}                ${BLUE}║${NC}"
    fi

    echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC}  ${YELLOW}Wähle eine Option:${NC}                                       ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}1)${NC} Mayan EDMS installieren (Erstinstallation)          ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}     → Inklusive preTypes Import (optional)                ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}2)${NC} SMB/Scanner-Zugang einrichten                        ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}     → Samba-Freigabe für Scanner/macOS                    ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}3)${NC} Backup erstellen                                     ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}     → Sichert Datenbank + Dateien                         ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}4)${NC} Backup-Cronjob einrichten                            ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}     → Automatische tägliche Backups                        ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}5)${NC} Backup wiederherstellen                              ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}     → Restore aus Backup-Archiv                           ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}6)${NC} Mayan Status anzeigen                                ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}     → Container-Status, Logs, URLs                        ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}7)${NC} Dokumentquellen konfigurieren                        ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}     → Watch/Staging Folder in GUI einrichten              ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}8)${NC} Problemlösung & Diagnose                             ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}     → Worker-Timeouts, Celery-Broker, Import-Tests       ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}0)${NC} Beenden                                              ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Deine Wahl [0-8]: " choice
    echo ""
}

# =============================================================================
# Option 1: Initial Installation
# =============================================================================

install_mayan() {
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Mayan EDMS Installation${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    # Check if already installed
    if check_mayan_installed; then
        echo -e "${YELLOW}⚠ Mayan EDMS ist bereits installiert!${NC}"
        echo ""
        read -p "Möchten Sie die Installation überschreiben? (ja/NEIN): " OVERWRITE
        if [[ "${OVERWRITE}" != "ja" ]]; then
            echo "Installation abgebrochen."
            press_enter
            return
        fi
        echo ""
        echo -e "${YELLOW}Stoppe existierende Installation...${NC}"
        cd "${MAYAN_DIR}" && docker compose down || true
    fi

    # ------------------------------------------------------------------
    # 1. Systemzeit korrigieren
    # ------------------------------------------------------------------
    echo -e "${BLUE}[1/9] Korrigiere Systemzeit...${NC}"
    apt-get update -qq || true
    DEBIAN_FRONTEND=noninteractive apt-get install -yqq chrony >/dev/null 2>&1
    chronyc makestep >/dev/null 2>&1 || true
    sleep 2
    echo -e "${GREEN}✓ Systemzeit synchronisiert${NC}"
    echo ""

    # ------------------------------------------------------------------
    # 2. Passwörter abfragen
    # ------------------------------------------------------------------
    echo -e "${BLUE}[2/9] Passwort-Konfiguration${NC}"
    while true; do
        echo -n "Starkes Passwort für PostgreSQL/Mayan (min. 16 Zeichen): "
        read -s DBPASS1
        echo
        echo -n "Wiederhole das Passwort: "
        read -s DBPASS2
        echo
        if [[ "$DBPASS1" == "$DBPASS2" && ${#DBPASS1} -ge 16 ]]; then
            MAYAN_DB_PASSWORD="$DBPASS1"
            break
        else
            echo -e "${RED}Passwörter stimmen nicht überein oder sind zu kurz!${NC}"
        fi
    done
    echo -e "${GREEN}✓ Passwort gesetzt${NC}"
    echo ""

    # ------------------------------------------------------------------
    # 3. Grundkonfiguration
    # ------------------------------------------------------------------
    echo -e "${BLUE}[3/9] Grundkonfiguration${NC}"

    read -r -p "Zeitzone (Enter = Europe/Berlin): " MAYAN_TZ
    MAYAN_TZ=${MAYAN_TZ:-Europe/Berlin}

    read -r -p "Sprache (Enter = de): " MAYAN_LANG
    MAYAN_LANG=${MAYAN_LANG:-de}

    echo ""
    echo -e "${YELLOW}Hinweis: Mayan erstellt automatisch einen Admin-User${NC}"
    echo "  Standard-Benutzername: admin"
    echo "  Standard-Passwort: admin"
    echo "  Ändern Sie das Passwort nach dem ersten Login!"
    echo ""

    read -r -p "Django Debug aktivieren? (nur Test) (y/N): " DEBUG_CHOICE
    DEBUG_CHOICE=${DEBUG_CHOICE:-N}
    if [[ "$DEBUG_CHOICE" =~ ^[yY]$ ]]; then
        MAYAN_DEBUG="True"
    else
        MAYAN_DEBUG="False"
    fi

    read -r -p "ALLOWED_HOSTS (Enter = *): " MAYAN_ALLOWED_HOSTS
    MAYAN_ALLOWED_HOSTS=${MAYAN_ALLOWED_HOSTS:-*}

    echo -e "${GREEN}✓ Grundkonfiguration abgeschlossen${NC}"
    echo ""

    # ------------------------------------------------------------------
    # 4. SMTP-Konfiguration
    # ------------------------------------------------------------------
    echo -e "${BLUE}[4/9] SMTP-Konfiguration (optional)${NC}"
    SMTP_ENV=""

    read -r -p "SMTP/Mail-Versand konfigurieren? (j/N): " SMTP_CHOICE
    SMTP_CHOICE=${SMTP_CHOICE:-N}

    if [[ "$SMTP_CHOICE" =~ ^[jJ]$ ]]; then
        read -r -p "SMTP-Host: " SMTP_HOST
        read -r -p "SMTP-Port (Enter = 587): " SMTP_PORT
        SMTP_PORT=${SMTP_PORT:-587}
        read -r -p "SMTP-Benutzer: " SMTP_USER
        echo -n "SMTP-Passwort: "
        read -s SMTP_PASS
        echo
        read -r -p "TLS verwenden? (Enter = True): " SMTP_TLS
        SMTP_TLS=${SMTP_TLS:-True}

        SMTP_ENV="      MAYAN_EMAIL_HOST: ${SMTP_HOST}
      MAYAN_EMAIL_PORT: \"${SMTP_PORT}\"
      MAYAN_EMAIL_HOST_USER: \"${SMTP_USER}\"
      MAYAN_EMAIL_HOST_PASSWORD: \"${SMTP_PASS}\"
      MAYAN_EMAIL_USE_TLS: \"${SMTP_TLS}\""

        echo -e "${GREEN}✓ SMTP konfiguriert${NC}"
    else
        echo -e "${YELLOW}⊘ SMTP übersprungen${NC}"
    fi
    echo ""

    # ------------------------------------------------------------------
    # 5. Docker & Verzeichnisse
    # ------------------------------------------------------------------
    echo -e "${BLUE}[5/9] Docker & Verzeichnisse${NC}"

    mkdir -p "${MAYAN_DIR}"
    chown "$SUDO_USER:$SUDO_USER" "${MAYAN_DIR}" 2>/dev/null || chown root:root "${MAYAN_DIR}"
    cd "${MAYAN_DIR}"

    if ! command -v docker &>/dev/null; then
        echo "Installiere Docker..."
        curl -fsSL https://get.docker.com | sh
    fi

    mkdir -p /etc/sysctl.d
    echo "kernel.shmmax = 1073741824" > /etc/sysctl.d/99-mayan.conf
    sysctl -p /etc/sysctl.d/99-mayan.conf >/dev/null

    mkdir -p /var/lib/mayan_postgres
    mkdir -p "${MAYAN_DIR}"/{redis_data,elasticsearch_data,app_data,staging,watch}

    chown 999:999   /var/lib/mayan_postgres
    chown 100:100   "${MAYAN_DIR}/redis_data"
    chown 1000:1000 "${MAYAN_DIR}/elasticsearch_data"
    chown 1001:1001 "${MAYAN_DIR}/app_data" "${MAYAN_DIR}/staging" "${MAYAN_DIR}/watch"

    echo -e "${GREEN}✓ Verzeichnisse angelegt${NC}"
    echo ""

    # ------------------------------------------------------------------
    # 6. docker-compose.yml erstellen
    # ------------------------------------------------------------------
    echo -e "${BLUE}[6/9] Erstelle docker-compose.yml${NC}"

    cat > docker-compose.yml <<EOF
services:
  mayan_postgres:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_DB: mayan
      POSTGRES_USER: mayan
      POSTGRES_PASSWORD: ${MAYAN_DB_PASSWORD}
    volumes:
      - /var/lib/mayan_postgres:/var/lib/postgresql/data

  mayan_redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - ${MAYAN_DIR}/redis_data:/data

  mayan_elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.15.2
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
    ulimits:
      memlock: -1
    volumes:
      - ${MAYAN_DIR}/elasticsearch_data:/usr/share/elasticsearch/data

  mayan_app:
    image: mayanedms/mayanedms:latest
    restart: unless-stopped
    depends_on:
      - mayan_postgres
      - mayan_redis
      - mayan_elasticsearch
    environment:
$( [[ -n "$SMTP_ENV" ]] && echo "$SMTP_ENV" )
      MAYAN_DATABASE_ENGINE: django.db.backends.postgresql
      MAYAN_DATABASE_HOST: mayan_postgres
      MAYAN_DATABASE_NAME: mayan
      MAYAN_DATABASE_USER: mayan
      MAYAN_DATABASE_PASSWORD: ${MAYAN_DB_PASSWORD}
      MAYAN_REDIS_URL: redis://mayan_redis:6379/1
      MAYAN_CELERY_BROKER_URL: redis://mayan_redis:6379/1
      MAYAN_CELERY_RESULT_BACKEND: redis://mayan_redis:6379/1
      MAYAN_GUNICORN_TIMEOUT: "300"
      MAYAN_CELERY_TASK_TIME_LIMIT: "7200"
      MAYAN_CELERY_TASK_SOFT_TIME_LIMIT: "6900"
    volumes:
      - ${MAYAN_DIR}/app_data:/var/lib/mayan
      - ${MAYAN_DIR}/staging:/staging_folder
      - ${MAYAN_DIR}/watch:/watch_folder
    ports:
      - "80:8000"
EOF

    echo -e "${GREEN}✓ docker-compose.yml erstellt${NC}"
    echo ""

    # ------------------------------------------------------------------
    # 7. Mayan starten
    # ------------------------------------------------------------------
    echo -e "${BLUE}[7/9] Starte Mayan EDMS${NC}"
    echo "Bitte 2-4 Minuten Geduld..."

    docker compose down -v >/dev/null 2>&1 || true
    docker compose up -d

    echo -n "Warte auf PostgreSQL"
    for i in {1..60}; do
        if docker compose logs mayan_postgres 2>/dev/null | grep -q "database system is ready to accept connections"; then
            echo ""
            echo -e "${GREEN}✓ PostgreSQL bereit${NC}"
            break
        fi
        echo -n "."
        sleep 1
    done
    echo ""

    # Kurze Wartezeit für initiale Mayan-Initialisierung
    echo "Warte auf Mayan Initialisierung (dies kann 3-5 Minuten dauern)..."
    echo "Mayan lädt Datenbank-Schema, erstellt Admin-User und startet Worker..."
    sleep 180  # 3 Minuten Wartezeit

    # Schnelle Prüfung ob Container läuft
    if docker compose ps mayan_app | grep -q "Up"; then
        echo -e "${GREEN}✓ Mayan Container läuft${NC}"
    else
        echo -e "${YELLOW}⚠ Mayan Container möglicherweise noch nicht bereit${NC}"
        echo "Prüfen Sie: docker compose logs -f mayan_app"
    fi
    echo ""


    # ------------------------------------------------------------------
    # 8. preTypes Import (optional)
    # ------------------------------------------------------------------
    echo -e "${BLUE}[8/9] preTypes Import (optional)${NC}"
    echo ""
    read -r -p "Möchten Sie die preTypes (273 Metadaten, 113 Dokumenttypen, etc.) importieren? (j/N): " IMPORT_PRETYPES
    IMPORT_PRETYPES=${IMPORT_PRETYPES:-N}

    if [[ "$IMPORT_PRETYPES" =~ ^[jJ]$ ]]; then
        # Restart mayan_app to ensure clean configuration without problematic env vars
        echo -e "${BLUE}Bereite Container für Import vor...${NC}"
        docker compose up -d --force-recreate mayan_app

        echo -n "Warte auf Neustart (30 Sekunden)"
        for i in {1..30}; do
            echo -n "."
            sleep 1
        done
        echo ""
        echo -e "${GREEN}✓ Container bereit${NC}"
        echo ""

        if [[ -d "${SCRIPT_DIR}/preTypes" ]]; then
            echo "Kopiere preTypes ins Container..."
            echo "Quelle: ${SCRIPT_DIR}/preTypes"

            # Ensure /srv/mayan exists in container and copy preTypes folder
            docker compose exec -T mayan_app mkdir -p /srv/mayan
            docker compose cp "${SCRIPT_DIR}/preTypes" mayan_app:/srv/mayan/preTypes

            if [[ -f "${SCRIPT_DIR}/import_preTypes.sh" ]]; then
                echo "Kopiere Import-Skripte..."
                docker compose cp "${SCRIPT_DIR}/import_preTypes.sh" mayan_app:/srv/mayan/import_preTypes.sh
                docker compose cp "${SCRIPT_DIR}/import_cabinets_api.py" mayan_app:/srv/mayan/import_cabinets_api.py 2>/dev/null || true

                echo "Verzeichnisinhalt im Container:"
                docker compose exec -T mayan_app ls -la /srv/mayan/ | grep -E "(preTypes|import_)" || true

                echo ""
                echo "Starte Import..."
                docker compose exec -T mayan_app bash /srv/mayan/import_preTypes.sh

                echo ""
                echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
                echo -e "${YELLOW}WICHTIG: Post-Import Schritte${NC}"
                echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
                echo ""
                echo "1. Rollen-Berechtigungen zuweisen (07_roles.json):"
                echo "   → System → Rollen → Rolle bearbeiten → Berechtigungen"
                echo ""
                echo "2. Gespeicherte Suchen konfigurieren (09_saved_searches.json):"
                echo "   → Suche → Erweiterte Suche → Suche speichern"
                echo ""
                echo -e "${YELLOW}Details: ${SCRIPT_DIR}/IMPORT_GUIDE.md${NC}"
                echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
            else
                echo -e "${YELLOW}⚠ import_preTypes.sh nicht gefunden - bitte manuell importieren${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ preTypes Verzeichnis nicht gefunden: ${SCRIPT_DIR}/preTypes${NC}"
        fi
    else
        echo -e "${YELLOW}⊘ preTypes Import übersprungen${NC}"
    fi
    echo ""

    # ------------------------------------------------------------------
    # 8a. Dokumentquellen konfigurieren (optional)
    # ------------------------------------------------------------------
    echo -e "${BLUE}[8a/9] Dokumentquellen (Watch/Staging Folder) konfigurieren?${NC}"
    echo ""
    echo "Möchten Sie jetzt die Dokumentquellen einrichten?"
    echo "  - Watch Folder: Automatischer Import von /srv/mayan/watch/"
    echo "  - Staging Folder: Manueller Upload via Web-GUI"
    echo ""
    read -p "Dokumentquellen jetzt konfigurieren? (j/N): " SETUP_SOURCES

    if [[ "$SETUP_SOURCES" =~ ^[jJyY]$ ]]; then
        echo ""
        echo -e "${BLUE}Konfiguriere Dokumentquellen...${NC}"

        if [[ -f "${SCRIPT_DIR}/configure_sources.py" ]]; then
            # Run as mayan user to avoid permission issues
            # Redirect stdin from the script in SCRIPT_DIR (works regardless of location)
            docker compose exec -T --user mayan mayan_app /opt/mayan-edms/bin/mayan-edms.py shell < "${SCRIPT_DIR}/configure_sources.py"

            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Dokumentquellen konfiguriert${NC}"
            else
                echo -e "${YELLOW}⚠ Konfiguration der Quellen fehlgeschlagen${NC}"
                echo "  Sie können dies später über Menü-Option 7 nachholen"
            fi
        else
            echo -e "${YELLOW}⚠ configure_sources.py nicht gefunden${NC}"
            echo "  Sie können dies später über Menü-Option 7 nachholen"
        fi
    else
        echo -e "${YELLOW}⊘ Dokumentquellen können später über Option 7 konfiguriert werden${NC}"
    fi
    echo ""

    # ------------------------------------------------------------------
    # 9. Fertig!
    # ------------------------------------------------------------------
    echo -e "${BLUE}[9/9] Installation abgeschlossen!${NC}"
    echo ""

    IP_ADDR=$(hostname -I | awk '{print $1}' | head -1)

    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Mayan EDMS läuft!${NC}                                        ${GREEN}║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}  URL: ${YELLOW}http://${IP_ADDR}${NC}                                  ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  Admin: ${YELLOW}admin${NC} / Passwort: ${YELLOW}admin${NC}                          ${GREEN}║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}  Nützliche Befehle:                                       ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  cd ${MAYAN_DIR}                                           ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  docker compose logs -f mayan_app${NC}                     ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  docker compose restart${NC}                               ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  docker compose down${NC}                                  ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"

    press_enter
}

# =============================================================================
# Option 2: SMB Setup
# =============================================================================

setup_smb() {
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  SMB/Scanner-Zugang einrichten${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    if [[ -f "${SCRIPT_DIR}/mayan_smb.sh" ]]; then
        bash "${SCRIPT_DIR}/mayan_smb.sh"
    else
        echo -e "${RED}Fehler: mayan_smb.sh nicht gefunden!${NC}"
        echo "Erwartet in: ${SCRIPT_DIR}/mayan_smb.sh"
    fi

    press_enter
}

# =============================================================================
# Option 3: Backup
# =============================================================================

create_backup() {
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Backup erstellen${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    if ! check_mayan_installed; then
        echo -e "${RED}Fehler: Mayan EDMS ist nicht installiert!${NC}"
        press_enter
        return
    fi

    if [[ -f "${SCRIPT_DIR}/mayan_backup.sh" ]]; then
        bash "${SCRIPT_DIR}/mayan_backup.sh"
    else
        echo -e "${YELLOW}mayan_backup.sh nicht gefunden - verwende Inline-Backup...${NC}"
        echo ""

        mkdir -p "${BACKUP_DIR}"
        TIMESTAMP="$(date +%F_%H-%M-%S)"
        BACKUP_NAME="mayan-backup-${TIMESTAMP}.tar.gz"

        echo "Erstelle PostgreSQL-Dump..."
        WORK_DIR="$(mktemp -d)"
        cd "${MAYAN_DIR}"
        docker compose exec -T mayan_postgres pg_dump -U mayan mayan > "${WORK_DIR}/mayan_db.sql"

        echo "Kopiere docker-compose.yml..."
        cp docker-compose.yml "${WORK_DIR}/"

        echo "Erstelle Archiv..."
        tar czf "${BACKUP_DIR}/${BACKUP_NAME}" \
            -C "${WORK_DIR}" mayan_db.sql docker-compose.yml \
            -C "${MAYAN_DIR}" app_data staging watch redis_data elasticsearch_data \
            -C /var/lib mayan_postgres

        rm -rf "${WORK_DIR}"

        echo ""
        echo -e "${GREEN}✓ Backup erstellt: ${BACKUP_DIR}/${BACKUP_NAME}${NC}"

        # Cleanup old backups (keep 7)
        BACKUPS=( $(ls -1t "${BACKUP_DIR}"/mayan-backup-*.tar.gz 2>/dev/null || true) )
        if (( ${#BACKUPS[@]} > 7 )); then
            echo "Bereinige alte Backups (behalte 7)..."
            TO_DELETE=( "${BACKUPS[@]:7}" )
            for f in "${TO_DELETE[@]}"; do
                rm -f "$f"
                echo "  Gelöscht: $(basename $f)"
            done
        fi
    fi

    press_enter
}

# =============================================================================
# Option 4: Setup Backup Cronjob
# =============================================================================

setup_backup_cronjob() {
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Backup-Cronjob einrichten${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    if ! check_mayan_installed; then
        echo -e "${RED}Fehler: Mayan EDMS ist nicht installiert!${NC}"
        press_enter
        return
    fi

    if [[ ! -f "${SCRIPT_DIR}/mayan_backup.sh" ]]; then
        echo -e "${RED}Fehler: mayan_backup.sh nicht gefunden!${NC}"
        echo "Erwartet in: ${SCRIPT_DIR}/mayan_backup.sh"
        press_enter
        return
    fi

    echo "Wähle Backup-Zeitplan:"
    echo ""
    echo "1) Täglich um 02:00 Uhr"
    echo "2) Täglich um 03:00 Uhr"
    echo "3) Täglich um 04:00 Uhr"
    echo "4) Sonntags um 02:00 Uhr (wöchentlich)"
    echo "5) Benutzerdefiniert"
    echo "0) Abbrechen"
    echo ""
    read -p "Wahl [0-5]: " CRON_CHOICE

    case $CRON_CHOICE in
        1)
            CRON_SCHEDULE="0 2 * * *"
            CRON_DESC="täglich um 02:00 Uhr"
            ;;
        2)
            CRON_SCHEDULE="0 3 * * *"
            CRON_DESC="täglich um 03:00 Uhr"
            ;;
        3)
            CRON_SCHEDULE="0 4 * * *"
            CRON_DESC="täglich um 04:00 Uhr"
            ;;
        4)
            CRON_SCHEDULE="0 2 * * 0"
            CRON_DESC="sonntags um 02:00 Uhr"
            ;;
        5)
            echo ""
            echo "Gib den Cron-Zeitplan ein (Format: Minute Stunde Tag Monat Wochentag)"
            echo "Beispiel: 0 2 * * * = täglich um 02:00"
            echo "Beispiel: 30 3 * * 1 = montags um 03:30"
            echo ""
            read -p "Cron-Zeitplan: " CRON_SCHEDULE
            CRON_DESC="benutzerdefiniert: ${CRON_SCHEDULE}"
            ;;
        0|*)
            echo "Abgebrochen."
            press_enter
            return
            ;;
    esac

    # Create cronjob
    CRON_JOB="${CRON_SCHEDULE} ${SCRIPT_DIR}/mayan_backup.sh >> /var/log/mayan_backup.log 2>&1"

    # Remove existing mayan backup cronjobs
    crontab -l 2>/dev/null | grep -v "mayan_backup.sh" | crontab - || true

    # Add new cronjob
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

    echo ""
    echo -e "${GREEN}✓ Cronjob eingerichtet!${NC}"
    echo ""
    echo "Zeitplan: ${CRON_DESC}"
    echo "Script:   ${SCRIPT_DIR}/mayan_backup.sh"
    echo "Log:      /var/log/mayan_backup.log"
    echo ""
    echo "Aktive Cronjobs:"
    crontab -l | grep mayan_backup

    press_enter
}

# =============================================================================
# Option 5: Restore Backup
# =============================================================================

restore_backup() {
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Backup wiederherstellen${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    if [[ -f "${SCRIPT_DIR}/mayan_restore.sh" ]]; then
        bash "${SCRIPT_DIR}/mayan_restore.sh"
    else
        echo -e "${RED}Fehler: mayan_restore.sh nicht gefunden!${NC}"
        echo "Erwartet in: ${SCRIPT_DIR}/mayan_restore.sh"
    fi

    press_enter
}

# =============================================================================
# Option 6: Show Status
# =============================================================================

show_status() {
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Mayan EDMS Status${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    if ! check_mayan_installed; then
        echo -e "${RED}Mayan EDMS ist nicht installiert!${NC}"
        press_enter
        return
    fi

    cd "${MAYAN_DIR}"

    echo -e "${BLUE}Container Status:${NC}"
    docker compose ps
    echo ""

    echo -e "${BLUE}Disk Usage:${NC}"
    echo "PostgreSQL: $(du -sh /var/lib/mayan_postgres 2>/dev/null | awk '{print $1}' || echo 'N/A')"
    echo "App Data:   $(du -sh ${MAYAN_DIR}/app_data 2>/dev/null | awk '{print $1}' || echo 'N/A')"
    echo "Backups:    $(du -sh ${BACKUP_DIR} 2>/dev/null | awk '{print $1}' || echo 'N/A')"
    echo ""

    IP_ADDR=$(hostname -I | awk '{print $1}' | head -1)
    echo -e "${BLUE}URLs:${NC}"
    echo "Mayan Web: http://${IP_ADDR}"
    echo ""

    echo -e "${BLUE}Letzte Logs (mayan_app):${NC}"
    docker compose logs --tail=10 mayan_app
    echo ""

    echo "Vollständige Logs: cd ${MAYAN_DIR} && docker compose logs -f"

    press_enter
}

# =============================================================================
# Option 7: Configure Document Sources
# =============================================================================

configure_sources() {
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Dokumentquellen konfigurieren${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    if ! check_mayan_installed; then
        echo -e "${RED}Mayan EDMS ist nicht installiert!${NC}"
        echo "Bitte erst Mayan installieren (Option 1)"
        press_enter
        return
    fi

    cd "${MAYAN_DIR}"

    # Check if Mayan is running
    if ! docker compose ps mayan_app | grep -q "running"; then
        echo -e "${RED}Mayan Container läuft nicht!${NC}"
        echo "Starte Container..."
        docker compose up -d
        sleep 10
    fi

    echo "Diese Funktion konfiguriert folgende Dokumentquellen in Mayan:"
    echo ""
    echo "  1. Watch Folder: /srv/mayan/watch/"
    echo "     → Automatischer Import von Dokumenten"
    echo "     → Dateien werden nach Import gelöscht"
    echo ""
    echo "  2. Staging Folder: /srv/mayan/staging/"
    echo "     → Manueller Upload via Web-GUI"
    echo "     → Dateien bleiben nach Import erhalten"
    echo ""
    read -p "Fortfahren? (j/N): " CONFIRM

    if [[ ! "$CONFIRM" =~ ^[jJyY]$ ]]; then
        echo "Abgebrochen."
        press_enter
        return
    fi

    echo ""

    # Check if script exists
    if [[ ! -f "${SCRIPT_DIR}/configure_sources.py" ]]; then
        echo -e "${RED}✗ configure_sources.py nicht gefunden in ${SCRIPT_DIR}${NC}"
        press_enter
        return
    fi

    echo -e "${BLUE}Konfiguriere Dokumentquellen...${NC}"
    echo ""

    # Execute the Python script via Django shell as mayan user
    # Run as mayan user to avoid permission issues with lock manager
    # Redirect stdin from SCRIPT_DIR (works regardless of where scripts are located)
    docker compose exec -T --user mayan mayan_app /opt/mayan-edms/bin/mayan-edms.py shell < "${SCRIPT_DIR}/configure_sources.py"

    EXIT_CODE=$?

    echo ""

    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✓ Dokumentquellen erfolgreich konfiguriert!${NC}"
        echo ""
        echo "Zugriff in Mayan Web-GUI:"
        echo "  → Setup → Sources → Document sources"
        echo ""
        echo "Verwendung:"
        echo "  • Watch Folder:   sudo cp dokument.pdf /srv/mayan/watch/"
        echo "  • Staging Folder: sudo cp dokument.pdf /srv/mayan/staging/"
        echo "    dann in Mayan: Sources → Staging Folder → Upload"
    else
        echo -e "${RED}✗ Konfiguration fehlgeschlagen (Exit Code: ${EXIT_CODE})${NC}"
        echo "Prüfe die Fehlermeldungen oben."
    fi

    press_enter
}

# =============================================================================
# Option 8: Troubleshooting & Diagnostics Submenu
# =============================================================================

troubleshooting_menu() {
    while true; do
        clear
        echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║${NC}  ${GREEN}Problemlösung & Diagnose${NC}                                ${BLUE}║${NC}"
        echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}Wähle ein Diagnose-Tool:${NC}                                ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${GREEN}1)${NC} Celery Broker reparieren (KRITISCH)                 ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}     → Behebt: memory:// statt redis://                   ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}     → Dokumente werden nicht importiert                  ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${GREEN}2)${NC} Worker-Timeouts beheben                              ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}     → Behebt: WORKER TIMEOUT Fehler                      ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}     → Erhöht Gunicorn & Celery Zeitlimits               ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${GREEN}3)${NC} Worker-Diagnose ausführen                            ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}     → Zeigt: Celery Status, Queues, Ressourcen          ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}     → Prüft: OCR-Tools, Elasticsearch                    ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${GREEN}4)${NC} Konfiguration verifizieren & Import testen          ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}     → Überprüft: docker-compose.yml Einstellungen       ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}     → Testet: Dokumentquellen, Berechtigungen           ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${GREEN}5)${NC} Alle Diagnosen & Reparaturen (komplett)             ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}     → Führt 1-4 nacheinander aus                         ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}                                                            ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${GREEN}0)${NC} Zurück zum Hauptmenü                                 ${BLUE}║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Deine Wahl [0-5]: " tshooting_choice
        echo ""

        case $tshooting_choice in
            1)
                echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
                echo -e "${GREEN}  Celery Broker reparieren${NC}"
                echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
                echo ""
                if [[ -f "${SCRIPT_DIR}/fix_celery_broker.sh" ]]; then
                    bash "${SCRIPT_DIR}/fix_celery_broker.sh"
                else
                    echo -e "${RED}✗ fix_celery_broker.sh nicht gefunden in ${SCRIPT_DIR}${NC}"
                fi
                press_enter
                ;;
            2)
                echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
                echo -e "${GREEN}  Worker-Timeouts beheben${NC}"
                echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
                echo ""
                if [[ -f "${SCRIPT_DIR}/fix_worker_timeouts.sh" ]]; then
                    bash "${SCRIPT_DIR}/fix_worker_timeouts.sh"
                else
                    echo -e "${RED}✗ fix_worker_timeouts.sh nicht gefunden in ${SCRIPT_DIR}${NC}"
                fi
                press_enter
                ;;
            3)
                echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
                echo -e "${GREEN}  Worker-Diagnose${NC}"
                echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
                echo ""
                if [[ -f "${SCRIPT_DIR}/diagnose_workers.sh" ]]; then
                    bash "${SCRIPT_DIR}/diagnose_workers.sh"
                else
                    echo -e "${RED}✗ diagnose_workers.sh nicht gefunden in ${SCRIPT_DIR}${NC}"
                fi
                press_enter
                ;;
            4)
                echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
                echo -e "${GREEN}  Konfiguration verifizieren & Import testen${NC}"
                echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
                echo ""
                if [[ -f "${SCRIPT_DIR}/verify_and_test_import.sh" ]]; then
                    bash "${SCRIPT_DIR}/verify_and_test_import.sh"
                else
                    echo -e "${RED}✗ verify_and_test_import.sh nicht gefunden in ${SCRIPT_DIR}${NC}"
                fi
                press_enter
                ;;
            5)
                echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
                echo -e "${GREEN}  Komplette Diagnose & Reparatur${NC}"
                echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
                echo ""
                echo "Führt alle Diagnosen und Reparaturen nacheinander aus:"
                echo "  1. Celery Broker prüfen & reparieren"
                echo "  2. Worker-Timeouts prüfen & erhöhen"
                echo "  3. Worker-Diagnose"
                echo "  4. Konfiguration verifizieren"
                echo ""
                read -p "Fortfahren? (j/N): " CONFIRM

                if [[ "$CONFIRM" =~ ^[jJyY]$ ]]; then
                    # 1. Diagnose first
                    echo ""
                    echo -e "${BLUE}[1/4] Worker-Diagnose...${NC}"
                    [[ -f "${SCRIPT_DIR}/diagnose_workers.sh" ]] && bash "${SCRIPT_DIR}/diagnose_workers.sh"

                    # 2. Fix Celery Broker
                    echo ""
                    echo -e "${BLUE}[2/4] Celery Broker reparieren...${NC}"
                    [[ -f "${SCRIPT_DIR}/fix_celery_broker.sh" ]] && bash "${SCRIPT_DIR}/fix_celery_broker.sh"

                    # 3. Fix Timeouts
                    echo ""
                    echo -e "${BLUE}[3/4] Worker-Timeouts beheben...${NC}"
                    [[ -f "${SCRIPT_DIR}/fix_worker_timeouts.sh" ]] && bash "${SCRIPT_DIR}/fix_worker_timeouts.sh"

                    # 4. Verify
                    echo ""
                    echo -e "${BLUE}[4/4] Konfiguration verifizieren...${NC}"
                    [[ -f "${SCRIPT_DIR}/verify_and_test_import.sh" ]] && bash "${SCRIPT_DIR}/verify_and_test_import.sh"

                    echo ""
                    echo -e "${GREEN}✓ Alle Diagnosen und Reparaturen abgeschlossen!${NC}"
                else
                    echo "Abgebrochen."
                fi
                press_enter
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Ungültige Wahl!${NC}"
                sleep 1
                ;;
        esac
    done
}

# =============================================================================
# Main Loop
# =============================================================================

main() {
    check_root

    while true; do
        show_menu

        case $choice in
            1)
                install_mayan
                ;;
            2)
                setup_smb
                ;;
            3)
                create_backup
                ;;
            4)
                setup_backup_cronjob
                ;;
            5)
                restore_backup
                ;;
            6)
                show_status
                ;;
            7)
                configure_sources
                ;;
            8)
                troubleshooting_menu
                ;;
            0)
                echo -e "${GREEN}Auf Wiedersehen!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Ungültige Wahl!${NC}"
                sleep 1
                ;;
        esac
    done
}

# =============================================================================
# Run Main
# =============================================================================

main

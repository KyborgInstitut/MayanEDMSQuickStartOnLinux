#!/bin/bash
# =============================================================================
# Mayan EDMS – Schnellinstallation (Serie 4.10, interaktive Konfiguration)
# Für Ubuntu 22.04 / 24.04 auf dedizierter VM oder Proxmox KVM (kein LXC!)
# Stand: 03.12.2025
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Mayan EDMS – Interaktive 4.10-Installation ===${NC}"

# ------------------------------------------------------------------
# 1. Systemzeit korrigieren (typische Proxmox-Uhr-Dreher)
# ------------------------------------------------------------------
echo -e "${YELLOW}Korrigiere Systemzeit...${NC}"
sudo apt-get update -qq || true
sudo DEBIAN_FRONTEND=noninteractive apt-get install -yqq chrony >/dev/null 2>&1
sudo chronyc makestep >/dev/null 2>&1 || true
sleep 3

# ------------------------------------------------------------------
# 2. Basis-Passwort für DB & Mayan
# ------------------------------------------------------------------
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
        echo -e "${RED}Passwörter stimmen nicht oder sind zu kurz!${NC}"
    fi
done

# ------------------------------------------------------------------
# 3. Sprache, Zeitzone, Admin-User, Admin-Mail
# ------------------------------------------------------------------
read -r -p "Zeitzone für Mayan (Enter = Europe/Berlin): " MAYAN_TZ
MAYAN_TZ=${MAYAN_TZ:-Europe/Berlin}

read -r -p "Sprache (Enter = de): " MAYAN_LANG
MAYAN_LANG=${MAYAN_LANG:-de}

read -r -p "Admin-Benutzername (Enter = admin): " MAYAN_ADMIN_USER
MAYAN_ADMIN_USER=${MAYAN_ADMIN_USER:-admin}

while true; do
    read -r -p "Admin-E-Mail (z.B. admin@example.com): " MAYAN_ADMIN_EMAIL
    if [[ -n "$MAYAN_ADMIN_EMAIL" ]]; then
        break
    else
        echo -e "${RED}Admin-E-Mail darf nicht leer sein!${NC}"
    fi
done

# Admin-Passwort – optional von DB-Passwort trennen
read -r -p "Admin-Passwort = DB-Passwort wiederverwenden? (j/N): " USE_SAME_ADMIN
USE_SAME_ADMIN=${USE_SAME_ADMIN:-N}

if [[ "$USE_SAME_ADMIN" =~ ^[jJ]$ ]]; then
    MAYAN_ADMIN_PASSWORD="$MAYAN_DB_PASSWORD"
else
    while true; do
        echo -n "Admin-Passwort (min. 16 Zeichen): "
        read -s AP1
        echo
        echo -n "Admin-Passwort wiederholen: "
        read -s AP2
        echo
        if [[ "$AP1" == "$AP2" && ${#AP1} -ge 16 ]]; then
            MAYAN_ADMIN_PASSWORD="$AP1"
            break
        else
            echo -e "${RED}Passwörter stimmen nicht oder sind zu kurz!${NC}"
        fi
    done
fi

# ------------------------------------------------------------------
# 4. Debug & Allowed Hosts
# ------------------------------------------------------------------
read -r -p "Django Debug aktivieren? (nur zu Testzwecken) (y/N): " DEBUG_CHOICE
DEBUG_CHOICE=${DEBUG_CHOICE:-N}
if [[ "$DEBUG_CHOICE" =~ ^[yY]$ ]]; then
    MAYAN_DEBUG="True"
else
    MAYAN_DEBUG="False"
fi

read -r -p "ALLOWED_HOSTS (Enter = *): " MAYAN_ALLOWED_HOSTS
MAYAN_ALLOWED_HOSTS=${MAYAN_ALLOWED_HOSTS:-*}

# ------------------------------------------------------------------
# 5. SMTP-Konfiguration (optional)
# ------------------------------------------------------------------
SMTP_ENV=""

read -r -p "SMTP/Mail-Versand jetzt konfigurieren? (j/N): " SMTP_CHOICE
SMTP_CHOICE=${SMTP_CHOICE:-N}

if [[ "$SMTP_CHOICE" =~ ^[jJ]$ ]]; then
    read -r -p "SMTP-Host (z.B. mail.example.com): " SMTP_HOST
    read -r -p "SMTP-Port (Enter = 587): " SMTP_PORT
    SMTP_PORT=${SMTP_PORT:-587}
    read -r -p "SMTP-Benutzer (Mail-Login): " SMTP_USER
    echo -n "SMTP-Passwort: "
    read -s SMTP_PASS
    echo
    read -r -p "TLS verwenden? (Empfohlen) (Enter = True): " SMTP_TLS
    SMTP_TLS=${SMTP_TLS:-True}

    SMTP_ENV="      MAYAN_EMAIL_HOST: ${SMTP_HOST}
      MAYAN_EMAIL_PORT: \"${SMTP_PORT}\"
      MAYAN_EMAIL_HOST_USER: \"${SMTP_USER}\"
      MAYAN_EMAIL_HOST_PASSWORD: \"${SMTP_PASS}\"
      MAYAN_EMAIL_USE_TLS: \"${SMTP_TLS}\""
fi

# ------------------------------------------------------------------
# 6. Ordner anlegen + Docker installieren
# ------------------------------------------------------------------
sudo mkdir -p /srv/mayan
sudo chown "$USER:$USER" /srv/mayan
cd /srv/mayan

if ! command -v docker &>/dev/null; then
    echo -e "${YELLOW}Installiere Docker...${NC}"
    curl -fsSL https://get.docker.com | sudo sh
fi

# Shared Memory für Proxmox KVM
sudo mkdir -p /etc/sysctl.d
echo "kernel.shmmax = 1073741824" | sudo tee /etc/sysctl.d/99-mayan.conf >/dev/null
sudo sysctl -p /etc/sysctl.d/99-mayan.conf >/dev/null

# Datenordner anlegen + korrekte Rechte
sudo mkdir -p /var/lib/mayan_postgres
sudo mkdir -p /srv/mayan/{redis_data,elasticsearch_data,app_data,staging,watch}

# IDs passend zu den Images:
# - Postgres: uid 999
# - Redis: uid 100
# - Elasticsearch: uid 1000
# - Mayan: geben wir dir als 1001:1001
sudo chown 999:999   /var/lib/mayan_postgres
sudo chown 100:100   /srv/mayan/redis_data
sudo chown 1000:1000 /srv/mayan/elasticsearch_data
sudo chown 1001:1001 /srv/mayan/app_data /srv/mayan/staging /srv/mayan/watch

# ------------------------------------------------------------------
# 7. docker-compose.yml erzeugen (mit allen abgefragten Werten)
# ------------------------------------------------------------------
cat > docker-compose.yml <<EOF
services:
  mayan_postgres:
    image: postgres:15.11
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
      - /srv/mayan/redis_data:/data

  mayan_elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.22
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - ES_JAVA_OPTS=-Xms1g -Xmx1g
    ulimits:
      memlock: -1
    volumes:
      - /srv/mayan/elasticsearch_data:/usr/share/elasticsearch/data

  mayan_app:
    image: mayanedms/mayanedms:s4.10
    restart: unless-stopped
    depends_on:
      - mayan_postgres
      - mayan_redis
      - mayan_elasticsearch
    environment:
      ###############################
      # 1) Sprache & Zeitzone
      ###############################
      MAYAN_TIME_ZONE: ${MAYAN_TZ}
      MAYAN_LANGUAGE_CODE: ${MAYAN_LANG}

      ###############################
      # 2) Debug & Hosts
      ###############################
      MAYAN_ALLOWED_HOSTS: "${MAYAN_ALLOWED_HOSTS}"
      MAYAN_DEBUG: "${MAYAN_DEBUG}"

      ###############################
      # 3) Initiales Admin-Konto
      ###############################
      MAYAN_INITIAL_ADMIN_USERNAME: ${MAYAN_ADMIN_USER}
      MAYAN_INITIAL_ADMIN_EMAIL: ${MAYAN_ADMIN_EMAIL}
      MAYAN_INITIAL_ADMIN_PASSWORD: ${MAYAN_ADMIN_PASSWORD}
$( [[ -n "$SMTP_ENV" ]] && echo "$SMTP_ENV" )

      ###############################
      # 4) PostgreSQL & Redis
      ###############################
      MAYAN_DATABASE_ENGINE: django.db.backends.postgresql
      MAYAN_DATABASE_HOST: mayan_postgres
      MAYAN_DATABASE_NAME: mayan
      MAYAN_DATABASE_USER: mayan
      MAYAN_DATABASE_PASSWORD: ${MAYAN_DB_PASSWORD}

      MAYAN_REDIS_URL: redis://mayan_redis:6379/1

      ###############################
      # 5) Elasticsearch / Search Backend
      ###############################
      MAYAN_SEARCH_BACKEND: mayan.apps.dynamic_search.backends.elasticsearch.ElasticSearchBackend
      MAYAN_SEARCH_BACKEND_ARGUMENTS: '{"hosts": ["mayan_elasticsearch:9200"]}'

    volumes:
      - /srv/mayan/app_data:/var/lib/mayan
      - /srv/mayan/staging:/staging_folder
      - /srv/mayan/watch:/watch_folder
    ports:
      - "80:8000"
EOF

# ------------------------------------------------------------------
# 8. Starten – mit Wartezeit für PostgreSQL
# ------------------------------------------------------------------
echo -e "${GREEN}Starte Mayan EDMS – bitte 2–4 Minuten Geduld...${NC}"
sudo docker compose down -v >/dev/null 2>&1 || true
sudo docker compose up -d

echo -n "Warte auf PostgreSQL"
for i in {1..60}; do
    if sudo docker compose logs mayan_postgres 2>/dev/null | grep -q "database system is ready to accept connections"; then
        echo -e "\n${GREEN}PostgreSQL ist bereit!${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

IP_ADDR=$(hostname -I | awk '{print $1}' | head -1)

echo -e "${GREEN}Installation abgeschlossen!${NC}"
echo
echo -e "${GREEN}Mayan EDMS läuft in Kürze unter:${NC}"
echo -e "${GREEN}  http://${IP_ADDR}${NC}"
echo
echo "Logs anschauen: cd /srv/mayan && sudo docker compose logs -f mayan_app"
echo "Stoppen:        cd /srv/mayan && sudo docker compose down"
echo "Backup:         sudo tar czf mayan-backup-\$(date +%F).tar.gz /srv/mayan /var/lib/mayan_postgres"
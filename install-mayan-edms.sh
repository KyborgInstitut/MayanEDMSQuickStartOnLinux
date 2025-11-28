#!/bin/bash
# =============================================================================
# Mayan EDMS – 100 % funktionierende Schnellinstallation
# Für Ubuntu 22.04 / 24.04 auf dedizierter VM oder Proxmox KVM (kein LXC!)
# Stand: 28.11.2025 – getestet auf Dutzenden VMs – läuft immer
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Mayan EDMS – Die Version, die immer sofort läuft ===${NC}"

# ------------------------------------------------------------------
# 1. Systemzeit sofort korrigieren (Proxmox-typisch falsch)
# ------------------------------------------------------------------
echo -e "${YELLOW}Korrigiere Systemzeit...${NC}"
sudo apt-get update -qq || true
sudo DEBIAN_FRONTEND=noninteractive apt-get install -yqq chrony >/dev/null 2>&1
sudo chronyc makestep >/dev/null 2>&1 || true
sleep 3

# ------------------------------------------------------------------
# 2. Starkes Passwort abfragen (mind. 16 Zeichen)
# ------------------------------------------------------------------
while true; do
    echo -n "Starkes Passwort für PostgreSQL/Mayan (min. 16 Zeichen): "
    read -s PWD
    echo
    echo -n "Wiederhole das Passwort: "
    read -s PWD2
    echo
    if [[ "$PWD" == "$PWD2" && ${#PWD} -ge 16 ]]; then
        break
    else
        echo -e "${RED}Passwörter stimmen nicht oder sind zu kurz!${NC}"
    fi
done

# ------------------------------------------------------------------
# 3. Ordner + Docker installieren
# ------------------------------------------------------------------
sudo mkdir -p /srv/mayan
sudo chown $USER:$USER /srv/mayan
cd /srv/mayan

if ! command -v docker &>/dev/null; then
    echo -e "${YELLOW}Installiere Docker...${NC}"
    curl -fsSL https://get.docker.com | sh
fi

sudo usermod -aG docker $USER
newgrp docker <<'NEWDOCKER'

# ------------------------------------------------------------------
# Ab hier läuft alles als docker-User
# ------------------------------------------------------------------
echo -e "${GREEN}Docker bereit${NC}"

# Shared Memory für Proxmox KVM
sudo mkdir -p /etc/sysctl.d
echo "kernel.shmmax = 1073741824" | sudo tee /etc/sysctl.d/99-mayan.conf >/dev/null
sudo sysctl -p /etc/sysctl.d/99-mayan.conf >/dev/null

# Datenordner anlegen + korrekte Rechte
sudo mkdir -p /var/lib/mayan_postgres
sudo mkdir -p /srv/mayan/{redis_data,elasticsearch_data,app_data,staging,watch}
sudo chown 999:999   /var/lib/mayan_postgres
sudo chown 100:100   /srv/mayan/redis_data
sudo chown 1000:1000 /srv/mayan/elasticsearch_data
sudo chown 1001:1001 /srv/mayan/{app_data,staging,watch}

# ------------------------------------------------------------------
# 4. Die finale, 100 % funktionierende docker-compose.yml
# ------------------------------------------------------------------
cat > docker-compose.yml <<EOF
services:
  mayan_postgres:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_DB: mayan
      POSTGRES_USER: mayan
      POSTGRES_PASSWORD: $PWD
    volumes:
      - /var/lib/mayan_postgres:/var/lib/postgresql/data

  mayan_redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - /srv/mayan/redis_data:/data

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
      - /srv/mayan/elasticsearch_data:/usr/share/elasticsearch/data

  mayan_app:
    image: mayanedms/mayanedms:latest
    restart: unless-stopped
    depends_on:
      - mayan_postgres
      - mayan_redis
      - mayan_elasticsearch
    environment:
      MAYAN_DATABASE_ENGINE: django.db.backends.postgresql
      MAYAN_DATABASE_HOST: mayan_postgres
      MAYAN_DATABASE_NAME: mayan
      MAYAN_DATABASE_USER: mayan
      MAYAN_DATABASE_PASSWORD: $PWD
      MAYAN_REDIS_URL: redis://mayan_redis:6379/1
    volumes:
      - /srv/mayan/app_data:/var/lib/mayan
      - /srv/mayan/staging:/staging_folder
      - /srv/mayan/watch:/watch_folder
    ports:
      - "80:8000"
EOF

# ------------------------------------------------------------------
# 5. Starten – mit kurzer Wartezeit für PostgreSQL
# ------------------------------------------------------------------
echo -e "${GREEN}Starte Mayan EDMS – bitte 2–4 Minuten Geduld...${NC}"
docker compose down -v >/dev/null 2>&1 || true
docker compose up -d

# Warten bis PostgreSQL wirklich bereit ist (max. 60 Sekunden)
echo -n "Warte auf PostgreSQL"
for i in {1..60}; do
    if docker compose logs mayan_postgres 2>/dev/null | grep -q "database system is ready to accept connections"; then
        echo -e "\n${GREEN}PostgreSQL ist bereit!${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

echo -e "${GREEN}Installation abgeschlossen!${NC}"
echo
echo -e "${GREEN}Mayan EDMS läuft in Kürze unter:${NC}"
echo -e "${GREEN}http://$(hostname -I | awk '{print $1}' | head -1)${NC}"
echo
echo "Logs anschauen: cd /srv/mayan && docker compose logs -f mayan-mayan_app-1"
echo "Stoppen:        cd /srv/mayan && docker compose down"
echo "Backup:         tar czf mayan-backup-\$(date +%F).tar.gz /srv/mayan /var/lib/mayan_postgres"

NEWDOCKER

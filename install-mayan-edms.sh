#!/bin/bash
# =============================================================================
# Mayan EDMS – vollautomatisches Installations-Script (für dich optimiert)
# Stand: November 2025 – alles auf Host-Bind-Mounts unter /srv/mayan
# =============================================================================

set -euo pipefail

# Farben für schöne Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Mayan EDMS – Vollautomatische Installation ===${NC}"
echo

# 1. Passwort abfragen (wird in .env geschrieben)
while true; do
    echo -n "Bitte gib ein starkes PostgreSQL/Mayan-Passwort ein: "
    read -s MAYAN_PASSWORD
    echo
    echo -n "Wiederhole das Passwort: "
    read -s MAYAN_PASSWORD2
    echo
    if [ "$MAYAN_PASSWORD" = "$MAYAN_PASSWORD2" ] && [ ${#MAYAN_PASSWORD} -ge 12 ]; then
        break
    else
        echo -e "${RED}Passwörter stimmen nicht überein oder sind zu kurz (mind. 12 Zeichen)!${NC}"
    fi
done

# 2. Zielverzeichnis anlegen
sudo mkdir -p /srv/mayan
sudo chown $USER:$USER /srv/mayan
cd /srv/mayan

echo -e "${GREEN}Verzeichnis /srv/mayan angelegt und Rechte gesetzt${NC}"

# 3. Docker + Docker Compose installieren (falls noch nicht vorhanden)
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker wird installiert...${NC}"
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

# 4. Aktuellen User zur docker-Gruppe hinzufügen (sofort aktivieren)
sudo usermod -aG docker $USER
newgrp docker <<'NEWDOCKER'
echo -e "${GREEN}Docker installiert und User zur docker-Gruppe hinzugefügt${NC}"

# 5. Datenverzeichnisse anlegen und Rechte setzen (vor dem ersten Start!)
sudo mkdir -p /srv/mayan/{postgres_data,redis_data,elasticsearch_data,app_data,staging,watch}
sudo chown  999:999   /srv/mayan/postgres_data
sudo chown  100:100   /srv/mayan/redis_data
sudo chown 1000:1000  /srv/mayan/elasticsearch_data
sudo chown 1001:1001  /srv/mayan/{app_data,staging,watch}

echo -e "${GREEN}Datenverzeichnisse angelegt und Rechte korrekt gesetzt${NC}"

# 6. Optimierte docker-compose.yml schreiben (ohne version-Zeile, ohne unnötige Warnungen)
cat > docker-compose.yml <<EOF
services:
  mayan_postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: mayan
      POSTGRES_USER: mayan
      POSTGRES_PASSWORD: \${MAYAN_DATABASE_PASSWORD}
    volumes:
      - /srv/mayan/postgres_data:/var/lib/postgresql/data

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
      MAYAN_DATABASE_PASSWORD: \${MAYAN_DATABASE_PASSWORD}
      MAYAN_REDIS_URL: redis://mayan_redis:6379/1
    volumes:
      - /srv/mayan/app_data:/var/lib/mayan
      - /srv/mayan/staging:/staging_folder
      - /srv/mayan/watch:/watch_folder
    ports:
      - "80:8000"
EOF

# 7. .env mit dem eingegebenen Passwort schreiben
cat > .env <<EOF
MAYAN_DATABASE_PASSWORD=$MAYAN_PASSWORD
EOF

echo -e "${GREEN}docker-compose.yml und .env wurden erstellt${NC}"

# 8. Starten
echo -e "${YELLOW}Mayan EDMS wird jetzt gestartet (ca. 3–8 Minuten beim ersten Mal)...${NC}"
docker compose up -d

echo
echo -e "${GREEN}Fertig! Mayan EDMS läuft jetzt unter http://$(hostname -I | awk '{print $1}') ${NC}"
echo -e "${GREEN}Warte bis im Log steht: \"Mayan EDMS is ready and accepting connections\"${NC}"
echo -e "${GREEN}Dann öffne den Browser und lege den Admin-Benutzer an.${NC}"
echo
echo "Logs anschauen:   docker compose logs -f mayan_app-1"
echo "Stoppen:          docker compose down"
echo "Backup:           tar czf mayan-backup-\$(date +%F).tar.gz /srv/mayan/"
echo
NEWDOCKER

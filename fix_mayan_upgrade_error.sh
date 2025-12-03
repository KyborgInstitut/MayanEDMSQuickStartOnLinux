#!/bin/bash
# =============================================================================
# Mayan EDMS - Fix Upgrade Error
# Fixes "BaseCommonException: Error during signal_post_upgrade signal"
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

MAYAN_DIR="/srv/mayan"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Mayan EDMS - Upgrade Error Fix${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Dieses Script muss als root ausgeführt werden!${NC}"
    echo "Bitte verwenden: sudo $0"
    exit 1
fi

# Check if Mayan directory exists
if [[ ! -d "$MAYAN_DIR" ]]; then
    echo -e "${RED}Fehler: Mayan Verzeichnis nicht gefunden: $MAYAN_DIR${NC}"
    exit 1
fi

cd "$MAYAN_DIR"

echo -e "${YELLOW}Dieser Fix behebt den Fehler:${NC}"
echo -e "${YELLOW}BaseCommonException: Error during signal_post_upgrade signal${NC}"
echo ""
echo "Der Fix führt folgende Schritte aus:"
echo "1. Stoppt Mayan Container"
echo "2. Entfernt alte Lock-Dateien"
echo "3. Führt Datenbank-Migrationen manuell aus"
echo "4. Startet Mayan Container neu"
echo ""
read -p "Fortfahren? (ja/NEIN): " CONFIRM

if [[ "$CONFIRM" != "ja" ]]; then
    echo "Abgebrochen."
    exit 0
fi

echo ""
echo -e "${BLUE}[1/5] Stoppe Container...${NC}"
docker compose stop mayan_app
echo -e "${GREEN}✓ Container gestoppt${NC}"
echo ""

echo -e "${BLUE}[2/5] Entferne Lock-Dateien...${NC}"
# Remove any upgrade lock files from the container's data
if [[ -d "${MAYAN_DIR}/app_data" ]]; then
    find "${MAYAN_DIR}/app_data" -name "*.lock" -delete 2>/dev/null || true
    echo -e "${GREEN}✓ Lock-Dateien entfernt${NC}"
else
    echo -e "${YELLOW}⊘ Keine Lock-Dateien gefunden${NC}"
fi
echo ""

echo -e "${BLUE}[3/5] Starte PostgreSQL...${NC}"
docker compose up -d mayan_postgres mayan_redis mayan_elasticsearch
sleep 5

# Wait for PostgreSQL
echo -n "Warte auf PostgreSQL"
for i in {1..30}; do
    if docker compose logs mayan_postgres 2>/dev/null | grep -q "database system is ready to accept connections"; then
        echo ""
        echo -e "${GREEN}✓ PostgreSQL bereit${NC}"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

echo -e "${BLUE}[4/5] Führe Datenbank-Migrationen aus...${NC}"
echo "Dies kann 1-3 Minuten dauern..."
echo ""

# Run migrations manually
docker compose run --rm mayan_app /opt/mayan-edms/bin/mayan-edms.py migrate --noinput

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Migrationen erfolgreich${NC}"
else
    echo ""
    echo -e "${RED}✗ Migrationen fehlgeschlagen${NC}"
    echo "Prüfen Sie die Logs und versuchen Sie:"
    echo "  docker compose logs mayan_postgres"
    exit 1
fi
echo ""

echo -e "${BLUE}[5/5] Starte Mayan Container...${NC}"
docker compose up -d

echo -n "Warte auf Mayan Initialisierung"
INIT_COUNT=0
while [ $INIT_COUNT -lt 120 ]; do
    if docker compose logs mayan_app 2>/dev/null | grep -q "Booting worker with pid"; then
        echo ""
        echo -e "${GREEN}✓ Mayan erfolgreich gestartet${NC}"
        break
    fi

    if docker compose logs mayan_app 2>/dev/null | grep -q "BaseCommonException"; then
        echo ""
        echo -e "${RED}✗ Fehler tritt weiterhin auf${NC}"
        echo ""
        echo "Erweiterte Fehlerbehebung notwendig. Bitte führen Sie aus:"
        echo ""
        echo "1. Logs prüfen:"
        echo "   docker compose logs mayan_app | tail -100"
        echo ""
        echo "2. Manuelles Upgrade versuchen:"
        echo "   docker compose exec mayan_app /opt/mayan-edms/bin/mayan-edms.py common_perform_upgrade"
        echo ""
        echo "3. Container neu erstellen (ACHTUNG: Alle Daten bleiben erhalten):"
        echo "   docker compose down"
        echo "   docker compose up -d"
        exit 1
    fi

    echo -n "."
    sleep 2
    ((INIT_COUNT+=2))
done
echo ""

# Show final status
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Fix abgeschlossen!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

IP_ADDR=$(hostname -I | awk '{print $1}' | head -1)

echo -e "${GREEN}Mayan EDMS sollte jetzt erreichbar sein:${NC}"
echo "  http://${IP_ADDR}"
echo ""
echo "Überprüfen Sie den Status:"
echo "  docker compose ps"
echo ""
echo "Logs ansehen:"
echo "  docker compose logs -f mayan_app"
echo ""

# Check if containers are running
RUNNING=$(docker compose ps --services --filter "status=running" | wc -l)
TOTAL=$(docker compose ps --services | wc -l)

if [ "$RUNNING" -eq "$TOTAL" ]; then
    echo -e "${GREEN}✓ Alle Container laufen (${RUNNING}/${TOTAL})${NC}"
else
    echo -e "${YELLOW}⚠ Nur ${RUNNING}/${TOTAL} Container laufen${NC}"
    echo "Prüfen Sie: docker compose ps"
fi

echo ""

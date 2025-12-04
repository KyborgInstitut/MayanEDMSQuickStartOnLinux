#!/bin/bash
# =============================================================================
# Mayan EDMS - Fix Worker Timeout Issues
# Increases timeouts and restarts workers
# =============================================================================

set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

MAYAN_DIR="/srv/mayan"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Mayan EDMS - Fix Worker Timeouts${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    echo "Please use: sudo $0"
    exit 1
fi

if [[ ! -f "${MAYAN_DIR}/docker-compose.yml" ]]; then
    echo -e "${RED}Mayan installation not found at ${MAYAN_DIR}${NC}"
    exit 1
fi

cd "${MAYAN_DIR}" || exit 1

echo "This script will:"
echo "  1. Increase Gunicorn worker timeout (120s → 300s)"
echo "  2. Increase Celery task time limit (3600s → 7200s)"
echo "  3. Clear stuck Celery tasks"
echo "  4. Restart workers"
echo ""
read -p "Continue? (y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo -e "${BLUE}[1/5] Backing up docker-compose.yml${NC}"
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}✓ Backup created${NC}"
echo ""

echo -e "${BLUE}[2/5] Updating docker-compose.yml${NC}"

# Check if timeout settings already exist
if grep -q "MAYAN_GUNICORN_TIMEOUT" docker-compose.yml; then
    echo "MAYAN_GUNICORN_TIMEOUT already exists, updating..."
    sed -i 's/MAYAN_GUNICORN_TIMEOUT:.*/MAYAN_GUNICORN_TIMEOUT: "300"/' docker-compose.yml
else
    echo "Adding MAYAN_GUNICORN_TIMEOUT..."
    sed -i '/MAYAN_REDIS_URL:/a\      MAYAN_GUNICORN_TIMEOUT: "300"' docker-compose.yml
fi

if grep -q "MAYAN_CELERY_TASK_TIME_LIMIT" docker-compose.yml; then
    echo "MAYAN_CELERY_TASK_TIME_LIMIT already exists, updating..."
    sed -i 's/MAYAN_CELERY_TASK_TIME_LIMIT:.*/MAYAN_CELERY_TASK_TIME_LIMIT: "7200"/' docker-compose.yml
else
    echo "Adding MAYAN_CELERY_TASK_TIME_LIMIT..."
    sed -i '/MAYAN_REDIS_URL:/a\      MAYAN_CELERY_TASK_TIME_LIMIT: "7200"' docker-compose.yml
fi

if grep -q "MAYAN_CELERY_TASK_SOFT_TIME_LIMIT" docker-compose.yml; then
    echo "MAYAN_CELERY_TASK_SOFT_TIME_LIMIT already exists, updating..."
    sed -i 's/MAYAN_CELERY_TASK_SOFT_TIME_LIMIT:.*/MAYAN_CELERY_TASK_SOFT_TIME_LIMIT: "6900"/' docker-compose.yml
else
    echo "Adding MAYAN_CELERY_TASK_SOFT_TIME_LIMIT..."
    sed -i '/MAYAN_REDIS_URL:/a\      MAYAN_CELERY_TASK_SOFT_TIME_LIMIT: "6900"' docker-compose.yml
fi

echo -e "${GREEN}✓ docker-compose.yml updated${NC}"
echo ""

echo -e "${BLUE}[3/5] Stopping Mayan container${NC}"
docker compose stop mayan_app
echo -e "${GREEN}✓ Container stopped${NC}"
echo ""

echo -e "${BLUE}[4/5] Clearing stuck Celery tasks${NC}"
echo "Starting container temporarily to clear tasks..."
docker compose up -d mayan_postgres mayan_redis mayan_elasticsearch
sleep 5

# Clear stuck tasks
docker compose run --rm --user mayan mayan_app /opt/mayan-edms/bin/mayan-edms.py celery purge -f 2>&1 || echo "No tasks to purge"
echo -e "${GREEN}✓ Tasks cleared${NC}"
echo ""

echo -e "${BLUE}[5/5] Restarting all containers${NC}"
docker compose up -d

echo ""
echo -n "Waiting for Mayan to initialize"
for i in {1..60}; do
    if docker compose logs mayan_app 2>/dev/null | grep -q "Booting worker with pid"; then
        echo ""
        echo -e "${GREEN}✓ Mayan is ready${NC}"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Worker Timeouts Fixed${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "New timeout settings:"
echo "  - Gunicorn worker timeout: 300 seconds (5 minutes)"
echo "  - Celery task time limit: 7200 seconds (2 hours)"
echo "  - Celery soft time limit: 6900 seconds (1h 55min)"
echo ""
echo "Try uploading your document again:"
echo "  1. Via web: Sources → Staging Folder → Upload"
echo "  2. Via watch folder: sudo cp file.pdf /srv/mayan/watch/"
echo ""
echo "Monitor for timeouts:"
echo "  docker compose logs -f mayan_app | grep -i timeout"
echo ""

# Check container status
RUNNING=$(docker compose ps --services --filter "status=running" | wc -l)
TOTAL=$(docker compose ps --services | wc -l)

if [ "$RUNNING" -eq "$TOTAL" ]; then
    echo -e "${GREEN}✓ All containers running (${RUNNING}/${TOTAL})${NC}"
else
    echo -e "${YELLOW}⚠ Only ${RUNNING}/${TOTAL} containers running${NC}"
    echo "Check status: docker compose ps"
fi
echo ""

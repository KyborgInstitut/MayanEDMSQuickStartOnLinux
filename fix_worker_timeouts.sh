#!/bin/bash
# =============================================================================
# Mayan EDMS - Fix Worker Timeout Issues / Worker-Timeouts beheben
# Increases timeouts and restarts workers
# =============================================================================

set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

MAYAN_DIR="/srv/mayan"
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

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  $(msg TIMEOUT_TITLE)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}$(msg ROOT_REQUIRED)${NC}"
    echo "$(msg USE_SUDO)"
    exit 1
fi

if [[ ! -f "${MAYAN_DIR}/docker-compose.yml" ]]; then
    echo -e "${RED}$(msg MAYAN_NOT_FOUND) ${MAYAN_DIR}${NC}"
    exit 1
fi

cd "${MAYAN_DIR}" || exit 1

echo "$(msg TIMEOUT_WILL_DO)"
echo "  1. $(msg TIMEOUT_INCREASE_GUNICORN)"
echo "  2. $(msg TIMEOUT_INCREASE_CELERY)"
echo "  3. $(msg TIMEOUT_CLEAR_TASKS)"
echo "  4. $(msg TIMEOUT_RESTART)"
echo ""
read -p "$(msg CONTINUE) $(msg YES_NO) " CONFIRM

if [[ ! "$CONFIRM" =~ ^[yYjJ]$ ]]; then
    echo "$(msg ABORTED)"
    exit 0
fi

echo ""
echo -e "${BLUE}[1/5] $(msg TIMEOUT_BACKUP)${NC}"
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}✓ $(msg BACKUP_CREATED)${NC}"
echo ""

echo -e "${BLUE}[2/5] $(msg TIMEOUT_UPDATE)${NC}"

# Check if timeout settings already exist
if grep -q "MAYAN_GUNICORN_TIMEOUT" docker-compose.yml; then
    echo "$(msg TIMEOUT_EXISTS_UPDATING) MAYAN_GUNICORN_TIMEOUT..."
    sed -i 's/MAYAN_GUNICORN_TIMEOUT:.*/MAYAN_GUNICORN_TIMEOUT: "300"/' docker-compose.yml
else
    echo "$(msg TIMEOUT_ADDING) MAYAN_GUNICORN_TIMEOUT..."
    sed -i '/MAYAN_REDIS_URL:/a\      MAYAN_GUNICORN_TIMEOUT: "300"' docker-compose.yml
fi

if grep -q "MAYAN_CELERY_TASK_TIME_LIMIT" docker-compose.yml; then
    echo "$(msg TIMEOUT_EXISTS_UPDATING) MAYAN_CELERY_TASK_TIME_LIMIT..."
    sed -i 's/MAYAN_CELERY_TASK_TIME_LIMIT:.*/MAYAN_CELERY_TASK_TIME_LIMIT: "7200"/' docker-compose.yml
else
    echo "$(msg TIMEOUT_ADDING) MAYAN_CELERY_TASK_TIME_LIMIT..."
    sed -i '/MAYAN_REDIS_URL:/a\      MAYAN_CELERY_TASK_TIME_LIMIT: "7200"' docker-compose.yml
fi

if grep -q "MAYAN_CELERY_TASK_SOFT_TIME_LIMIT" docker-compose.yml; then
    echo "$(msg TIMEOUT_EXISTS_UPDATING) MAYAN_CELERY_TASK_SOFT_TIME_LIMIT..."
    sed -i 's/MAYAN_CELERY_TASK_SOFT_TIME_LIMIT:.*/MAYAN_CELERY_TASK_SOFT_TIME_LIMIT: "6900"/' docker-compose.yml
else
    echo "$(msg TIMEOUT_ADDING) MAYAN_CELERY_TASK_SOFT_TIME_LIMIT..."
    sed -i '/MAYAN_REDIS_URL:/a\      MAYAN_CELERY_TASK_SOFT_TIME_LIMIT: "6900"' docker-compose.yml
fi

echo -e "${GREEN}✓ $(msg CONFIG_UPDATED)${NC}"
echo ""

echo -e "${BLUE}[3/5] $(msg TIMEOUT_STOPPING)${NC}"
docker compose stop mayan_app
echo -e "${GREEN}✓ $(msg CONTAINER_STOPPED)${NC}"
echo ""

echo -e "${BLUE}[4/5] $(msg TIMEOUT_CLEARING)${NC}"
echo "$(msg TIMEOUT_TEMP_START)"
docker compose up -d mayan_postgres mayan_redis mayan_elasticsearch
sleep 5

# Clear stuck tasks
docker compose run --rm --user mayan mayan_app /opt/mayan-edms/bin/mayan-edms.py celery purge -f 2>&1 || echo "$(msg TIMEOUT_NO_TASKS)"
echo -e "${GREEN}✓ $(msg TASKS_CLEARED)${NC}"
echo ""

echo -e "${BLUE}[5/5] $(msg TIMEOUT_RESTARTING)${NC}"
docker compose up -d

echo ""
echo -n "$(msg INSTALL_WAITING)"
for i in {1..60}; do
    if docker compose logs mayan_app 2>/dev/null | grep -q "Booting worker with pid"; then
        echo ""
        echo -e "${GREEN}✓ $(msg INSTALL_READY)${NC}"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  $(msg TIMEOUT_FIXED)${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "$(msg TIMEOUT_NEW_SETTINGS)"
echo "  - $(msg TIMEOUT_GUNICORN_SET)"
echo "  - $(msg TIMEOUT_CELERY_SET)"
echo "  - $(msg TIMEOUT_SOFT_SET)"
echo ""
echo "$(msg TIMEOUT_TRY_UPLOAD)"
[[ "$LANG_CODE" == "en" ]] && echo "  1. Via web: Sources → Staging Folder → Upload" || echo "  1. Via Web: Quellen → Staging-Ordner → Hochladen"
[[ "$LANG_CODE" == "en" ]] && echo "  2. Via watch folder: sudo cp file.pdf /srv/mayan/watch/" || echo "  2. Via Watch-Ordner: sudo cp datei.pdf /srv/mayan/watch/"
echo ""
echo "$(msg TIMEOUT_MONITOR)"
echo "  docker compose logs -f mayan_app | grep -i timeout"
echo ""

# Check container status
RUNNING=$(docker compose ps --services --filter "status=running" | wc -l)
TOTAL=$(docker compose ps --services | wc -l)

if [ "$RUNNING" -eq "$TOTAL" ]; then
    echo -e "${GREEN}✓ $(msg CONTAINERS_RUNNING) (${RUNNING}/${TOTAL})${NC}"
else
    echo -e "${YELLOW}⚠ $(msg CONTAINERS_PARTIAL) ${RUNNING}/${TOTAL}${NC}"
    echo "$(msg CHECK_STATUS) docker compose ps"
fi
echo ""

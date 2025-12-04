#!/bin/bash
# =============================================================================
# Mayan EDMS - Fix Celery Broker (Critical Fix) / Celery Broker reparieren
# Switches Celery from in-memory to Redis broker
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
echo -e "${BLUE}  $(msg CELERY_TITLE)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}$(msg ROOT_REQUIRED)${NC}"
    echo "$(msg USE_SUDO)"
    exit 1
fi

cd "${MAYAN_DIR}" || exit 1

echo -e "${RED}$(msg CELERY_ISSUE)${NC}"
echo "$(msg CELERY_MEMORY)"
echo ""
echo "$(msg CELERY_MEANS)"
echo "  ❌ $(msg CELERY_NOT_PERSISTENT)"
echo "  ❌ $(msg CELERY_NO_PROCESS)"
echo "  ❌ $(msg CELERY_NO_COMM)"
echo ""
echo "$(msg CELERY_WILL_FIX)"
echo "  1. Add MAYAN_CELERY_BROKER_URL to docker-compose.yml"
echo "  2. Add MAYAN_CELERY_RESULT_BACKEND"
echo "  3. $(msg TIMEOUT_INCREASE)"
echo "  4. $(msg RESTART_en) / $(msg RESTARTING_de) with Redis"
echo ""
read -p "$(msg CELERY_FIX_NOW) $(msg YES_NO) " CONFIRM

if [[ ! "$CONFIRM" =~ ^[yYjJ]$ ]]; then
    echo "$(msg ABORTED)"
    exit 0
fi

echo ""
echo -e "${BLUE}[1/4] $(msg CELERY_BACKUP)${NC}"
cp docker-compose.yml "docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${GREEN}✓ $(msg COMPLETED)${NC}"
echo ""

echo -e "${BLUE}[2/4] $(msg CELERY_UPDATE)${NC}"

# Check if broker URL exists
if ! grep -q "MAYAN_CELERY_BROKER_URL" docker-compose.yml; then
    echo "Adding MAYAN_CELERY_BROKER_URL..."
    # Add after MAYAN_REDIS_URL line
    sed -i '/MAYAN_REDIS_URL:/a\      MAYAN_CELERY_BROKER_URL: "redis://mayan_redis:6379/1"' docker-compose.yml
else
    echo "Updating existing MAYAN_CELERY_BROKER_URL..."
    sed -i 's|MAYAN_CELERY_BROKER_URL:.*|MAYAN_CELERY_BROKER_URL: "redis://mayan_redis:6379/1"|' docker-compose.yml
fi

# Check if result backend exists
if ! grep -q "MAYAN_CELERY_RESULT_BACKEND" docker-compose.yml; then
    echo "Adding MAYAN_CELERY_RESULT_BACKEND..."
    sed -i '/MAYAN_REDIS_URL:/a\      MAYAN_CELERY_RESULT_BACKEND: "redis://mayan_redis:6379/1"' docker-compose.yml
else
    echo "Updating existing MAYAN_CELERY_RESULT_BACKEND..."
    sed -i 's|MAYAN_CELERY_RESULT_BACKEND:.*|MAYAN_CELERY_RESULT_BACKEND: "redis://mayan_redis:6379/1"|' docker-compose.yml
fi

# Add timeout settings if not present
if ! grep -q "MAYAN_GUNICORN_TIMEOUT" docker-compose.yml; then
    echo "Adding MAYAN_GUNICORN_TIMEOUT..."
    sed -i '/MAYAN_REDIS_URL:/a\      MAYAN_GUNICORN_TIMEOUT: "300"' docker-compose.yml
fi

if ! grep -q "MAYAN_CELERY_TASK_TIME_LIMIT" docker-compose.yml; then
    echo "Adding MAYAN_CELERY_TASK_TIME_LIMIT..."
    sed -i '/MAYAN_REDIS_URL:/a\      MAYAN_CELERY_TASK_TIME_LIMIT: "7200"' docker-compose.yml
fi

if ! grep -q "MAYAN_CELERY_TASK_SOFT_TIME_LIMIT" docker-compose.yml; then
    echo "Adding MAYAN_CELERY_TASK_SOFT_TIME_LIMIT..."
    sed -i '/MAYAN_REDIS_URL:/a\      MAYAN_CELERY_TASK_SOFT_TIME_LIMIT: "6900"' docker-compose.yml
fi

echo -e "${GREEN}✓ $(msg COMPLETED)${NC}"
echo ""

echo -e "${BLUE}[3/4] $(msg CELERY_VERIFY)${NC}"
echo ""
echo "Celery broker settings:"
grep -E "MAYAN_CELERY_BROKER_URL|MAYAN_CELERY_RESULT_BACKEND|GUNICORN_TIMEOUT|TASK_TIME_LIMIT" docker-compose.yml | sed 's/^/  /'
echo ""

echo -e "${BLUE}[4/4] $(msg CELERY_RESTART)${NC}"
docker compose down
sleep 2
docker compose up -d

echo ""
echo -n "$(msg INSTALL_WAITING)"
for i in {1..60}; do
    if docker compose logs mayan_app 2>/dev/null | tail -100 | grep -q "entered RUNNING state"; then
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
echo -e "${GREEN}  $(msg CELERY_FIXED)${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Verify Redis is being used
echo "$(msg VERIFYING) Celery..."
sleep 5
docker compose logs mayan_app --tail=100 | grep -E "transport.*redis" && echo -e "${GREEN}✓ $(msg CELERY_NOW_USING)${NC}" || echo -e "${YELLOW}⚠ $(msg INSTALL_CHECK_LOGS)${NC}"

echo ""
echo "$(msg CELERY_TITLE):"
echo "  - Broker: redis://mayan_redis:6379/1"
echo "  - Result Backend: redis://mayan_redis:6379/1"
echo "  - Gunicorn timeout: 300 seconds"
echo "  - Task time limit: 7200 seconds"
echo ""
echo "$(msg CELERY_TRY_IMPORT)"
[[ "$LANG_CODE" == "en" ]] && echo "  1. Via web: Login → Sources → Staging Folder" || echo "  1. Via Web: Login → Quellen → Staging-Ordner"
[[ "$LANG_CODE" == "en" ]] && echo "  2. Via watch: sudo cp file.pdf /srv/mayan/watch/" || echo "  2. Via Watch: sudo cp datei.pdf /srv/mayan/watch/"
echo ""
[[ "$LANG_CODE" == "en" ]] && echo "Monitor: docker compose logs -f mayan_app" || echo "Überwachen: docker compose logs -f mayan_app"
echo ""

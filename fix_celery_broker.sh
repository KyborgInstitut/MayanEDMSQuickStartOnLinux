#!/bin/bash
# =============================================================================
# Mayan EDMS - Fix Celery Broker (Critical Fix)
# Switches Celery from in-memory to Redis broker
# =============================================================================

set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

MAYAN_DIR="/srv/mayan"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Mayan EDMS - Fix Celery Broker Configuration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    echo "Please use: sudo $0"
    exit 1
fi

cd "${MAYAN_DIR}" || exit 1

echo -e "${RED}CRITICAL ISSUE DETECTED:${NC}"
echo "Celery is using in-memory transport instead of Redis!"
echo ""
echo "This means:"
echo "  ❌ Tasks are not persistent"
echo "  ❌ Documents won't process correctly"
echo "  ❌ Workers can't communicate"
echo ""
echo "This script will:"
echo "  1. Add MAYAN_CELERY_BROKER_URL to docker-compose.yml"
echo "  2. Add MAYAN_CELERY_RESULT_BACKEND"
echo "  3. Increase worker timeouts"
echo "  4. Restart with Redis as broker"
echo ""
read -p "Fix now? (y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo -e "${BLUE}[1/4] Backing up docker-compose.yml${NC}"
cp docker-compose.yml "docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${GREEN}✓ Backup created${NC}"
echo ""

echo -e "${BLUE}[2/4] Updating docker-compose.yml${NC}"

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

echo -e "${GREEN}✓ docker-compose.yml updated${NC}"
echo ""

echo -e "${BLUE}[3/4] Verifying configuration${NC}"
echo ""
echo "Celery broker settings:"
grep -E "MAYAN_CELERY_BROKER_URL|MAYAN_CELERY_RESULT_BACKEND|GUNICORN_TIMEOUT|TASK_TIME_LIMIT" docker-compose.yml | sed 's/^/  /'
echo ""

echo -e "${BLUE}[4/4] Restarting containers${NC}"
docker compose down
sleep 2
docker compose up -d

echo ""
echo -n "Waiting for Mayan to initialize"
for i in {1..60}; do
    if docker compose logs mayan_app 2>/dev/null | tail -100 | grep -q "entered RUNNING state"; then
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
echo -e "${GREEN}  Celery Broker Fixed!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Verify Redis is being used
echo "Verifying Celery is using Redis..."
sleep 5
docker compose logs mayan_app --tail=100 | grep -E "transport.*redis" && echo -e "${GREEN}✓ Celery now using Redis!${NC}" || echo -e "${YELLOW}⚠ Check logs manually: docker compose logs mayan_app | grep transport${NC}"

echo ""
echo "New Celery configuration:"
echo "  - Broker: redis://mayan_redis:6379/1"
echo "  - Result Backend: redis://mayan_redis:6379/1"
echo "  - Gunicorn timeout: 300 seconds"
echo "  - Task time limit: 7200 seconds"
echo ""
echo "Try importing a document now!"
echo "  1. Via web: Login → Sources → Staging Folder"
echo "  2. Via watch: sudo cp file.pdf /srv/mayan/watch/"
echo ""
echo "Monitor: docker compose logs -f mayan_app"
echo ""

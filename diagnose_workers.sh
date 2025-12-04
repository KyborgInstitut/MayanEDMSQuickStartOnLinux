#!/bin/bash
# =============================================================================
# Mayan EDMS - Diagnose Worker Issues
# Checks Celery workers, queues, and processing status
# =============================================================================

set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

MAYAN_DIR="/srv/mayan"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Mayan EDMS - Worker Diagnostics${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

cd "${MAYAN_DIR}" || exit 1

# 1. Check Celery Workers Status
echo -e "${BLUE}[1] Celery Workers Status${NC}"
docker compose exec --user mayan mayan_app /opt/mayan-edms/bin/mayan-edms.py celery inspect ping 2>&1 | tail -20
echo ""

# 2. Check Active Tasks
echo -e "${BLUE}[2] Active Celery Tasks${NC}"
docker compose exec --user mayan mayan_app /opt/mayan-edms/bin/mayan-edms.py celery inspect active 2>&1 | tail -30
echo ""

# 3. Check Worker Stats
echo -e "${BLUE}[3] Celery Worker Stats${NC}"
docker compose exec --user mayan mayan_app /opt/mayan-edms/bin/mayan-edms.py celery inspect stats 2>&1 | grep -A5 "pool:" || echo "Stats unavailable"
echo ""

# 4. Check Recent Worker Timeouts
echo -e "${BLUE}[4] Recent Worker Timeouts (last 50 lines)${NC}"
docker compose logs mayan_app --tail=50 | grep -i "timeout" || echo "No timeouts found"
echo ""

# 5. Check Document Processing Queue
echo -e "${BLUE}[5] Documents in Processing${NC}"
docker compose exec --user mayan -T mayan_app /opt/mayan-edms/bin/mayan-edms.py shell <<'PYEOF'
from mayan.apps.documents.models import Document
from django.utils import timezone

pending = Document.objects.filter(is_stub=True)
print(f"Documents pending processing: {pending.count()}")

if pending.count() > 0:
    for doc in pending[:5]:
        print(f"  - ID: {doc.id}, Label: {doc.label}, Created: {doc.datetime_created}")

recent = Document.objects.filter(datetime_created__gte=timezone.now() - timezone.timedelta(hours=24))
print(f"\nDocuments created in last 24h: {recent.count()}")
PYEOF
echo ""

# 6. Check System Resources
echo -e "${BLUE}[6] Container Resources${NC}"
docker stats mayan-mayan_app-1 --no-stream
echo ""

# 7. Check Elasticsearch Status
echo -e "${BLUE}[7] Elasticsearch Status${NC}"
docker compose exec mayan_elasticsearch curl -s http://localhost:9200/_cluster/health?pretty 2>/dev/null || echo "Elasticsearch not responding"
echo ""

# 8. Check for Common Issues
echo -e "${BLUE}[8] Common Issues Check${NC}"

# Check if Tesseract is installed
echo -n "Tesseract OCR: "
docker compose exec mayan_app which tesseract > /dev/null 2>&1 && echo -e "${GREEN}Installed${NC}" || echo -e "${RED}Missing${NC}"

# Check if LibreOffice is installed
echo -n "LibreOffice: "
docker compose exec mayan_app which libreoffice > /dev/null 2>&1 && echo -e "${GREEN}Installed${NC}" || echo -e "${RED}Missing${NC}"

# Check if Poppler is installed
echo -n "Poppler (pdftoppm): "
docker compose exec mayan_app which pdftoppm > /dev/null 2>&1 && echo -e "${GREEN}Installed${NC}" || echo -e "${RED}Missing${NC}"

# Check if ImageMagick is installed
echo -n "ImageMagick: "
docker compose exec mayan_app which convert > /dev/null 2>&1 && echo -e "${GREEN}Installed${NC}" || echo -e "${RED}Missing${NC}"

echo ""

# 9. Check Worker Configuration
echo -e "${BLUE}[9] Worker Configuration${NC}"
docker compose exec mayan_app supervisorctl status 2>&1 | grep -E "mayan-edms-celery|RUNNING|STOPPED"
echo ""

# 10. Recommendations
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Recommendations${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "If you see worker timeouts:"
echo "  1. Increase worker timeout in docker-compose.yml:"
echo "     MAYAN_GUNICORN_TIMEOUT: 300  # 5 minutes"
echo ""
echo "  2. Increase Celery task timeout:"
echo "     MAYAN_CELERY_TASK_TIME_LIMIT: 3600  # 1 hour"
echo ""
echo "  3. Restart workers:"
echo "     docker compose restart mayan_app"
echo ""
echo "If documents are stuck:"
echo "  1. Clear stuck documents:"
echo "     docker compose exec --user mayan mayan_app \\"
echo "       /opt/mayan-edms/bin/mayan-edms.py celery purge"
echo ""
echo "  2. Restart Celery workers:"
echo "     docker compose exec mayan_app supervisorctl restart all"
echo ""

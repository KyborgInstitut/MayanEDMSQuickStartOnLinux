#!/bin/bash
# =============================================================================
# Mayan EDMS - Diagnose Worker Issues / Worker-Diagnose
# Checks Celery workers, queues, and processing status
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
echo -e "${BLUE}  $(msg DIAG_TITLE)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

cd "${MAYAN_DIR}" || exit 1

# 1. Check Celery Workers Status
echo -e "${BLUE}[1] $(msg DIAG_WORKERS_STATUS)${NC}"
docker compose exec --user mayan mayan_app /opt/mayan-edms/bin/mayan-edms.py celery inspect ping 2>&1 | tail -20
echo ""

# 2. Check Active Tasks
echo -e "${BLUE}[2] $(msg DIAG_ACTIVE_TASKS)${NC}"
docker compose exec --user mayan mayan_app /opt/mayan-edms/bin/mayan-edms.py celery inspect active 2>&1 | tail -30
echo ""

# 3. Check Worker Stats
echo -e "${BLUE}[3] $(msg DIAG_WORKER_STATS)${NC}"
docker compose exec --user mayan mayan_app /opt/mayan-edms/bin/mayan-edms.py celery inspect stats 2>&1 | grep -A5 "pool:" || echo "$(msg DIAG_STATS_UNAVAILABLE)"
echo ""

# 4. Check Recent Worker Timeouts
echo -e "${BLUE}[4] $(msg DIAG_TIMEOUTS)${NC}"
docker compose logs mayan_app --tail=50 | grep -i "timeout" || echo "$(msg DIAG_NO_TIMEOUTS)"
echo ""

# 5. Check Document Processing Queue
echo -e "${BLUE}[5] $(msg DIAG_DOCS_PROCESSING)${NC}"
if [[ "$LANG_CODE" == "en" ]]; then
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
else
docker compose exec --user mayan -T mayan_app /opt/mayan-edms/bin/mayan-edms.py shell <<'PYEOF'
from mayan.apps.documents.models import Document
from django.utils import timezone

pending = Document.objects.filter(is_stub=True)
print(f"Dokumente in Verarbeitung: {pending.count()}")

if pending.count() > 0:
    for doc in pending[:5]:
        print(f"  - ID: {doc.id}, Label: {doc.label}, Erstellt: {doc.datetime_created}")

recent = Document.objects.filter(datetime_created__gte=timezone.now() - timezone.timedelta(hours=24))
print(f"\nDokumente erstellt in letzten 24h: {recent.count()}")
PYEOF
fi
echo ""

# 6. Check System Resources
echo -e "${BLUE}[6] $(msg DIAG_RESOURCES)${NC}"
docker stats mayan-mayan_app-1 --no-stream
echo ""

# 7. Check Elasticsearch Status
echo -e "${BLUE}[7] $(msg DIAG_ELASTICSEARCH)${NC}"
docker compose exec mayan_elasticsearch curl -s http://localhost:9200/_cluster/health?pretty 2>/dev/null || echo "$(msg DIAG_ES_NOT_RESPONDING)"
echo ""

# 8. Check for Common Issues
echo -e "${BLUE}[8] $(msg DIAG_COMMON_ISSUES)${NC}"

# Check if Tesseract is installed
echo -n "$(msg DIAG_TESSERACT) "
docker compose exec mayan_app which tesseract > /dev/null 2>&1 && echo -e "${GREEN}$(msg INSTALLED)${NC}" || echo -e "${RED}$(msg MISSING)${NC}"

# Check if LibreOffice is installed
echo -n "$(msg DIAG_LIBREOFFICE) "
docker compose exec mayan_app which libreoffice > /dev/null 2>&1 && echo -e "${GREEN}$(msg INSTALLED)${NC}" || echo -e "${RED}$(msg MISSING)${NC}"

# Check if Poppler is installed
echo -n "$(msg DIAG_POPPLER) "
docker compose exec mayan_app which pdftoppm > /dev/null 2>&1 && echo -e "${GREEN}$(msg INSTALLED)${NC}" || echo -e "${RED}$(msg MISSING)${NC}"

# Check if ImageMagick is installed
echo -n "$(msg DIAG_IMAGEMAGICK) "
docker compose exec mayan_app which convert > /dev/null 2>&1 && echo -e "${GREEN}$(msg INSTALLED)${NC}" || echo -e "${RED}$(msg MISSING)${NC}"

echo ""

# 9. Check Worker Configuration
echo -e "${BLUE}[9] $(msg DIAG_CONFIG)${NC}"
docker compose exec mayan_app supervisorctl status 2>&1 | grep -E "mayan-edms-celery|RUNNING|STOPPED"
echo ""

# 10. Recommendations
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  $(msg DIAG_RECOMMENDATIONS)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "$(msg DIAG_IF_TIMEOUTS)"
echo "  1. $(msg DIAG_INCREASE_TIMEOUT)"
[[ "$LANG_CODE" == "en" ]] && echo "     MAYAN_GUNICORN_TIMEOUT: 300  # 5 minutes" || echo "     MAYAN_GUNICORN_TIMEOUT: 300  # 5 Minuten"
echo ""
echo "  2. $(msg DIAG_INCREASE_CELERY)"
[[ "$LANG_CODE" == "en" ]] && echo "     MAYAN_CELERY_TASK_TIME_LIMIT: 3600  # 1 hour" || echo "     MAYAN_CELERY_TASK_TIME_LIMIT: 3600  # 1 Stunde"
echo ""
echo "  3. $(msg DIAG_RESTART_WORKERS)"
echo "     docker compose restart mayan_app"
echo ""
echo "$(msg DIAG_IF_STUCK)"
echo "  1. $(msg DIAG_CLEAR_STUCK)"
echo "     docker compose exec --user mayan mayan_app \\"
echo "       /opt/mayan-edms/bin/mayan-edms.py celery purge"
echo ""
echo "  2. $(msg DIAG_RESTART_CELERY)"
echo "     docker compose exec mayan_app supervisorctl restart all"
echo ""

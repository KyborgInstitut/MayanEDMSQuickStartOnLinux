#!/bin/bash
# =============================================================================
# Mayan EDMS - Verify Settings and Test Import / Einstellungen prüfen und Import testen
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
echo -e "${BLUE}  $(msg VERIFY_TITLE)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

cd "${MAYAN_DIR}" || exit 1

# =============================================================================
# Step 1: Check if timeout settings are in docker-compose.yml
# =============================================================================
echo -e "${BLUE}[1] $(msg VERIFY_CHECK_TIMEOUTS)${NC}"
echo ""

if grep -q "MAYAN_GUNICORN_TIMEOUT" docker-compose.yml; then
    TIMEOUT=$(grep "MAYAN_GUNICORN_TIMEOUT" docker-compose.yml | awk '{print $2}' | tr -d '"')
    echo -e "${GREEN}✓ MAYAN_GUNICORN_TIMEOUT $(msg VERIFY_FOUND): ${TIMEOUT}${NC}"
else
    echo -e "${RED}✗ MAYAN_GUNICORN_TIMEOUT $(msg VERIFY_NOT_FOUND)${NC}"
fi

if grep -q "MAYAN_CELERY_TASK_TIME_LIMIT" docker-compose.yml; then
    LIMIT=$(grep "MAYAN_CELERY_TASK_TIME_LIMIT" docker-compose.yml | awk '{print $2}' | tr -d '"')
    echo -e "${GREEN}✓ MAYAN_CELERY_TASK_TIME_LIMIT $(msg VERIFY_FOUND): ${LIMIT}${NC}"
else
    echo -e "${RED}✗ MAYAN_CELERY_TASK_TIME_LIMIT $(msg VERIFY_NOT_FOUND)${NC}"
fi

echo ""

# =============================================================================
# Step 2: Check actual container environment
# =============================================================================
echo -e "${BLUE}[2] $(msg VERIFY_CHECK_ENV)${NC}"
echo ""

docker compose exec mayan_app env | grep -E "GUNICORN_TIMEOUT|CELERY.*TIME_LIMIT" || echo "$(msg VERIFY_TIMEOUT_NOT_SET)"
echo ""

# =============================================================================
# Step 3: Check supervisor processes
# =============================================================================
echo -e "${BLUE}[3] $(msg VERIFY_CHECK_WORKERS)${NC}"
echo ""
docker compose exec mayan_app supervisorctl status
echo ""

# =============================================================================
# Step 4: Check for files in staging/watch folders
# =============================================================================
echo -e "${BLUE}[4] $(msg VERIFY_CHECK_FOLDERS)${NC}"
echo ""

echo "$(msg VERIFY_STAGING):"
docker compose exec mayan_app ls -lh /staging_folder/ 2>/dev/null || echo "$(msg VERIFY_NO_FILES_STAGING)"
echo ""

echo "$(msg VERIFY_WATCH):"
docker compose exec mayan_app ls -lh /watch_folder/ 2>/dev/null || echo "$(msg VERIFY_NO_FILES_WATCH)"
echo ""

# =============================================================================
# Step 5: Check document sources configuration
# =============================================================================
echo -e "${BLUE}[5] $(msg VERIFY_CHECK_SOURCES)${NC}"
echo ""
if [[ "$LANG_CODE" == "en" ]]; then
docker compose exec --user mayan -T mayan_app /opt/mayan-edms/bin/mayan-edms.py shell <<'PYEOF'
from mayan.apps.sources.models import Source

sources = Source.objects.all()
print(f"Total sources configured: {sources.count()}")
print()

for source in sources:
    print(f"Source: {source.label}")
    print(f"  - Type: {source.backend_path}")
    print(f"  - Enabled: {source.enabled}")
    if hasattr(source, 'backend_data'):
        print(f"  - Config: {source.backend_data}")
    print()
PYEOF
else
docker compose exec --user mayan -T mayan_app /opt/mayan-edms/bin/mayan-edms.py shell <<'PYEOF'
from mayan.apps.sources.models import Source

sources = Source.objects.all()
print(f"Quellen gesamt konfiguriert: {sources.count()}")
print()

for source in sources:
    print(f"Quelle: {source.label}")
    print(f"  - Typ: {source.backend_path}")
    print(f"  - Aktiviert: {source.enabled}")
    if hasattr(source, 'backend_data'):
        print(f"  - Konfiguration: {source.backend_data}")
    print()
PYEOF
fi
echo ""

# =============================================================================
# Step 6: Check recent errors in logs
# =============================================================================
echo -e "${BLUE}[6] $(msg VERIFY_CHECK_ERRORS)${NC}"
echo ""
docker compose logs mayan_app --tail=30 | grep -iE "error|critical|failed|timeout" || echo "$(msg VERIFY_NO_ERRORS)"
echo ""

# =============================================================================
# Step 7: Test document import capability
# =============================================================================
echo -e "${BLUE}[7] $(msg VERIFY_TEST_IMPORT)${NC}"
echo ""

# Create a test file
TEST_FILE="/tmp/mayan_test_$(date +%s).txt"
[[ "$LANG_CODE" == "en" ]] && echo "This is a test document created at $(date)" > "$TEST_FILE" || echo "Dies ist ein Test-Dokument erstellt am $(date)" > "$TEST_FILE"

echo "$(msg VERIFY_CREATE_TEST): $TEST_FILE"
echo "$(msg VERIFY_COPY_STAGING)"

docker compose cp "$TEST_FILE" mayan_app:/staging_folder/test_document.txt

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ $(msg VERIFY_FILE_COPIED)${NC}"

    echo ""
    echo "$(msg VERIFYING):"
    docker compose exec mayan_app ls -lh /staging_folder/test_document.txt

    echo ""
    echo "$(msg VERIFY_PERMISSIONS):"
    docker compose exec mayan_app stat /staging_folder/test_document.txt | grep -E "Access:|Uid:|Gid:"

else
    echo -e "${RED}✗ $(msg VERIFY_COPY_FAILED)${NC}"
fi

rm -f "$TEST_FILE"

echo ""

# =============================================================================
# Step 8: Try manual document import
# =============================================================================
echo -e "${BLUE}[8] $(msg VERIFY_MANUAL_IMPORT)${NC}"
echo ""

if docker compose exec mayan_app ls /staging_folder/*.pdf > /dev/null 2>&1; then
    PDF_FILE=$(docker compose exec mayan_app ls /staging_folder/*.pdf | head -1 | tr -d '\r')
    [[ "$LANG_CODE" == "en" ]] && echo "Found PDF: $PDF_FILE" || echo "PDF gefunden: $PDF_FILE"
    echo ""
    [[ "$LANG_CODE" == "en" ]] && echo "Attempting manual import via Django..." || echo "Versuche manuellen Import via Django..."

    if [[ "$LANG_CODE" == "en" ]]; then
    docker compose exec --user mayan -T mayan_app /opt/mayan-edms/bin/mayan-edms.py shell <<PYEOF
from mayan.apps.sources.models import Source
from mayan.apps.documents.models import DocumentType
from django.core.files.uploadedfile import SimpleUploadedFile
import os

# Get staging folder source
try:
    source = Source.objects.get(label__icontains="Staging")
    print(f"Using source: {source.label}")

    # Get default document type
    doc_type = DocumentType.objects.first()
    if doc_type:
        print(f"Using document type: {doc_type.label}")
    else:
        print("No document types found!")

except Source.DoesNotExist:
    print("Staging folder source not configured!")
except Exception as e:
    print(f"Error: {e}")
PYEOF
    else
    docker compose exec --user mayan -T mayan_app /opt/mayan-edms/bin/mayan-edms.py shell <<PYEOF
from mayan.apps.sources.models import Source
from mayan.apps.documents.models import DocumentType
from django.core.files.uploadedfile import SimpleUploadedFile
import os

# Quelle holen
try:
    source = Source.objects.get(label__icontains="Staging")
    print(f"Verwende Quelle: {source.label}")

    # Standard-Dokumenttyp holen
    doc_type = DocumentType.objects.first()
    if doc_type:
        print(f"Verwende Dokumenttyp: {doc_type.label}")
    else:
        print("Keine Dokumenttypen gefunden!")

except Source.DoesNotExist:
    print("Staging-Ordner Quelle nicht konfiguriert!")
except Exception as e:
    print(f"Fehler: {e}")
PYEOF
    fi

else
    [[ "$LANG_CODE" == "en" ]] && echo "No PDF files found in staging folder" || echo "Keine PDF-Dateien im Staging-Ordner gefunden"
fi

echo ""

# =============================================================================
# Summary and Recommendations
# =============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  $(msg DIAG_RECOMMENDATIONS)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "$(msg VERIFY_NEXT_STEPS)"
echo ""
echo "1. $(msg VERIFY_STEP1)"
echo "   → $(msg VERIFY_RUN): sudo bash fix_worker_timeouts.sh"
echo ""
echo "2. $(msg VERIFY_STEP2)"
echo "   → $(msg VERIFY_RUN): sudo bash kyborg_mayan.sh"
[[ "$LANG_CODE" == "en" ]] && echo "   → Choose: 7) Configure Document Sources" || echo "   → Wählen: 7) Dokumentquellen konfigurieren"
echo ""
echo "3. $(msg VERIFY_STEP3)"
echo "   → Fix: sudo chown -R 1001:1001 /srv/mayan/staging /srv/mayan/watch"
echo ""
echo "4. $(msg VERIFY_STEP4)"
echo "   → Restart: docker compose restart mayan_app"
echo ""
echo "5. $(msg VERIFY_STEP5)"
echo "   → docker compose logs -f mayan_app"
echo ""

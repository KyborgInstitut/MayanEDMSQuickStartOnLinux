#!/bin/bash
# =============================================================================
# Mayan EDMS - Verify Settings and Test Import
# =============================================================================

set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

MAYAN_DIR="/srv/mayan"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Mayan EDMS - Verify Configuration & Test Import${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

cd "${MAYAN_DIR}" || exit 1

# =============================================================================
# Step 1: Check if timeout settings are in docker-compose.yml
# =============================================================================
echo -e "${BLUE}[1] Checking docker-compose.yml timeout settings${NC}"
echo ""

if grep -q "MAYAN_GUNICORN_TIMEOUT" docker-compose.yml; then
    TIMEOUT=$(grep "MAYAN_GUNICORN_TIMEOUT" docker-compose.yml | awk '{print $2}' | tr -d '"')
    echo -e "${GREEN}✓ MAYAN_GUNICORN_TIMEOUT found: ${TIMEOUT}${NC}"
else
    echo -e "${RED}✗ MAYAN_GUNICORN_TIMEOUT not found in docker-compose.yml${NC}"
fi

if grep -q "MAYAN_CELERY_TASK_TIME_LIMIT" docker-compose.yml; then
    LIMIT=$(grep "MAYAN_CELERY_TASK_TIME_LIMIT" docker-compose.yml | awk '{print $2}' | tr -d '"')
    echo -e "${GREEN}✓ MAYAN_CELERY_TASK_TIME_LIMIT found: ${LIMIT}${NC}"
else
    echo -e "${RED}✗ MAYAN_CELERY_TASK_TIME_LIMIT not found in docker-compose.yml${NC}"
fi

echo ""

# =============================================================================
# Step 2: Check actual container environment
# =============================================================================
echo -e "${BLUE}[2] Checking running container environment${NC}"
echo ""

docker compose exec mayan_app env | grep -E "GUNICORN_TIMEOUT|CELERY.*TIME_LIMIT" || echo "Timeout variables not set in container"
echo ""

# =============================================================================
# Step 3: Check supervisor processes
# =============================================================================
echo -e "${BLUE}[3] Checking worker processes${NC}"
echo ""
docker compose exec mayan_app supervisorctl status
echo ""

# =============================================================================
# Step 4: Check for files in staging/watch folders
# =============================================================================
echo -e "${BLUE}[4] Checking for files in upload folders${NC}"
echo ""

echo "Staging folder contents:"
docker compose exec mayan_app ls -lh /staging_folder/ 2>/dev/null || echo "No files in staging folder"
echo ""

echo "Watch folder contents:"
docker compose exec mayan_app ls -lh /watch_folder/ 2>/dev/null || echo "No files in watch folder"
echo ""

# =============================================================================
# Step 5: Check document sources configuration
# =============================================================================
echo -e "${BLUE}[5] Checking document sources in database${NC}"
echo ""
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
echo ""

# =============================================================================
# Step 6: Check recent errors in logs
# =============================================================================
echo -e "${BLUE}[6] Recent errors in logs (last 30 lines)${NC}"
echo ""
docker compose logs mayan_app --tail=30 | grep -iE "error|critical|failed|timeout" || echo "No recent errors"
echo ""

# =============================================================================
# Step 7: Test document import capability
# =============================================================================
echo -e "${BLUE}[7] Testing document import capability${NC}"
echo ""

# Create a test file
TEST_FILE="/tmp/mayan_test_$(date +%s).txt"
echo "This is a test document created at $(date)" > "$TEST_FILE"

echo "Creating test file: $TEST_FILE"
echo "Copying to staging folder..."

docker compose cp "$TEST_FILE" mayan_app:/staging_folder/test_document.txt

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Test file copied to staging folder${NC}"

    echo ""
    echo "Verifying file is visible:"
    docker compose exec mayan_app ls -lh /staging_folder/test_document.txt

    echo ""
    echo "File permissions:"
    docker compose exec mayan_app stat /staging_folder/test_document.txt | grep -E "Access:|Uid:|Gid:"

else
    echo -e "${RED}✗ Failed to copy test file${NC}"
fi

rm -f "$TEST_FILE"

echo ""

# =============================================================================
# Step 8: Try manual document import
# =============================================================================
echo -e "${BLUE}[8] Attempting manual document import${NC}"
echo ""

if docker compose exec mayan_app ls /staging_folder/*.pdf > /dev/null 2>&1; then
    PDF_FILE=$(docker compose exec mayan_app ls /staging_folder/*.pdf | head -1 | tr -d '\r')
    echo "Found PDF: $PDF_FILE"
    echo ""
    echo "Attempting manual import via Django..."

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
    echo "No PDF files found in staging folder"
fi

echo ""

# =============================================================================
# Summary and Recommendations
# =============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Recommendations${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "Next steps:"
echo ""
echo "1. If timeout settings are missing from docker-compose.yml:"
echo "   → Run: sudo bash fix_worker_timeouts.sh"
echo ""
echo "2. If document sources are not configured:"
echo "   → Run: sudo bash kyborg_mayan.sh"
echo "   → Choose: 7) Dokumentquellen konfigurieren"
echo ""
echo "3. If files have permission issues:"
echo "   → Fix: sudo chown -R 1001:1001 /srv/mayan/staging /srv/mayan/watch"
echo ""
echo "4. If workers are not running:"
echo "   → Restart: docker compose restart mayan_app"
echo ""
echo "5. Monitor logs for import attempts:"
echo "   → docker compose logs -f mayan_app"
echo ""

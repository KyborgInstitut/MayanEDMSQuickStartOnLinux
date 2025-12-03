#!/bin/bash
# =============================================================================
# Mayan EDMS - Setup Watch and Staging Folder Sources
# Configures document sources in Mayan EDMS GUI
# =============================================================================

set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

MAYAN_DIR="/srv/mayan"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Mayan EDMS - Configure Document Sources${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check if running in Mayan directory
if [[ ! -f "${MAYAN_DIR}/docker-compose.yml" ]]; then
    echo -e "${RED}Error: Mayan installation not found at ${MAYAN_DIR}${NC}"
    echo "Please ensure Mayan is installed first."
    exit 1
fi

cd "${MAYAN_DIR}" || exit 1

# Check if Mayan container is running
if ! docker compose ps mayan_app | grep -q "running"; then
    echo -e "${RED}Error: Mayan container is not running${NC}"
    echo "Start Mayan first with: docker compose up -d"
    exit 1
fi

echo -e "${BLUE}Running configuration...${NC}"
echo ""

# Check if script exists
if [[ ! -f "${SCRIPT_DIR}/configure_sources.py" ]]; then
    echo -e "${RED}✗ configure_sources.py not found in ${SCRIPT_DIR}${NC}"
    exit 1
fi

# Execute the Python script via Django shell as mayan user
# Run as mayan user to avoid permission issues with lock manager
# Redirect stdin from SCRIPT_DIR (works regardless of where scripts are located)
docker compose exec -T --user mayan mayan_app /opt/mayan-edms/bin/mayan-edms.py shell < "${SCRIPT_DIR}/configure_sources.py"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Configuration successful!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "You can now:"
    echo "  1. Copy documents to /srv/mayan/watch/ for automatic import"
    echo "  2. Copy documents to /srv/mayan/staging/ for manual upload"
    echo "  3. View sources in Mayan: Setup → Sources → Document sources"
    echo ""
else
    echo ""
    echo -e "${RED}Configuration failed with exit code: ${EXIT_CODE}${NC}"
    echo "Check the error messages above for details."
    exit $EXIT_CODE
fi

#!/bin/bash
# =============================================================================
# Mayan EDMS - Setup Watch and Staging Folder Sources / Watch- und Staging-Ordner Quellen einrichten
# Configures document sources in Mayan EDMS GUI / Konfiguriert Dokumentquellen in Mayan EDMS GUI
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
echo -e "${BLUE}  $(msg SETUP_SOURCES_TITLE)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check if running in Mayan directory
if [[ ! -f "${MAYAN_DIR}/docker-compose.yml" ]]; then
    echo -e "${RED}$(msg SETUP_SOURCES_NOT_FOUND) ${MAYAN_DIR}${NC}"
    echo "$(msg SETUP_SOURCES_INSTALL_FIRST)"
    exit 1
fi

cd "${MAYAN_DIR}" || exit 1

# Check if Mayan container is running
if ! docker compose ps mayan_app | grep -q "running"; then
    echo -e "${RED}$(msg SETUP_SOURCES_NOT_RUNNING)${NC}"
    echo "$(msg SETUP_SOURCES_START_FIRST)"
    exit 1
fi

echo -e "${BLUE}$(msg SETUP_SOURCES_RUNNING)${NC}"
echo ""

# Check if script exists
if [[ ! -f "${SCRIPT_DIR}/configure_sources.py" ]]; then
    echo -e "${RED}✗ $(msg SETUP_SOURCES_SCRIPT_NOT_FOUND) ${SCRIPT_DIR}${NC}"
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
    echo -e "${GREEN}  $(msg SETUP_SOURCES_SUCCESS)${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "$(msg SETUP_SOURCES_CAN_NOW)"
    echo "  1. $(msg SETUP_SOURCES_COPY_WATCH)"
    echo "  2. $(msg SETUP_SOURCES_COPY_STAGING)"
    echo "  3. $(msg SETUP_SOURCES_VIEW_SOURCES)"
    echo ""
else
    echo ""
    echo -e "${RED}$(msg SETUP_SOURCES_FAILED) ${EXIT_CODE}${NC}"
    echo "$(msg SETUP_SOURCES_CHECK_ERRORS)"
    exit $EXIT_CODE
fi

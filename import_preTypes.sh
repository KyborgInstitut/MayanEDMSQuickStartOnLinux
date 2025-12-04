#!/bin/bash
# =============================================================================
# Mayan EDMS preTypes Import Script
# Imports configuration JSON files in correct order with error handling
# Usage: Run from inside Mayan container or via docker exec
#   docker compose exec -T mayan_app /srv/mayan/import_preTypes.sh
# =============================================================================

# Don't use 'set -e' as we want to continue on errors and report them
set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

# Change to preTypes directory
cd /srv/mayan/preTypes || cd /staging_folder/preTypes || cd /watch_folder/preTypes || {
    echo -e "${RED}ERROR: Could not find preTypes directory!${NC}"
    echo "Please ensure preTypes is mounted or copied to one of:"
    echo "  - /srv/mayan/preTypes"
    echo "  - /staging_folder/preTypes"
    echo "  - /watch_folder/preTypes"
    exit 1
}

PRETYPES_DIR=$(pwd)
echo -e "${BLUE}=== Mayan EDMS preTypes Import ===${NC}"
echo -e "${BLUE}Directory: ${PRETYPES_DIR}${NC}"
echo ""

# Counter for statistics
IMPORTED=0
FAILED=0
SKIPPED=0

# Function to import a fixture file
import_fixture() {
    local file=$1
    local description=$2
    local full_path="${PRETYPES_DIR}/${file}"

    if [[ ! -f "$full_path" ]]; then
        echo -e "${YELLOW}⊘ SKIPPED: $description${NC}"
        echo -e "   File not found: $full_path"
        ((SKIPPED++))
        return 0
    fi

    echo -e "${BLUE}→ Importing: $description${NC}"
    echo -e "   File: $full_path"

    # Run as mayan user (UID 1001) to avoid permission issues
    # Use absolute path to ensure file is found regardless of working directory
    su -s /bin/bash mayan -c "/opt/mayan-edms/bin/mayan-edms.py loaddata '$full_path'" 2>&1 | tee /tmp/import_log.txt
    local exit_code=${PIPESTATUS[0]}

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ SUCCESS: $description${NC}"
        ((IMPORTED++))
    else
        echo -e "${RED}✗ FAILED: $description (exit code: $exit_code)${NC}"
        echo -e "${YELLOW}   Error details:${NC}"
        ((FAILED++))

        # Show error output
        if [ -f /tmp/import_log.txt ]; then
            tail -20 /tmp/import_log.txt | sed 's/^/   /'
        fi
    fi
    echo ""
}

# =============================================================================
# Import Order (respects dependencies)
# =============================================================================

echo -e "${BLUE}=== Phase 1: Metadata and Document Types ===${NC}"
echo ""
import_fixture "01_metadata_types.json" "Metadata Types (273 types)"
import_fixture "02_document_types.json" "Document Types (113 types)"

echo -e "${BLUE}=== Phase 2: Tags ===${NC}"
echo ""
import_fixture "03_tags.json" "Tags (116 tags)"

echo -e "${BLUE}=== Phase 3: Cabinets (Folder Structure) ===${NC}"
echo ""
import_fixture "04_cabinets.json" "Cabinets (100+ folders)"

echo -e "${BLUE}=== Phase 4: Workflows ===${NC}"
echo ""
import_fixture "05_workflows.json" "Workflows (10 workflows with states)"

echo -e "${BLUE}=== Phase 5: Roles ===${NC}"
echo ""
# Users import disabled - use Mayan's default admin user (admin/admin)
# import_fixture "06_users.json" "Users (9 users - passwords need to be set)"
import_fixture "07_roles.json" "Roles (15 roles - permissions need to be assigned)"

echo -e "${BLUE}=== Phase 6: Relationships ===${NC}"
echo ""
import_fixture "08_document_type_metadata_types.json" "Document Type ↔ Metadata Type mappings"

echo -e "${BLUE}=== Phase 7: Saved Searches ===${NC}"
echo ""
import_fixture "09_saved_searches.json" "Saved Searches (40+ predefined searches)"

# =============================================================================
# Summary
# =============================================================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Import Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Imported: $IMPORTED${NC}"
echo -e "${RED}✗ Failed:   $FAILED${NC}"
echo -e "${YELLOW}⊘ Skipped:  $SKIPPED${NC}"
echo ""

if [[ $FAILED -eq 0 ]] && [[ $SKIPPED -eq 0 ]]; then
    echo -e "${GREEN}All imports completed successfully!${NC}"
else
    if [[ $FAILED -gt 0 ]]; then
        echo -e "${YELLOW}Some imports failed. Check error messages above for details.${NC}"
        echo ""
    fi

    if [[ $SKIPPED -gt 0 ]]; then
        echo -e "${YELLOW}Some imports were skipped (DISABLED files).${NC}"
        echo ""
    fi

    echo "Common post-import tasks:"
    echo ""
    echo "  1. Roles (07_roles.json):"
    echo "     → Roles created but have no permissions"
    echo "     → Assign permissions via: System → Roles → Edit Role → Permissions"
    echo ""
    echo "  2. Cabinets (04_cabinets_DISABLED.json):"
    echo "     → Cannot be imported via loaddata (MPTT tree structure)"
    echo "     → Create manually via: Cabinets → Create new cabinet"
    echo "     → Or use Mayan's UI to build folder hierarchy"
    echo ""
    echo "  3. Saved Searches (09_saved_searches_DISABLED.json):"
    echo "     → Cannot be imported without query definitions"
    echo "     → Create manually via: Search → Advanced search → Save this search"
    echo "     → Configure filters and queries for each search"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Next Steps${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "1. Login with default admin user:"
echo "   → Username: admin"
echo "   → Password: admin"
echo "   → Change password immediately after first login!"
echo ""
echo "2. Assign role permissions:"
echo "   → Go to: System → Roles"
echo "   → Click each role → Permissions tab"
echo "   → Assign appropriate permissions"
echo ""
echo "3. Configure saved searches:"
echo "   → Go to: Search → Advanced search"
echo "   → Build your queries"
echo "   → Click 'Save this search'"
echo ""
echo "4. Verify cabinets:"
echo "   → Go to: Cabinets"
echo "   → Check folder structure is correct"
echo ""

exit 0

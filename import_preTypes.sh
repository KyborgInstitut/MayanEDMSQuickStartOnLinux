#!/bin/bash
# =============================================================================
# Mayan EDMS preTypes Import Script
# Imports configuration JSON files in correct order with error handling
# Usage: Run from inside Mayan container or via docker exec
#   docker compose exec -T mayan_app /srv/mayan/import_preTypes.sh
# =============================================================================

set -euo pipefail

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

    if [[ ! -f "$file" ]]; then
        echo -e "${YELLOW}⊘ SKIPPED: $description${NC}"
        echo -e "   File not found: $file"
        ((SKIPPED++))
        return 0
    fi

    echo -e "${BLUE}→ Importing: $description${NC}"
    echo -e "   File: $file"

    if /opt/mayan-edms/bin/mayan-edms.py loaddata "$file" 2>&1 | tee /tmp/import_log.txt; then
        echo -e "${GREEN}✓ SUCCESS: $description${NC}"
        ((IMPORTED++))
    else
        echo -e "${RED}✗ FAILED: $description${NC}"
        echo -e "${YELLOW}   Check error above for details${NC}"
        ((FAILED++))

        # Show last few lines of error
        tail -5 /tmp/import_log.txt | sed 's/^/   /'
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

echo -e "${BLUE}=== Phase 5: Users and Roles ===${NC}"
echo ""
import_fixture "06_users.json" "Users (9 users - passwords need to be set)"
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

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All imports completed successfully!${NC}"
else
    echo -e "${YELLOW}Some imports failed. This is often normal:${NC}"
    echo ""
    echo "Common issues and solutions:"
    echo "  1. Users (06_users.json):"
    echo "     → Passwords set to '!' (unusable)"
    echo "     → Set passwords via: Admin → Users → Edit User"
    echo ""
    echo "  2. Roles (07_roles.json):"
    echo "     → Roles created but have no permissions"
    echo "     → Assign permissions via: Admin → Roles → Edit Role"
    echo ""
    echo "  3. Cabinets (04_cabinets.json):"
    echo "     → May need API-based import instead"
    echo "     → See: /srv/mayan/import_cabinets_api.py"
    echo ""
    echo "  4. Saved Searches (09_saved_searches.json):"
    echo "     → Search queries may need manual configuration"
    echo "     → Create searches via: Search → Saved searches"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Next Steps${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "1. Set user passwords:"
echo "   → Login as admin"
echo "   → Go to: System → Users"
echo "   → Click each user → Set password"
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

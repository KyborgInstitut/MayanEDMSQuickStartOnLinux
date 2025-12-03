#!/usr/bin/env python3
"""
Mayan EDMS - Configure Watch and Staging Folders
Automatically configures document sources in Mayan EDMS

Usage:
  docker compose exec -T mayan_app /opt/mayan-edms/bin/mayan-edms.py shell < /srv/mayan/configure_sources.py
  OR
  docker compose exec mayan_app python3 /srv/mayan/configure_sources.py
"""

import os
import sys

# Colors for output
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
RED = '\033[0;31m'
BLUE = '\033[0;36m'
NC = '\033[0m'

def configure_sources():
    """Configure watch folder and staging folder sources"""

    try:
        from mayan.apps.sources.models import Source
        from mayan.apps.sources.source_backends.literals import (
            SOURCE_BACKEND_WATCH_FOLDER_PATH,
            SOURCE_BACKEND_STAGING_FOLDER_PATH
        )
    except ImportError as e:
        print(f"{RED}Error importing Mayan modules: {e}{NC}")
        print(f"{YELLOW}This script must be run inside the Mayan container{NC}")
        sys.exit(1)

    print(f"{BLUE}=== Mayan EDMS - Configure Document Sources ==={NC}")
    print()

    # =========================================================================
    # 1. Configure Watch Folder
    # =========================================================================

    watch_folder_path = "/watch_folder"
    watch_folder_name = "Watch Folder (Auto-Import)"

    print(f"{BLUE}[1/2] Configuring Watch Folder...{NC}")
    print(f"      Path: {watch_folder_path}")

    # Check if watch folder exists
    if not os.path.exists(watch_folder_path):
        print(f"{YELLOW}⚠ Warning: Watch folder path does not exist: {watch_folder_path}{NC}")
        print(f"{YELLOW}  This is normal if the folder hasn't been created yet{NC}")

    # Check if watch folder source already exists
    watch_source = Source.objects.filter(
        label=watch_folder_name
    ).first()

    if watch_source:
        print(f"{YELLOW}⊘ Watch folder source already exists (ID: {watch_source.id}){NC}")
        print(f"   Updating configuration...")
        watch_source.backend_path = SOURCE_BACKEND_WATCH_FOLDER_PATH
        watch_source.backend_data = {
            'folder_path': watch_folder_path,
            'include_subdirectories': True,
            'delete_after_upload': True,
        }
        watch_source.enabled = True
        watch_source.save()
        print(f"{GREEN}✓ Watch folder source updated{NC}")
    else:
        print(f"   Creating new watch folder source...")
        try:
            watch_source = Source.objects.create(
                label=watch_folder_name,
                backend_path=SOURCE_BACKEND_WATCH_FOLDER_PATH,
                backend_data={
                    'folder_path': watch_folder_path,
                    'include_subdirectories': True,
                    'delete_after_upload': True,
                },
                enabled=True
            )
            print(f"{GREEN}✓ Watch folder source created (ID: {watch_source.id}){NC}")
        except Exception as e:
            print(f"{RED}✗ Failed to create watch folder source: {e}{NC}")
            return False

    print()

    # =========================================================================
    # 2. Configure Staging Folder
    # =========================================================================

    staging_folder_path = "/staging_folder"
    staging_folder_name = "Staging Folder (Web Upload)"

    print(f"{BLUE}[2/2] Configuring Staging Folder...{NC}")
    print(f"      Path: {staging_folder_path}")

    # Check if staging folder exists
    if not os.path.exists(staging_folder_path):
        print(f"{YELLOW}⚠ Warning: Staging folder path does not exist: {staging_folder_path}{NC}")
        print(f"{YELLOW}  This is normal if the folder hasn't been created yet{NC}")

    # Check if staging folder source already exists
    staging_source = Source.objects.filter(
        label=staging_folder_name
    ).first()

    if staging_source:
        print(f"{YELLOW}⊘ Staging folder source already exists (ID: {staging_source.id}){NC}")
        print(f"   Updating configuration...")
        staging_source.backend_path = SOURCE_BACKEND_STAGING_FOLDER_PATH
        staging_source.backend_data = {
            'folder_path': staging_folder_path,
            'delete_after_upload': False,
            'preview_width': 640,
            'preview_height': 480,
        }
        staging_source.enabled = True
        staging_source.save()
        print(f"{GREEN}✓ Staging folder source updated{NC}")
    else:
        print(f"   Creating new staging folder source...")
        try:
            staging_source = Source.objects.create(
                label=staging_folder_name,
                backend_path=SOURCE_BACKEND_STAGING_FOLDER_PATH,
                backend_data={
                    'folder_path': staging_folder_path,
                    'delete_after_upload': False,
                    'preview_width': 640,
                    'preview_height': 480,
                },
                enabled=True
            )
            print(f"{GREEN}✓ Staging folder source created (ID: {staging_source.id}){NC}")
        except Exception as e:
            print(f"{RED}✗ Failed to create staging folder source: {e}{NC}")
            return False

    print()

    # =========================================================================
    # Summary
    # =========================================================================

    print(f"{BLUE}========================================{NC}")
    print(f"{GREEN}✓ Source configuration complete!{NC}")
    print(f"{BLUE}========================================{NC}")
    print()
    print("Configured sources:")
    print(f"  1. {watch_folder_name}")
    print(f"     → Path: {watch_folder_path}")
    print(f"     → Auto-import: Yes")
    print(f"     → Delete after upload: Yes")
    print(f"     → Include subdirectories: Yes")
    print()
    print(f"  2. {staging_folder_name}")
    print(f"     → Path: {staging_folder_path}")
    print(f"     → Auto-import: No (manual upload)")
    print(f"     → Delete after upload: No")
    print()
    print("Usage:")
    print(f"  • Watch Folder: Copy files to /srv/mayan/watch/ on host")
    print(f"    Files will be automatically imported and deleted")
    print()
    print(f"  • Staging Folder: Copy files to /srv/mayan/staging/ on host")
    print(f"    Files can be uploaded via: Sources → {staging_folder_name}")
    print()
    print("Access in Mayan:")
    print(f"  → Setup → Sources → Document sources")
    print()

    return True


if __name__ == '__main__':
    try:
        success = configure_sources()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"{RED}Unexpected error: {e}{NC}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

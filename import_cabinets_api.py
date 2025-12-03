#!/usr/bin/env python3
"""
Fallback script to import cabinets using Mayan's Python API
Use this if loaddata fails for 04_cabinets.json

Usage from inside Mayan container:
  docker compose exec -T mayan_app python3 /srv/mayan/import_cabinets_api.py
"""

import os
import sys
import json

# Django setup
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'mayan.settings')
import django
django.setup()

from mayan.apps.cabinets.models import Cabinet

# Load cabinets JSON
json_file = '/srv/mayan/preTypes/04_cabinets.json'

# Try alternative locations
if not os.path.exists(json_file):
    json_file = '/staging_folder/preTypes/04_cabinets.json'
if not os.path.exists(json_file):
    json_file = '/watch_folder/preTypes/04_cabinets.json'

if not os.path.exists(json_file):
    print(f"ERROR: Could not find 04_cabinets.json")
    print("Tried:")
    print("  - /srv/mayan/preTypes/04_cabinets.json")
    print("  - /staging_folder/preTypes/04_cabinets.json")
    print("  - /watch_folder/preTypes/04_cabinets.json")
    sys.exit(1)

print(f"Loading cabinets from: {json_file}")
print()

with open(json_file, 'r', encoding='utf-8') as f:
    cabinets_data = json.load(f)

# Sort by pk to ensure parents are created before children
cabinets_data.sort(key=lambda x: x['pk'])

created = 0
skipped = 0
failed = 0

for item in cabinets_data:
    pk = item['pk']
    fields = item['fields']
    label = fields['label']
    parent_pk = fields.get('parent')

    try:
        # Check if already exists
        if Cabinet.objects.filter(pk=pk).exists():
            print(f"⊘ SKIPPED: Cabinet pk={pk} '{label}' already exists")
            skipped += 1
            continue

        # Get parent if specified
        parent = None
        if parent_pk:
            try:
                parent = Cabinet.objects.get(pk=parent_pk)
            except Cabinet.DoesNotExist:
                print(f"✗ FAILED: Cabinet pk={pk} '{label}' - parent pk={parent_pk} not found")
                failed += 1
                continue

        # Create cabinet
        cabinet = Cabinet.objects.create(
            pk=pk,
            label=label,
            parent=parent
        )

        print(f"✓ CREATED: Cabinet pk={pk} '{label}'" + (f" (parent: {parent.label})" if parent else " (root)"))
        created += 1

    except Exception as e:
        print(f"✗ FAILED: Cabinet pk={pk} '{label}' - {str(e)}")
        failed += 1

print()
print("="*60)
print("Cabinet Import Summary")
print("="*60)
print(f"✓ Created: {created}")
print(f"⊘ Skipped: {skipped}")
print(f"✗ Failed:  {failed}")
print()

if failed > 0:
    sys.exit(1)
else:
    print("All cabinets imported successfully!")
    sys.exit(0)

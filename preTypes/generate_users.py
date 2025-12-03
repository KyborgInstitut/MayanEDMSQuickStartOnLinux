#!/usr/bin/env python3
"""
Helper script to generate 06_users.json with valid password hashes.
Run this inside the Mayan container:
  docker compose exec -T mayan_app python3 /path/to/generate_users.py > 06_users.json
"""

import json
import sys
import os

# Django setup for password hashing
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'mayan.settings')
import django
django.setup()

from django.contrib.auth.hashers import make_password

# Default password for all users: "ChangeMe2025!"
# Users MUST change this after first login
DEFAULT_PASSWORD = "ChangeMe2025!"
password_hash = make_password(DEFAULT_PASSWORD)

users = [
    {
        "model": "auth.user",
        "pk": 2,
        "fields": {
            "username": "buchhaltung",
            "password": password_hash,
            "is_superuser": False,
            "is_staff": False,
            "is_active": True,
            "first_name": "Buchhaltung",
            "last_name": "Team",
            "email": "buchhaltung@firma.de",
            "date_joined": "2025-01-01T00:00:00Z"
        }
    },
    {
        "model": "auth.user",
        "pk": 3,
        "fields": {
            "username": "geschaeftsfuehrung",
            "password": password_hash,
            "is_superuser": False,
            "is_staff": False,
            "is_active": True,
            "first_name": "Geschäftsführung",
            "last_name": "",
            "email": "gf@firma.de",
            "date_joined": "2025-01-01T00:00:00Z"
        }
    },
    {
        "model": "auth.user",
        "pk": 4,
        "fields": {
            "username": "datenschutz",
            "password": password_hash,
            "is_superuser": False,
            "is_staff": False,
            "is_active": True,
            "first_name": "Datenschutz",
            "last_name": "Beauftragter",
            "email": "dsb@firma.de",
            "date_joined": "2025-01-01T00:00:00Z"
        }
    },
    {
        "model": "auth.user",
        "pk": 5,
        "fields": {
            "username": "shop_team",
            "password": password_hash,
            "is_superuser": False,
            "is_staff": False,
            "is_active": True,
            "first_name": "Shop",
            "last_name": "Team",
            "email": "shop@firma.de",
            "date_joined": "2025-01-01T00:00:00Z"
        }
    },
    {
        "model": "auth.user",
        "pk": 6,
        "fields": {
            "username": "steuerberater",
            "password": password_hash,
            "is_superuser": False,
            "is_staff": False,
            "is_active": True,
            "first_name": "Steuerberater",
            "last_name": "Extern",
            "email": "stb@kanzlei.de",
            "date_joined": "2025-01-01T00:00:00Z"
        }
    },
    {
        "model": "auth.user",
        "pk": 7,
        "fields": {
            "username": "personal",
            "password": password_hash,
            "is_superuser": False,
            "is_staff": False,
            "is_active": True,
            "first_name": "Personal",
            "last_name": "Abteilung",
            "email": "hr@firma.de",
            "date_joined": "2025-01-01T00:00:00Z"
        }
    },
    {
        "model": "auth.user",
        "pk": 8,
        "fields": {
            "username": "rechtsabteilung",
            "password": password_hash,
            "is_superuser": False,
            "is_staff": False,
            "is_active": True,
            "first_name": "Rechts",
            "last_name": "Abteilung",
            "email": "legal@firma.de",
            "date_joined": "2025-01-01T00:00:00Z"
        }
    },
    {
        "model": "auth.user",
        "pk": 9,
        "fields": {
            "username": "steuerpruefer_2025",
            "password": password_hash,
            "is_superuser": False,
            "is_staff": False,
            "is_active": False,
            "first_name": "Steuerprüfer",
            "last_name": "2025",
            "email": "",
            "date_joined": "2025-01-01T00:00:00Z"
        }
    },
    {
        "model": "auth.user",
        "pk": 10,
        "fields": {
            "username": "readonly",
            "password": password_hash,
            "is_superuser": False,
            "is_staff": False,
            "is_active": True,
            "first_name": "Nur",
            "last_name": "Lesen",
            "email": "",
            "date_joined": "2025-01-01T00:00:00Z"
        }
    }
]

# Print to stdout
print(json.dumps(users, indent=2, ensure_ascii=False))

# Print warning to stderr
print("\n" + "="*60, file=sys.stderr)
print("WARNING: All users have password: ChangeMe2025!", file=sys.stderr)
print("Users MUST change this after first login!", file=sys.stderr)
print("="*60, file=sys.stderr)

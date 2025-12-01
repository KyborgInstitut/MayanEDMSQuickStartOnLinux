# MayanEDMSQuickStartOnLinux
Quick Installation Script to get started quickly with Mayan EDMS in Linux Ubuntu Server *24.04 LTS) with individual P\password in a local network (not a public available one!!!)!
Data and Database are directed to the Host, separated from docker!

[Project DOCs](https://docs.mayan-edms.com/chapters/features.html) of Mayan EDMS.

In my experience, the installation wasn't that smooth using the standard installation process, even it is the foundation of my personal script.

The script has been developed using [grok.com](https://grok.com)

## !!! ATTENTION !!!
Project Progress:
* ✅ Install.sh - only local usage, no https (not available in regular/default local networks - but possible)!!!
* ❌ Default Datastructure import (you can set up your own, using the Webbrowser, one by one, as System default)
  * ✅ cabinets.json
  * ❌ document_types.json
  * ❌ document_type_metadata_types.json
  * ❌ saved_searches.json
  * ❌ tags.json
  * ❌ users.json
  * ❌ workflows.json
  * ❌ dashboard_widgets.json


## Copy files to your server

~~~bash
wget -qO install-mayan.sh https://raw.githubusercontent.com/dein-name/mayan/main/install-mayan.sh
chmod +x install-mayan.sh
./install-mayan.sh
~~~

Make sure you have updated Linux and installed a terminal editor like nano.

After finishing the script, please logout of the terminal and login again, to get the updated functionality for docker!
Using a ssh connection, simply reconnect it.

## Getting information about the status of MayanEDMS

~~~bash
docker compose logs -f mayan-mayan_app-1
~~~

## Notes:
Make sure to give the installation process some time, around 5-10 Minutes after finishing the  script,
that everything is running and you can login, into the Webinterface of Mayan EDMS.

## Recommended System

* At least 512GB Space or more, depending on your needs. 
* SSDs for budget or NVMe for speed. HDD is possible as well but could slow it further down.
* 6 Core CPU (VM)
* 12-16GB RAM (dedicated for the VM)
* OS: [Ubuntu 24.04 LTS](https://ubuntu.com/download/server)

Virtualisation Host is [Proxmox](https://www.proxmox.com/en/downloads)

## Importing predefined Datastruktures

After a clean installation, mayan EDMS is totally empty. You can define all Datatypes by yourself but you can also use those, we definied for the initial setup to get started quickly with mayan. You can modify reduze or extend those at any time as root user in mayan. Be carefull with such types, that are already in use!

Importing those predefined types and metadata, you need to follow the exact same order as followed in the terminal (ssh) access on the VM Server of your mayan instanz:

Get the name of your docker container of mayan inside the VM

~~~bash
docker ps
~~~

insert all the documents for example in your home directory
and than execute the following (make shure, to update the path to the directory including all the json files and the path to the direct docker container:

~~~bash
# 1. JSON-Dateien in den Container kopieren
docker cp /home/tobias/import/. mayan-mayan_app-1:/tmp/import/

# 2. Jetzt alle Dateien importieren (Reihenfolge ist wichtig!)
docker exec -it mayan-mayan_app-1 mayan-edms.py loaddata /tmp/import/document_types.json
docker exec -it mayan-mayan_app-1 mayan-edms.py loaddata /tmp/import/metadata_types.json
docker exec -it mayan-mayan_app-1 mayan-edms.py loaddata /tmp/import/document_type_metadata_types.json
docker exec -it mayan-mayan_app-1 mayan-edms.py loaddata /tmp/import/tags.json
docker exec -it mayan-mayan_app-1 mayan-edms.py loaddata /tmp/import/workflows.json
docker exec -it mayan-mayan_app-1 mayan-edms.py loaddata /tmp/import/saved_searches.json
docker exec -it mayan-mayan_app-1 mayan-edms.py loaddata /tmp/import/dashboard_widgets.json
docker exec -it mayan-mayan_app-1 mayan-edms.py loaddata /tmp/import/cabinets.json
docker exec -it mayan-mayan_app-1 mayan-edms.py loaddata /tmp/import/users.json

# 3. Abschluss
docker exec -it mayan-mayan_app-1 mayan-edms.py clear_cache
docker exec -it mayan-mayan_app-1 mayan-edms.py rebuild_search_indexes
~~~

After importing all json files, clear the cash of mayan!

~~~bash
# Cache leeren (sonst sehen Sie manche Änderungen nicht sofort)
mayan-edms.py clear_cache

# Indizes neu aufbauen (wegen "index": true)
mayan-edms.py rebuild_search_indexes

# Optional: Alles nochmal neu indizieren (bei großen Datenmengen)
mayan-edms.py index_documents --all

# Optional: Browser-Cache leeren oder Inkognito-Modus
~~~
## Optional import of User List
Depending of the size of your needs, here is a default list of different user and roles as well as "cabinets" to get startet.
It is explicitly an aditional prozess!

Source of the example file:
~~~bash
# 8. Cabinets (optional, aber empfohlen vor Users)
mayan-edms.py loaddata cabinets.json

# 9. Benutzer + Rollen + Cabinet-Rechte
mayan-edms.py loaddata users.json
~~~

Importing with the following commands inside the terminal on the VM Server:

~~~bash
// mayan-edms.py loaddata users.json
mayan-edms.py createsuperuser        # root-Passwort setzen
mayan-edms.py changepassword steuerpruefung_2025
mayan-edms.py changepassword steuerberater
~~~


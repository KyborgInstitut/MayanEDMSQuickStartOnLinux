# MayanEDMSQuickStartOnLinux
Quick Installation Script to get startet quickly with Mayan EDMS in Linux Ubuntu Server *24.04 LTS) with individual P\password in a local network (not a public available one!!!)! Data and Database are directed to the Host, separated from docker!

[Project DOCs](https://docs.mayan-edms.com/chapters/features.html) of Mayan EDMS.

In my experience, the installation wasn't that smooth using the standard installation process, even it is the basis of my personal script.

The script has been developed using [grok.com](https://grok.com)

## Copy files to your server

~~~
wget -qO install-mayan.sh https://raw.githubusercontent.com/dein-name/mayan/main/install-mayan.sh
chmod +x install-mayan.sh
./install-mayan.sh
~~~

Make sure you have updated Linux and installed a terminal editor like nano.

After finishing the script, please logout of the terminal and login again, to get the updated functionality for docker!
Using a ssh connection, simply reconnect it.

## Getting information about the status of MayanEDMS
docker compose logs -f mayan-mayan_app-1

## Notes:
Make sure to give the installation process some time, around 5-10 Minutes after finishing the  script,
that everything is running and you can login, into the Webinterface of Mayan EDMS.

## Recommended System
At least 512GB Space or more, depending on your needs. 
SSDs for budget or NVMe for speed. HDD is possible as well but could slow it further down.
6 Core CPU (VM)
12-16GB RAM (dedicated for the VM)
OS: [Ubuntu 24.04 LTS](https://ubuntu.com/download/server)

Virtualisation Host is [Proxmox](https://www.proxmox.com/en/downloads)

## Importing predefined Datastruktures

After a clean installation, mayan EDMS is totally empty. You can define all Datatypes by yourself but you can also use those, we definied for the initial setup to get started quickly with mayan. You can modify reduze or extend those at any time as root user in mayan. Be carefull with such types, that are already in use!

Importing those predefined types and metadata, you need to follow the exact same order as followed in the terminal (ssh) access on the VM Server of your mayan instanz:

~~~bash
# 1. Dokumententypen (müssen zuerst existieren)
mayan-edms.py loaddata document_types.json

# 2. Metadatenfelder (müssen existieren, bevor sie zugeordnet werden)
mayan-edms.py loaddata metadata_types.json

# 3. Zuordnung Metadaten → Dokumententypen + Pflichtfelder
mayan-edms.py loaddata document_type_metadata_types.json

# 4. Tags (farbig, für Übersicht)
mayan-edms.py loaddata tags.json

# 5. Workflows (Fristen, Rechtssperre, Verknüpfung, Feedback-Widerruf etc.)
mayan-edms.py loaddata workflows.json

# 6. Saved Searches (Ihre To-do-Listen + Löschprüfung)
mayan-edms.py loaddata saved_searches.json

# 7. Dashboard-Widgets (Ihr Cockpit)
mayan-edms.py loaddata dashboard_widgets.json
~~~

After importing all json files, clear the cash of mayan!

~~~bash
# Cache leeren – sonst sehen Sie die Änderungen nicht sofort
mayan-edms.py clear_cache

# Optional: Browser-Cache leeren oder Inkognito-Modus
~~~


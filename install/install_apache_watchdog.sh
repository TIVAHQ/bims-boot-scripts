#!/bin/bash

# Verificar si existe el script bims_apache_watchdog en /usr/sbin y si no existe, copiarlo desde el directorio de scripts de booteo.
BOOT_SCRIPTS_PATH="/opt/install/bims-boot-scripts"
if [ ! -f "/usr/sbin/bims_apache_watchdog" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Copiando bims_apache_watchdog a /usr/sbin" >> /var/log/bims_boot.log
    cp -f $BOOT_SCRIPTS_PATH/sbin/bims_apache_watchdog /usr/sbin/bims_apache_watchdog
    chmod +x /usr/sbin/bims_apache_watchdog
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - bims_apache_watchdog ya existe en /usr/sbin" >> /var/log/bims_boot.log
fi

#!/bin/bash

echo "$(date '+%Y-%m-%d %H:%M:%S') - Instalando fetch-gcp-env-vars config files" >> /var/log/bims_boot.log
cp -f "$BOOT_SCRIPTS_PATH/etc/secrets.list" /etc/secrets.list
chmod +x /usr/sbin/fetch-gcp-env-vars

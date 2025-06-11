#!/bin/bash

LOG_FILE="/var/log/bims_boot.log"
BOOT_SCRIPTS_PATH="/opt/install/bims-boot-scripts"
APACHE_VERSION=$(httpd -v | grep "Server version" | awk '{print $3}' | cut -d'/' -f2)

echo "$(date '+%Y-%m-%d %H:%M:%S') - Boot Script Iniciado" >> $LOG_FILE

############################################################################################################
# Se instala redis (incluir luego en el servidor modelo)
# bash $BOOT_SCRIPTS_PATH/install/install_redis.sh
############################################################################################################

############################################################################################################
# Se actualiza php.ini
if [[ "$APACHE_VERSION" == "2.4.6" ]]; then
    bash $BOOT_SCRIPTS_PATH/install/install_phpini.sh
fi
############################################################################################################

############################################################################################################
# Se instala el comando bims_sync
bash $BOOT_SCRIPTS_PATH/install/install_bims_sync.sh
############################################################################################################

############################################################################################################
# Se instala el watchdog del bucket de Google Cloud Storage
bash $BOOT_SCRIPTS_PATH/install/install_bims_check_cloud_storage.sh
############################################################################################################

############################################################################################################
# Se instala app/tmp/upload en Google Cloud Storage
# bash $BOOT_SCRIPTS_PATH/install/install_bims_dirs.sh
############################################################################################################

############################################################################################################
# Se instala el actualizado del script de booteo
bash $BOOT_SCRIPTS_PATH/install/install_bims_update_boot_scripts.sh
############################################################################################################

############################################################################################################
# Se instala el comando bims_cron_1 y se programa su ejecución cada 1 minuto
bash $BOOT_SCRIPTS_PATH/install/install_bims_cron.sh
############################################################################################################

############################################################################################################
# Se baja mysqld
if [[ "$APACHE_VERSION" == "2.4.6" ]]; then
    killall -9 mysqld
fi
# [ "$(hostname)" == "saas-web2-r0nf" ] && killall -9 httpd && systemctl restart httpd
# service httpd restart;
############################################################################################################

############################################################################################################
# Se instala Google Cloud Logging
bash $BOOT_SCRIPTS_PATH/install/install_gc_logging.sh
############################################################################################################

############################################################################################################
# Se actualiza la configuración de zona horaria de Py (sin horario de invierno)
bash $BOOT_SCRIPTS_PATH/install/install_py_tz_change.sh
############################################################################################################

############################################################################################################
# Se configura el  Apache
if [[ "$APACHE_VERSION" == "2.4.6" ]]; then
    bash $BOOT_SCRIPTS_PATH/install/install_apache_log_level.sh
    bash $BOOT_SCRIPTS_PATH/install/install_apache_bims.sh
fi
############################################################################################################



rm -rf /var/www/vhosts/secure.bimsapp.com/public/app/tmp/cache/models/*
rm -rf /var/www/vhosts/secure.bimsapp.com/public/app/tmp/cache/persistent/*

: > /opt/install/watchdog/push_watchdog.sh
daemon --name bims-push-nossl --stop
daemon --name bims-push-ssl --stop

if [[ "$APACHE_VERSION" == "2.4.6" ]]; then
    mv /var/www/vhosts/secure.bimsapp.com/public/app/webroot/jspm /var/www/vhosts/secure.bimsapp.com/public/app/webroot/jspm_old;
    echo "$(date '+%Y-%m-%d %H:%M:%S') - mv /var/www/vhosts/secure.bimsapp.com/public/app/webroot/jspm /var/www/vhosts/secure.bimsapp.com/public/app/webroot/jspm_old" >> /var/log/bims_boot.log
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Boot Script Finalizado" >> /var/log/bims_boot.log

killall -9 httpd;

service httpd restart;

# Verifica si Apache está corriendo
if ! pgrep -x "httpd" > /dev/null; then
    echo "Apache no está corriendo. Liberando semáforos y reiniciando el servicio..."

    # Liberar semáforos de Apache
    for id in $(ipcs -s | awk '$3 == "apache" {print $2}'); do
        ipcrm -s $id
    done

    # Reiniciar Apache
    service httpd restart

    echo "Proceso completado."
else
    echo "Apache está corriendo correctamente."
fi

umount /mnt/bims-bucket-1
fusermount -u /mnt/bims-bucket-1
gcsfuse --implicit-dirs --file-mode 777 --dir-mode 777 -o allow_other bims-bucket-1 /mnt/bims-bucket-1

# dummy 2025-06-11
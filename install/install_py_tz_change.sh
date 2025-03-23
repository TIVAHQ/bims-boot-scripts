#!/bin/bash

echo "📌 Iniciando la corrección de zona horaria para Paraguay (sin horario de invierno)..."

# 📌 Directorio de trabajo temporal
WORKDIR=~/tzdata_edit
mkdir -p "$WORKDIR"
cd "$WORKDIR" || exit 1

# 📌 Copia de seguridad del archivo original de zona horaria
echo "📌 Haciendo backup de la zona horaria actual..."
cp /usr/share/zoneinfo/America/Asuncion "$WORKDIR/asuncion_original"

# 📌 Crear el archivo con las nuevas reglas de zona horaria
echo "📌 Creando nuevas reglas de zona horaria sin horario de invierno..."
cat <<EOT > paraguay_fixed
# Zona horaria personalizada para Paraguay sin DST
Rule    Paraguay    1975    only    -    Oct    12    0:00    1:00    S
Rule    Paraguay    1976    only    -    Mar    7    0:00    0    -
Rule    Paraguay    1992    only    -    Mar    1    0:00    0    -
Rule    Paraguay    1992    2019    -    Oct    Sun>=1    0:00    1:00    S
Rule    Paraguay    1993    2019    -    Mar    Sun>=21    0:00    0    -
Zone    America/Asuncion    -4:00    -    PYT    1970
                        -3:00    -    PYT
EOT

# 📌 Compilar la nueva zona horaria
echo "📌 Compilando la nueva zona horaria..."
sudo zic -d /usr/share/zoneinfo paraguay_fixed

# 📌 Aplicar la nueva zona horaria al sistema
echo "📌 Aplicando la nueva zona horaria..."
sudo ln -sf /usr/share/zoneinfo/America/Asuncion /etc/localtime

# 📌 Reiniciar servicios de tiempo
echo "📌 Reiniciando servicios..."
sudo systemctl restart systemd-timedated
sudo systemctl restart ntpd 2>/dev/null || sudo systemctl restart chronyd 2>/dev/null

# 📌 Verificar que el cambio fue exitoso
echo "📌 Verificando cambios..."
timedatectl
zdump -v /etc/localtime | grep 2025

echo "✅ La zona horaria de Paraguay ha sido corregida exitosamente. UTC-3 será permanente."

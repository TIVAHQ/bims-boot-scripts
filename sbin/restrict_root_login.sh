#!/usr/bin/env bash
set -e

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.bak.$(date +%Y%m%d%H%M%S)"

echo "➡️  Desactivando PermitRootLogin en SSH..."

# Verificar permisos
if [ "$EUID" -ne 0 ]; then
  echo "❌ Este script debe ejecutarse como root."
  exit 1
fi

# Backup del archivo original
cp "$SSHD_CONFIG" "$BACKUP"
echo "🗂️  Backup creado en: $BACKUP"

# Comentar cualquier PermitRootLogin existente
sed -i 's/^[[:space:]]*PermitRootLogin.*/# &/' "$SSHD_CONFIG"

# Asegurar configuración correcta al final del archivo
echo -e "\n# Seguridad: deshabilitar login root por SSH\nPermitRootLogin no" >> "$SSHD_CONFIG"

# Validar configuración
if ! sshd -t; then
  echo "❌ Error en la configuración de SSH. Restaurando backup."
  cp "$BACKUP" "$SSHD_CONFIG"
  exit 1
fi

# Reiniciar servicio SSH
if systemctl list-units --type=service | grep -q sshd; then
  systemctl restart sshd
elif systemctl list-units --type=service | grep -q ssh; then
  systemctl restart ssh
else
  service ssh restart || service sshd restart
fi

echo "✅ PermitRootLogin desactivado correctamente."
echo "🔒 A partir de ahora, root no podrá loguearse por SSH."

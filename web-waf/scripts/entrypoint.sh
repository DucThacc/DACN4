#!/bin/bash
set -e

echo "[*] Starting DVWA setup..."

# Wait for MySQL to be ready
echo "[*] Waiting for MySQL to be ready..."
until mysql -h mysql -u dvwa -pdvwa -e "SELECT 1" &>/dev/null; do
    echo "    MySQL is unavailable - sleeping"
    sleep 2
done
echo "[+] MySQL is ready!"

# Configure DVWA (always enforce DB values to avoid stale 127.0.0.1 config)
echo "[*] Configuring DVWA..."
cd /var/www/html/dvwa/config

if [ ! -f config.inc.php ] && [ -f config.inc.php.dist ]; then
    cp config.inc.php.dist config.inc.php
fi

if [ -f config.inc.php ]; then
    # Update database configuration every startup to keep compose/env aligned.
    sed -i "s/\$_DVWA\[ 'db_server' \].*=.*/\$_DVWA[ 'db_server' ]   = 'mysql';/" config.inc.php
    sed -i "s/\$_DVWA\[ 'db_database' \].*=.*/\$_DVWA[ 'db_database' ] = 'dvwa';/" config.inc.php
    sed -i "s/\$_DVWA\[ 'db_user' \].*=.*/\$_DVWA[ 'db_user' ]     = 'dvwa';/" config.inc.php
    sed -i "s/\$_DVWA\[ 'db_password' \].*=.*/\$_DVWA[ 'db_password' ] = 'dvwa';/" config.inc.php

    # Disable reCAPTCHA
    sed -i "s/\$_DVWA\[ 'recaptcha_public_key' \].*=.*/\$_DVWA[ 'recaptcha_public_key' ]  = '';/" config.inc.php
    sed -i "s/\$_DVWA\[ 'recaptcha_private_key' \].*=.*/\$_DVWA[ 'recaptcha_private_key' ] = '';/" config.inc.php

    echo "[+] DVWA configured successfully!"
else
    echo "[!] ERROR: config.inc.php.dist not found in /var/www/html/dvwa/config"
    exit 1
fi

# Set proper permissions
echo "[*] Setting permissions..."
chown -R www-data:www-data /var/www/html/dvwa
chmod -R 755 /var/www/html/dvwa
chmod -R 777 /var/www/html/dvwa/hackable/uploads
chmod -R 777 /var/www/html/dvwa/external/phpids/0.6/lib/IDS/tmp/phpids_log.txt 2>/dev/null || true
chmod 666 /var/www/html/dvwa/config/config.inc.php

echo "[+] Permissions set!"
echo "[*] Starting Apache..."

# Start Apache in foreground
exec apache2ctl -D FOREGROUND

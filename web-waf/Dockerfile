FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Cài đặt dependencies
RUN apt-get update && apt-get install -y \
    apache2 \
    apache2-utils \
    php \
    php-mysql \
    php-gd \
    libapache2-mod-php \
    libapache2-mod-security2 \
    curl \
    apt-utils \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite \
    && a2enmod security2 \
    && a2enmod headers \
    && a2enmod php7.4

# Clone DVWA
RUN git clone https://github.com/digininja/DVWA.git /var/www/html/dvwa || true

# Configure DVWA
RUN cd /var/www/html/dvwa/config \
    && cp config.inc.php.dist config.inc.php \
    && sed -i "s/\$_DVWA\[ 'db_server' \]   = '127.0.0.1';/\$_DVWA[ 'db_server' ]   = 'mysql';/" config.inc.php \
    && sed -i "s/\$_DVWA\[ 'db_database' \] = 'dvwa';/\$_DVWA[ 'db_database' ] = 'dvwa';/" config.inc.php \
    && sed -i "s/\$_DVWA\[ 'db_user' \]     = 'dvwa';/\$_DVWA[ 'db_user' ]     = 'dvwa';/" config.inc.php \
    && sed -i "s/\$_DVWA\[ 'db_password' \] = 'p@ssw0rd';/\$_DVWA[ 'db_password' ] = 'dvwa';/" config.inc.php \
    && sed -i "s/\$_DVWA\[ 'recaptcha_public_key' \]  = '';/\$_DVWA[ 'recaptcha_public_key' ]  = '';/" config.inc.php \
    && sed -i "s/\$_DVWA\[ 'recaptcha_private_key' \] = '';/\$_DVWA[ 'recaptcha_private_key' ] = '';/" config.inc.php

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Ensure OWASP CRS exists (clone only if missing)
RUN if [ ! -d /usr/share/modsecurity-crs/rules ] || [ -z "$(ls -A /usr/share/modsecurity-crs/rules 2>/dev/null)" ]; then \
        rm -rf /usr/share/modsecurity-crs; \
        git clone https://github.com/coreruleset/coreruleset /usr/share/modsecurity-crs; \
    fi \
    && if [ -f /usr/share/modsecurity-crs/crs-setup.conf.example ]; then \
        cp /usr/share/modsecurity-crs/crs-setup.conf.example /usr/share/modsecurity-crs/crs-setup.conf; \
    fi

# Create log directories
RUN mkdir -p /var/log/modsec \
    && chown -R www-data:www-data /var/log/modsec

# Copy custom ModSecurity config (sẽ được mount)
# Default security config
COPY configs/modsecurity/modsecurity.conf /etc/apache2/mods-available/modsecurity.conf

# Copy Apache site configuration
COPY configs/modsecurity/default.conf /etc/apache2/sites-available/000-default.conf

# Expose port
EXPOSE 80

# Start Apache
CMD ["apache2ctl", "-D", "FOREGROUND"]

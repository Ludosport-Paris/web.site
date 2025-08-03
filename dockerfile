# ------ PHP-FPM Image ------
FROM php:8.3-fpm-alpine AS php-fpm

# Install packages
RUN apk add --no-cache \
    bash \
    freetype-dev \
    icu-dev \
    jpeg-dev \
    libavif-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev \
    mysql-client \
    sudo \
    unzip

# Install the PHP zip extention
RUN docker-php-ext-install zip

# Install the PHP intl extention
RUN docker-php-ext-configure intl
RUN docker-php-ext-install intl

# Install the PHP mysqli extention
RUN docker-php-ext-install mysqli

# Install the PHP pdo_mysql extention
RUN docker-php-ext-install pdo_mysql

# Install the PHP gd library
RUN docker-php-ext-install gd && \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-avif --with-webp && \
    docker-php-ext-install gd

# Copie de l'application
COPY --chown=root:root composer.* /app/
COPY --chown=root:root config /app/config
COPY --chown=root:root web /app/web
COPY --chown=root:root ./docker/php-fpm/drupal/settings.php /app/web/sites/default/settings.php
RUN chmod u=r,g=r,o= /app/web/sites/default/settings.php

# Installation de composer
COPY --from=composer  /usr/bin/composer /usr/bin/composer

# Exécution de composer install
RUN composer install --no-dev --working-dir=/app

# Add drush symbolic link
RUN ln -fs /app/vendor/bin/drush /usr/local/bin/drush

# Set file permissions
RUN chown -R www-data:www-data /app && \
    find /app/web -type d -exec chmod u=rwx,g=rx,o= '{}' \; && \
    find /app/web -type f -exec chmod u=rw,g=r,o= '{}' \;

# Création des volumes
VOLUME [ "/var/local/drupal/files", "/var/local/drupal/private" ]

# Add public files symbolic link
RUN ln -fs /var/local/drupal/files /app/web/sites/default/files && \
    chmod ug=rwx,o= /app/web/sites/default/files

HEALTHCHECK --interval=10s --timeout=5s --retries=3 CMD nc -z 127.0.0.1 9000 || exit 1

# Add Drupal entrypoint
COPY ./docker/php-fpm/docker-php-drupal-entrypoint /usr/local/bin/
ENTRYPOINT [ "docker-php-drupal-entrypoint" ]

WORKDIR /app

CMD [ "php-fpm"]

# ------ Web Image ------
FROM httpd:2.4-alpine AS web

# Copy the Apache configuration
COPY ./docker/apache/httpd.conf /usr/local/apache2/conf/

# Copy the website configuration
COPY ./docker/apache/vhosts/ludosport.conf /usr/local/apache2/conf/vhosts/

# Copie de l'application
COPY --chown=www-data:www-data --from=php-fpm /app/web /app/web

# Création des volumes
VOLUME [ "/var/local/drupal/files" ]
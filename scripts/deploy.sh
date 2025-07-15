#!/bin/sh

distribution=$(date +%s)

# Create the new distribution folder
mkdir /var/local/ludosport/www/$distribution
chown :daemon /var/local/ludosport/www/$distribution

# Get the last version of the project
git clone git@github.com:Zlika666/ludosport.paris.git /var/local/ludosport/www/$distribution
rm -r /var/local/ludosport/www/$distribution/.ddev

# Composer install
docker run --user 1001:1 --rm --interactive --tty \
    --volume /var/local/ludosport/www/$distribution:/app \
    composer install --ignore-platform-reqs --no-scripts --no-dev

# Maintenance mode on
docker exec --user 1001:1 ludosport_php drush maint:set 1

# Cache clear
docker exec --user 1001:1 ludosport_php drush cr

# Switch site version
ln -sf /var/local/ludosport/www/$distribution /var/local/ludosport/www/current

# Restart containers to take the switch into account
docker restart ludosport_web ludosport_php

# Manage file permissions
docker exec --user 1001:1 -ti ludosport_php ./scripts/dfp.sh /app

# DB Update
docker exec --user 1001:1 -ti ludosport_php drush updb -y

# Import configs
docker exec --user 1001:1 -ti ludosport_php bash -c "drush cim -y > /dev/null || drush cim -y"

# Maintenance mode off
docker exec php-fpm drush maint:set 0
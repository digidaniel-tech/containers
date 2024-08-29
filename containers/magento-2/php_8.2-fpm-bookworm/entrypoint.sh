#!/bin/bash

searchengine="${SEARCH_ENGINE:-opensearch}"

# Setup Composer authentication with environment variables
if [ -n "${MAGENTO_PUBLIC_KEY}" ] && [ -n "${MAGENTO_SECRET_KEY}" ]; then
  mkdir -p /root/.composer \
    && echo "{\"http-basic\":{\"repo.magento.com\":{\"username\":\"${MAGENTO_PUBLIC_KEY}\",\"password\":\"${MAGENTO_SECRET_KEY}\"}}}" > /root/.composer/auth.json
fi

# Install Magento if not already installed
if [ ! -f "app/etc/env.php" ]; then
  # Install Magento using composer
  composer create-project --repository-url=https://repo.magento.com/ \
    magento/project-community-edition:2.4.6 .

  # Set permissions
  find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +; \
    find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +; \
    chown -R :www-data .; \
    chmod u+x bin/magento

    bin/magento setup:install \
      --base-url="${MAGENTO_BASE_URL:-http://localhost/}" \
      --db-host="${DB_HOST:-localhost}" \
      --db-name="${DB_NAME:-magento}" \
      --db-user="${DB_USER:-magento}" \
      --db-password="${DB_PASS:-magento}" \
      --admin-firstname="${ADMIN_FIRSTNAME:-admin}" \
      --admin-lastname="${ADMIN_LASTNAME:-admin}" \
      --admin-email="${ADMIN_EMAIL:-admin@admin.com}" \
      --admin-user="${ADMIN_USER:-admin}" \
      --admin-password="${ADMIN_PASSWORD:-admin123}" \
      --language="${LANGUAGE:-en_US}" \
      --currency="${CURRENCY:-USD}" \
      --timezone="${TIMEZONE:-America/Chicago}" \
      --use-rewrites="${USE_REWRITES:-1}" \
      --search-engine="${searchengine}" \
      --${searchengine}-host="${SEARCH_ENGINE_HOST:-os-host.example.com}" \
      --${searchengine}-port="${SEARCH_ENGINE_PORT:-9200}" \
      --${searchengine}-index-prefix="${SEARCH_ENGINE_INDEX_PREFIX:-magento2}" \
      --${searchengine}-timeout="${SEARCH_ENGINE_TIMEOUT:-15}" \
      --${searchengine}-enable-auth="${SEARCH_ENGINE_ENABLE_AUTH:0}" \
      --${searchengine}-username="${SEARCH_ENGINE_USERNAME}" \
      --${searchengine}-password="${SEARCH_ENGINE_PASSWORD}" 
fi

# Start PHP-FPM
exec docker-php-entrypoint php-fpm
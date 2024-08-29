#!/bin/bash
set -e

searchengine="${SEARCH_ENGINE:-elasticsearch7}"

setup_composer_authentication() {
  if [ -n "${MAGENTO_PUBLIC_KEY}" ] && [ -n "${MAGENTO_SECRET_KEY}" ]; then
    mkdir -p /root/.composer
    echo "{\"http-basic\":{\"repo.magento.com\":{\"username\":\"${MAGENTO_PUBLIC_KEY}\",\"password\":\"${MAGENTO_SECRET_KEY}\"}}}" > /root/.composer/auth.json
  fi
}

install_magento() {
  composer create-project --repository-url=https://repo.magento.com/ \
    magento/project-community-edition:${MAGENTO_VERSION} .

  # Set permissions
  find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} + 
  find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} + 
  chown -R :www-data . 
  chmod u+x bin/magento
}

setup_magento() {
  local engine=$1
  
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
    --${engine}_host="${SEARCH_ENGINE_HOST:-localhost}" \
    --${engine}_port="${SEARCH_ENGINE_PORT:-9200}" \
    --${engine}_index-prefix="${SEARCH_ENGINE_INDEX_PREFIX:-magento2}" \
    --${engine}_timeout="${SEARCH_ENGINE_TIMEOUT:-15}" \
    --${engine}_enable-auth="${SEARCH_ENGINE_ENABLE_AUTH:0}" \
    --${engine}_username="${SEARCH_ENGINE_USERNAME}" \
    --${engine}_password="${SEARCH_ENGINE_PASSWORD}"
}

main() {
  setup_composer_authentication

  if [ ! -f "app/etc/env.php" ]; then
    install_magento

    case "${searchengine}" in
      opensearch)
        setup_magento "opensearch"
        ;;
      elasticsearch7)
        setup_magento "elasticsearch"
        ;;
      *)
        echo "Error: Unsupported search engine '${searchengine}'. Exiting." >&2
        exit 1
        ;;
    esac
  fi

  # Start PHP-FPM
  exec docker-php-entrypoint php-fpm
}

main "$@"

#!/bin/bash
set -e

setup_composer_authentication() {
  if [ -n "${MAGENTO_PUBLIC_KEY}" ] && [ -n "${MAGENTO_SECRET_KEY}" ]; then
    mkdir -p /root/.composer
    echo "{\"http-basic\":{\"repo.magento.com\":{\"username\":\"${MAGENTO_PUBLIC_KEY}\",\"password\":\"${MAGENTO_SECRET_KEY}\"}}}" > /root/.composer/auth.json
  fi
}

create_magento_project() {
  # Project is created in a temp folder and moved to app/ to being able to mount
  # local files to project during development
  echo "Creating Magento project in temp folder..."
  composer create-project --repository-url=https://repo.magento.com/ \
    magento/project-community-edition:${MAGENTO_VERSION} /app_temp/

  # Copying project to /app where project is run
  echo "Copying magento project to app folder..."
  rsync -a --ignore-existing /app_temp/ /app/
  rm -rf /app_temp

  # Set permissions
  echo "Setup Magento file permissions..."
  find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} + 
  find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} + 
  chmod 644 -R ./app/etc/*.xml
  chown -R :www-data . 
  chmod u+x bin/magento
}

setup_magento() {
  local arguments=$(build_argument_collection)

  echo "Starting Magento installation..."
  bin/magento setup:install ${arguments}
}

validate_required_data() {
  declare -a required_data=(
    "ADMIN_FIRSTNAME"
    "ADMIN_LASTNAME"
    "ADMIN_EMAIL"
    "ADMIN_USER"
    "ADMIN_PASSWORD"
    "BASE_URL"
    "DB_PASSWORD"
  )

  for var in "${required_data[@]}"; do
    value="${!var}"

    if [[ -z "$value" ]]; then
      echo "$var property is required to be set"
      exit 1
    fi
  done
}

validate_lock_provider() {
  if [[ "${LOCK_PROVIDER}" == "zookeeper" && -z "${LOCK_ZOOKEEPER_HOST}" ]]; then
    echo "LOCK_ZOOKEEPER_HOST property is required when LOCK_PROVIDER is set to zookeeper"
    exit 1
  fi

  if [[ "${LOCK_PROVIDER}" == "file" && -z "${LOCK_FILE_PATH}" ]]; then
    echo "LOCK_FILE_PATH property is required when LOCK_PROVIDER is set to file"
    exit 1
  fi
}

validate_elasticsearch_auth() {
  if [[ "${ELASTICSEARCH_ENABLE_AUTH}" == "true" ]]; then
    if [[ -z "${ELASTICSEARCH_USERNAME}" || -z "${ELASTICSEARCH_PASSWORD}" ]]; then
      echo "ELASTICSEARCH_USERNAME and ELASTICSEARCH_PASSWORD are required when ELASTICSEARCH_ENABLE_AUTH is set"
      exit 1
    fi
  fi
}

validate_opensearch_auth() {
  if [[ "${OPENSEARCH_ENABLE_AUTH}" == "true" ]]; then
    if [[ -z "${OPENSEARCH_USERNAME}" || -z "${OPENSEARCH_PASSWORD}" ]]; then
      echo "OPENSEARCH_USERNAME and OPENSEARCH_PASSWORD are required when OPENSEARCH_ENABLE_AUTH is set"
      exit 1
    fi
  fi
}

validate_environment_variables() {
  echo "Validating input data..."
  validate_required_data
  validate_lock_provider
  validate_elasticsearch_auth
  validate_opensearch_auth
}

build_argument_collection() {
  declare -A flag_map=(
    [BASE_URL]="--base-url"
    [ADMIN_FIRSTNAME]="--admin-firstname"
    [ADMIN_LASTNAME]="--admin-lastname"
    [ADMIN_EMAIL]="--admin-email"
    [ADMIN_USER]="--admin-user"
    [ADMIN_PASSWORD]="--admin-password"
    [BACKEND_FRONTNAME]="--backend-frontname"
    [LANGUAGE]="--language"
    [CURRENCY]="--currency"
    [TIMEZONE]="--timezone"
    [USE_REWRITES]="--use-rewrites"
    [USE_SECURE]="--use-secure"
    [BASE_URL_SECURE]="--base-url-secure"
    [USE_SECURE_ADMIN]="--use-secure-admin"
    [ADMIN_USE_SECURITY_KEY]="--admin-use-security-key"
    [SESSION_SAVE]="--session-save"
    [KEY]="--key"
    [SALES_ORDER_INCREMENT_PREFIX]="--sales-order-increment-prefix"
    [DB_HOST]="--db-host"
    [DB_NAME]="--db-name"
    [DB_USER]="--db-user"
    [DB_PASSWORD]="--db-password"
    [DB_PREFIX]="--db-prefix"
    [DB_SSL_KEY]="--db-ssl-key"
    [DB_SSL_CERT]="--db-ssl-cert"
    [DB_SSL_CA]="--db-ssl-ca"
    [CLEANUP_DATABASE]="--cleanup-database"
    [DB_INIT_STATEMENTS]="--db-init-statements"
    [SEARCH_ENGINE]="--search-engine"
    [ELASTICSEARCH_HOST]="--elasticsearch-host"
    [ELASTICSEARCH_PORT]="--elasticsearch-port"
    [ELASTICSEARCH_INDEX_PREFIX]="--elasticsearch-index-prefix"
    [ELASTICSEARCH_TIMEOUT]="--elasticsearch-timeout"
    [ELASTICSEARCH_ENABLE_AUTH]="--elasticsearch-enable-auth"
    [ELASTICSEARCH_USERNAME]="--elasticsearch-username"
    [ELASTICSEARCH_PASSWORD]="--elasticsearch-password"
    [OPENSEARCH_HOST]="--opensearch-host"
    [OPENSEARCH_PORT]="--opensearch-port"
    [OPENSEARCH_INDEX_PREFIX]="--opensearch-index-prefix"
    [OPENSEARCH_TIMEOUT]="--opensearch-timeout"
    [OPENSEARCH_ENABLE_AUTH]="--opensearch-enable-auth"
    [OPENSEARCH_USERNAME]="--opensearch-username"
    [OPENSEARCH_PASSWORD]="--opensearch-password"
    [AMQP_HOST]="--amqp-host"
    [AMQP_PORT]="--amqp-port"
    [AMQP_USER]="--amqp-user"
    [AMQP_PASSWORD]="--amqp-password"
    [AMQP_VIRTUALHOST]="--amqp-virtualhost"
    [AMQP_SSL]="--amqp-ssl"
    [CONSUMERS_WAIT_FOR_MESSAGES]="--consumers-wait-for-messages"
    [LOCK_PROVIDER]="--lock-provider"
    [LOCK_DB_PREFIX]="--lock-db-prefix"
    [LOCK_ZOOKEEPER_HOST]="--lock-zookeeper-host"
    [LOCK_ZOOKEEPER_PATH]="--lock-zookeeper-path"
    [LOCK_FILE_PATH]="--lock-file-path"
  )
  
  local arguments=()
  for var in "${!flag_map[@]}"; do
    value="${!var}"

    if [[ -n "$value" ]]; then
        arguments+=("${flag_map[$var]}=$value")
    fi
  done

  echo "${arguments[@]}"
}

main() {
  validate_environment_variables
  setup_composer_authentication

  if [ ! -f "app/etc/env.php" ]; then
    create_magento_project
    setup_magento
  fi

  # Start PHP-FPM
  exec docker-php-entrypoint php-fpm
}

main "$@"

FROM php:8.2-fpm-bookworm

# Install dependencies
RUN apt update && apt install -y \
  unzip \
  libcurl4-openssl-dev \
  libxml2-dev \
  zlib1g-dev \
  libpng-dev \
  libonig-dev \
  libsodium-dev \
  libxslt1-dev \
  libzip-dev \
  libpcre3-dev \
  libssl-dev \
  && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install \
  bcmath \
  ctype \
  curl \
  dom \
  fileinfo \
  filter \
  gd \
  iconv \
  intl \
  mbstring \
  pdo_mysql \
  simplexml \
  soap \
  sockets \
  sodium \
  xsl \
  zip

# Install Composer
RUN curl -sS https://getcomposer.org/installer \
  | php -- --install-dir=/usr/local/bin --filename=composer

# Copy tailored php.ini file for Magento
COPY ./php.ini /usr/local/etc/php/php.ini

# Change workdir to where magento will be installed
WORKDIR /app

# Setup endpoint that will setup and install Magento
COPY ./entrypoint.sh /entrypoint.sh 
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT [ "/entrypoint.sh" ]
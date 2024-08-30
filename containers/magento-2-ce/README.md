# Magento 2 Container

## Build and push new image

Run the following command from container project folder (ex. containers/magento-2-ce)

> docker build php_8.2-fpm-bookworm -t digidanieltech/magento2:*tag*

Once image is build run the following to push to docker hub

> docker push digidanieltech/magento2:*tag*

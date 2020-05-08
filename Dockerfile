FROM php:7.3-apache

WORKDIR /var/www/html

ENV APACHE_DOCUMENT_ROOT /var/www/html/

ENV TZ=Asia/Jakarta

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get update && apt-get install curl -y

# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 10.15.2


RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.2/install.sh | bash

# Install package for php
RUN apt-get install -y libxml2-dev \
        libzip-dev libpq-dev \
        libmcrypt-dev \
        libmagickwand-dev \
        libreadline-dev \
        libssl-dev zlib1g-dev \
        libpng-dev libjpeg-dev \
        libfreetype6-dev \
        git \
        zip \
        cron \
        vim \
        wget \
        --no-install-recommends \
        && pecl install mcrypt-1.0.2 \
        && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
        && docker-php-ext-configure zip --with-libzip \ 
        && docker-php-ext-install pdo_mysql pdo_pgsql pgsql gd xml zip mbstring exif \
        && docker-php-ext-enable mcrypt
       
# add mc client
RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc && chmod +x mc && ./mc --help

# Enable rewrite module apache #
RUN a2enmod rewrite && mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && sed -i -e 's/expose_php = On/expose_php = Off/' /usr/local/etc/php/php.ini \
    && echo "ServerTokens Prod" >> /etc/apache2/apache2.conf \
    && echo "ServerSignature Off" >> /etc/apache2/apache2.conf \
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf 
   
# add composer.phar 
ADD composer.phar /var/www/html/
RUN  php composer.phar -V 

RUN  apt-get remove curl wget bash-y \
     && apt-get autoremove -y \
     && apt-get purge -y \
     && rm -r /var/lib/apt/lists/*

EXPOSE 80

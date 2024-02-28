FROM php:8.1.0-apache
WORKDIR  /var/www/html

# Mod Rewrite

RUN a2enmod rewrite

# Linux Library

RUN apt-get update -y && apt-get install -y \
    libicu-dev \
    libmariadb-dev \
    unzip zip \
    zlib1g-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype-dev \
    libjpeg62-turbo-dev \
    libpng-dev

#Composer
COPY --from=composer:latest /usr/bin/composer/ /usr/bin/composer

#PHP Extension
RUN docker-php-ext-install gettext intl pdo_mysql gd

# Enable GD extension with freetype and jpeg support
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# Install GD extension
RUN docker-php-ext-install -j$(nproc) gd

# Run composer create-project to create a new Laravel project
# RUN composer create-project --prefer-dist laravel/laravel /var/www/html/docker-app
# NPc
FROM php:7.2.6-apache

COPY . /var/www
COPY .docker/vhost.conf /etc/apache2/sites-available/000-default.conf
COPY .docker/server.crt /etc/apache2/ssl/server.crt
COPY .docker/server.key /etc/apache2/ssl/server.key

WORKDIR /var/www

RUN apt-get update
RUN apt-get install -y --no-install-recommends gnupg
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list

RUN apt-get install -y --no-install-recommends \
        libxml2-dev \
        locales \
        apt-transport-https \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && apt-get update


RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN ACCEPT_EULA=Y apt-get -yq --no-install-recommends install \
        unixodbc-dev \
        msodbcsql17

RUN apt-get install -y apt-utils net-tools libmcrypt-dev \
	vim libpng-dev libmagickwand-dev zip unzip
RUN docker-php-ext-install calendar mbstring pdo pdo_mysql mysqli soap
RUN pecl install sqlsrv pdo_sqlsrv
RUN docker-php-ext-enable sqlsrv pdo_sqlsrv
RUN pecl install imagick
RUN docker-php-ext-enable imagick

RUN apt-get install -y libfreetype6-dev \
        libjpeg-dev \
        libpng-dev

RUN docker-php-ext-configure gd \
        --enable-gd-native-ttf \
        --with-freetype-dir=/usr/include/freetype2 \
        --with-png-dir=/usr/include \
        --with-jpeg-dir=/usr/include \
    && docker-php-ext-install gd \
    && docker-php-ext-enable gd

RUN pecl install mcrypt-1.0.1

RUN docker-php-ext-enable mcrypt

RUN pecl install xdebug

RUN docker-php-ext-enable xdebug

RUN echo 'xdebug.default_enable=1' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_enable=1' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_autostart=1' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_handler=dbgp' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_port=9000' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_connect_back=0' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.idekey="DRG_DEBUG"' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_host="docker.for.mac.localhost"' >> /usr/local/etc/php/php.ini

RUN echo 'log_errors=On' >> /usr/local/etc/php/php.ini
RUN echo 'error_log="/var/www/phperror.log"' >> /usr/local/etc/php/php.ini

RUN apt-get -y install git

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN apt-get install -y curl software-properties-common
RUN curl -sL https://deb.nodesource.com/setup_13.x | bash -
RUN apt-get install -y nodejs

RUN a2enmod ssl
RUN a2enmod rewrite

RUN chown -R www-data:www-data /var/www/content
RUN chown -R www-data:www-data /var/www/storage

RUN service apache2 restart

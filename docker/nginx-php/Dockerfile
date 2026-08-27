ARG PHP_VERSION=8.3
FROM debian:bookworm-slim

LABEL maintainer="waifly" \
      org.opencontainers.image.description="Waifly custom Nginx+PHP-FPM runtime for Pterodactyl (WebHost egg) - serves /home/container/webroot only, no arbitrary proxy_pass"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl wget git unzip zip jq gnupg lsb-release apt-transport-https \
    && curl -sSL https://packages.sury.org/php/apt.gpg -o /etc/apt/trusted.gpg.d/php.gpg \
    && echo "deb https://packages.sury.org/php/ bookworm main" > /etc/apt/sources.list.d/php.list \
    && apt-get update

ARG PHP_VERSION
RUN apt-get install -y --no-install-recommends \
        nginx-light \
        php${PHP_VERSION}-fpm php${PHP_VERSION}-cli php${PHP_VERSION}-common \
        php${PHP_VERSION}-mysql php${PHP_VERSION}-curl php${PHP_VERSION}-gd \
        php${PHP_VERSION}-mbstring php${PHP_VERSION}-xml php${PHP_VERSION}-zip \
        php${PHP_VERSION}-bcmath php${PHP_VERSION}-intl php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-sqlite3 php${PHP_VERSION}-imagick \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sS https://getcomposer.org/installer | php${PHP_VERSION} -- --install-dir=/usr/local/bin --filename=composer

# Non-root only (Wings always forces --user, never root): drop the default pool config that
# assumes it can setuid to www-data, disable the daemon's own pidfile/log paths (redirect to
# stderr instead) so nothing here needs write access outside /home/container and /tmp.
COPY php-fpm-pool.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
RUN sed -i \
        -e 's|^error_log = .*|error_log = /dev/stderr|' \
        -e 's|^pid = .*|pid = /tmp/php-fpm.pid|' \
        /etc/php/${PHP_VERSION}/fpm/php-fpm.conf \
    && ln -sf /usr/sbin/php-fpm${PHP_VERSION} /usr/local/bin/php-fpm-run \
    && ln -sf /etc/php/${PHP_VERSION}/fpm/php-fpm.conf /etc/php-fpm.conf

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start-web.sh /start-web.sh
RUN chmod +x /start-web.sh

RUN mkdir -p /home/container
WORKDIR /home/container

ENV USER=container HOME=/home/container

STOPSIGNAL SIGQUIT
CMD ["/start-web.sh"]

#!/bin/bash
cd /home/container || exit 1

# Accept either an existing www/ (legacy layout, e.g. migrated from another nginx egg) or
# webroot/ (this egg's default for fresh installs). webroot wins if both somehow exist.
if [[ -d webroot ]]; then
    DOCROOT="webroot"
elif [[ -d www ]]; then
    DOCROOT="www"
else
    DOCROOT="webroot"
    mkdir -p webroot
fi

if [[ -d "${DOCROOT}/.git" ]] && [[ "${AUTO_UPDATE}" == "1" ]]; then
    (cd "${DOCROOT}" && git pull)
fi

if [ ! -f "${DOCROOT}/index.php" ] && [ ! -f "${DOCROOT}/index.html" ]; then
    cat > "${DOCROOT}/index.php" <<'PHP'
<?php phpinfo();
PHP
fi

sed -e "s/__SERVER_PORT__/${SERVER_PORT}/" -e "s#__DOCROOT__#/home/container/${DOCROOT}#" /etc/nginx/nginx.conf.template > /tmp/nginx.conf

if [[ -n "${COMPOSER_MODULES}" ]]; then
    composer require ${COMPOSER_MODULES} --working-dir="/home/container/${DOCROOT}" --no-interaction || true
fi

php-fpm-run -F -y /etc/php-fpm.conf &
PHP_FPM_PID=$!

# Optional: only runs if the customer set a Cloudflare Tunnel connector token (Cloudflare
# dashboard -> Zero Trust -> Networks -> Tunnels). Same mechanism as any other Cloudflare Tunnel
# origin - just a cloudflared client maintaining an outbound connection, nothing Cloudflare or
# this box does automatically without it.
CLOUDFLARED_PID=""
if [[ -n "${CLOUDFLARE_TUNNEL_TOKEN}" ]]; then
    echo "Starting Cloudflare Tunnel..."
    cloudflared tunnel --no-autoupdate run --token "${CLOUDFLARE_TUNNEL_TOKEN}" &
    CLOUDFLARED_PID=$!
fi

trap 'kill -TERM "$PHP_FPM_PID" ${CLOUDFLARED_PID:+"$CLOUDFLARED_PID"} 2>/dev/null' TERM INT QUIT

if ! nginx -c /tmp/nginx.conf -t; then
    echo "nginx configuration test failed, aborting startup"
    kill -TERM "$PHP_FPM_PID" 2>/dev/null
    exit 1
fi

cat <<'BANNER'

__          __   _  __ _
\ \        / /  (_)/ _| |
 \ \  /\  / /_ _ _| |_| |_   _
  \ \/  \/ / _` | |  _| | | | |
   \  /\  / (_| | | | | | |_| |
    \/  \/ \__,_|_|_| |_|\__, |
                          __/ |
                         |___/

-----------------------------------------------------------------------
BANNER
printf '\033[1;32mServer started\033[0m\n\n'

exec nginx -c /tmp/nginx.conf -g 'daemon off;'

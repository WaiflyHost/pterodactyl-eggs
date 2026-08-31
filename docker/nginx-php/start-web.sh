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

# Optional self-service app config: /home/container/.env, KEY=VALUE per line (# comments, blank
# lines ignored). Parsed as plain data - never sourced/eval'd, so it cannot run shell commands or
# touch nginx/php-fpm's own config the way editing their raw config files used to allow on the old
# egg. Exported before php-fpm starts so it reaches $_SERVER/getenv() in the app (php-fpm-pool.conf
# already has clear_env=no). Lives one level above the docroot, so it's never web-reachable no
# matter what nginx rule is or isn't in place. Deliberately outside the panel's egg-variable list:
# this is the escape hatch for whatever a customer's specific app needs that we haven't (and won't)
# add as a first-class egg variable one request at a time.
ENV_FILE="/home/container/.env"
RESERVED_ENV_KEYS=" PATH HOME USER PWD SHLVL _ SERVER_PORT DOCROOT STARTUP GIT_ADDRESS BRANCH USER_UPLOAD AUTO_UPDATE USERNAME ACCESS_TOKEN COMPOSER_MODULES CLOUDFLARE_TUNNEL_TOKEN "
ENV_FILE_LOADED_COUNT=0
if [[ -f "${ENV_FILE}" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"
        [[ -z "$line" || "$line" == \#* ]] && continue
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            if [[ "$value" =~ ^\"(.*)\"$ ]] || [[ "$value" =~ ^\'(.*)\'$ ]]; then
                value="${BASH_REMATCH[1]}"
            fi
            [[ "$key" == P_SERVER_* ]] && continue
            [[ "${RESERVED_ENV_KEYS}" == *" ${key} "* ]] && continue
            export "$key=$value"
            ENV_FILE_LOADED_COUNT=$((ENV_FILE_LOADED_COUNT + 1))
        fi
    done < "${ENV_FILE}"
fi

cat <<EOF

-----------------------------------------------------------------------
App config: this egg only ships nginx + PHP-FPM, no editable server
config, and no extra process besides the optional Cloudflare Tunnel
below. Need your own env vars (DB credentials, API keys, ...)? Drop a
plain "KEY=VALUE" per line (# for comments) into:
  /home/container/.env
It is only ever read as data (never executed), sits above your web
root so it's never web-reachable, and is exported for PHP before
PHP-FPM starts (so it reaches \$_SERVER / getenv() in your app).
$( [[ ${ENV_FILE_LOADED_COUNT} -gt 0 ]] && echo "Loaded ${ENV_FILE_LOADED_COUNT} variable(s) from .env just now." || echo "No .env found - create one any time, it's picked up on next start/restart." )
-----------------------------------------------------------------------
EOF

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

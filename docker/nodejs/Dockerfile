ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-bookworm-slim

LABEL maintainer="waifly" \
      org.opencontainers.image.description="Waifly custom Node.js runtime for Pterodactyl (Universal egg)"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl wget git unzip zip jq gnupg \
        build-essential python3 sqlite3 libsqlite3-dev tzdata \
    && rm -rf /var/lib/apt/lists/*

# The official node image bundles whichever npm shipped with that Node release, which npm itself
# then nags about being outdated (its own "new version available" notice, unrelated to Node's own
# version). Pin to the newest npm whose own package.json "engines.node" range this NODE_VERSION
# actually satisfies (passed in by build.sh, computed from the real npm registry metadata) - NOT
# npm@latest, which can require a newer Node than an older NODE_VERSION here actually has and
# leave a broken npm on that image.
ARG NPM_VERSION
RUN npm install -g npm@${NPM_VERSION} typescript ts-node pm2 pnpm && corepack enable || true

RUN mkdir -p /home/container
WORKDIR /home/container

ENV USER=container HOME=/home/container

COPY entrypoint.sh /entrypoint.sh
COPY start.sh /start.sh
RUN chmod +x /entrypoint.sh /start.sh

STOPSIGNAL SIGINT
ENTRYPOINT ["/entrypoint.sh"]

ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-bookworm-slim

LABEL maintainer="waifly" \
      org.opencontainers.image.description="Waifly custom Node.js runtime for Pterodactyl (Universal egg)"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl wget git unzip zip jq gnupg \
        build-essential python3 sqlite3 libsqlite3-dev tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g typescript ts-node pm2 pnpm && corepack enable || true

RUN mkdir -p /home/container
WORKDIR /home/container

ENV USER=container HOME=/home/container

COPY entrypoint.sh /entrypoint.sh
COPY start.sh /start.sh
RUN chmod +x /entrypoint.sh /start.sh

STOPSIGNAL SIGINT
ENTRYPOINT ["/entrypoint.sh"]

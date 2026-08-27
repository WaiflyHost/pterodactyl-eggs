ARG GO_VERSION=1.25
FROM golang:${GO_VERSION}-bookworm

LABEL maintainer="waifly" \
      org.opencontainers.image.description="Waifly custom Go runtime for Pterodactyl (Universal egg)"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl wget git unzip zip jq gnupg \
        build-essential tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/container
WORKDIR /home/container

ENV USER=container HOME=/home/container GOPATH=/home/container/go GOCACHE=/home/container/.cache/go-build

COPY entrypoint.sh /entrypoint.sh
COPY start.sh /start.sh
RUN chmod +x /entrypoint.sh /start.sh

STOPSIGNAL SIGINT
ENTRYPOINT ["/entrypoint.sh"]

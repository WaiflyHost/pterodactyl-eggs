ARG JAVA_VERSION=21
FROM eclipse-temurin:${JAVA_VERSION}-jdk

LABEL maintainer="waifly" \
      org.opencontainers.image.description="Waifly custom Java runtime for Pterodactyl (Java generic egg)"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl wget git unzip zip jq gnupg iproute2 \
        tzdata fontconfig libfreetype6 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/container
WORKDIR /home/container

ENV USER=container HOME=/home/container

COPY entrypoint.sh /entrypoint.sh
COPY start.sh /start.sh
RUN chmod +x /entrypoint.sh /start.sh

STOPSIGNAL SIGINT
ENTRYPOINT ["/entrypoint.sh"]

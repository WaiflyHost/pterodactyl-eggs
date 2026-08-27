ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-slim-bookworm

LABEL maintainer="waifly" \
      org.opencontainers.image.description="Waifly custom Python runtime for Pterodactyl (Universal egg)"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl wget git unzip zip jq gnupg \
        build-essential libffi-dev libssl-dev tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --upgrade pip setuptools wheel virtualenv

RUN mkdir -p /home/container
WORKDIR /home/container

ENV USER=container HOME=/home/container PYTHONUNBUFFERED=1

COPY entrypoint.sh /entrypoint.sh
COPY start.sh /start.sh
RUN chmod +x /entrypoint.sh /start.sh

STOPSIGNAL SIGINT
ENTRYPOINT ["/entrypoint.sh"]

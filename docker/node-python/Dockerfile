FROM debian:bookworm-slim

LABEL maintainer="waifly" \
      org.opencontainers.image.description="Waifly combined Node.js + Python runtime for Pterodactyl - both toolchains installed with multiple versions, selectable independently at runtime via NODE_VERSION / PYTHON_VERSION"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl wget git unzip zip jq gnupg build-essential \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js: install several versions via nvm, then expose each as a stable
# /usr/local/nodeversions/<major>/bin path (symlinked from nvm's own versioned install dirs) so the
# startup script can select one by simply prepending the right directory to PATH - no need to
# "source" nvm's shell function at container startup (it only works in interactive/login shells).
ENV NVM_DIR=/usr/local/nvm
RUN mkdir -p "$NVM_DIR" \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && for v in 16 18 19 20 21 22 23 24 25 26; do \
        nvm install "$v" && \
        mkdir -p "/usr/local/nodeversions/$v" && \
        ln -sfn "$(dirname "$(nvm which "$v")")" "/usr/local/nodeversions/$v/bin"; \
    done \
    && nvm alias default 22 \
    && . "$NVM_DIR/nvm.sh" && nvm use 22 && npm install -g typescript ts-node pm2 pnpm && corepack enable || true

# ── Python: install several versions via pyenv. pyenv's shims (PATH-based dispatch driven by the
# PYENV_VERSION env var) work in a plain non-interactive shell, unlike nvm, so no extra symlinking
# needed here - the startup script just exports PYENV_VERSION.
ENV PYENV_ROOT=/usr/local/pyenv
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
RUN git clone --depth 1 https://github.com/pyenv/pyenv.git "$PYENV_ROOT" \
    && for v in 3.8.20 3.9.20 3.10.15 3.11.10 3.12.7 3.13.0 3.14.0; do \
        pyenv install -s "$v"; \
    done \
    && pyenv global 3.12.7 \
    && pyenv exec pip install --no-cache-dir --upgrade pip setuptools wheel virtualenv

RUN mkdir -p /home/container
WORKDIR /home/container

ENV USER=container HOME=/home/container PYTHONUNBUFFERED=1

COPY entrypoint.sh /entrypoint.sh
COPY start.sh /start.sh
RUN chmod +x /entrypoint.sh /start.sh

STOPSIGNAL SIGINT
ENTRYPOINT ["/entrypoint.sh"]

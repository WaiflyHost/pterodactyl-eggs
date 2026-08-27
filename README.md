# Waifly Pterodactyl Eggs

Custom Node.js, Python, Go and Nginx+PHP eggs for [Pterodactyl](https://pterodactyl.io), self-built and
self-maintained by Waifly instead of depending on third-party image maintainers whose update cadence
you don't control.

Images are based on official Debian-slim upstream images with "rolling" tags (`node:22-bookworm-slim`,
`python:3.12-slim-bookworm`, `golang:1.25-bookworm`, ...), so rebuilding always picks up the latest
minor/patch release. All images are public on GHCR - no authentication needed to pull.

## Available versions

- **Node.js**: 16, 18, 19, 20, 21, 22, 23, 24, 25, 26 - `ghcr.io/waiflyhost/nodejs:<version>`
- **Python**: 2.7, 3.8, 3.9, 3.10, 3.11, 3.12, 3.13, 3.14 - `ghcr.io/waiflyhost/python:<version>`
- **Go**: 1.21 - 1.27 - `ghcr.io/waiflyhost/go:<version>`
- **Nginx + PHP-FPM**: PHP 8.1 - 8.4 - `ghcr.io/waiflyhost/nginx-php:<version>`

Node images ship `typescript`, `ts-node`, `pm2`, `pnpm` (and `yarn`, bundled by the official Node
image). Python images ship an up-to-date `pip`/`setuptools`/`wheel`/`virtualenv`. Go images ship the
standard toolchain only. Nginx+PHP images ship Composer and the common PHP extensions (mysqli, curl,
gd, mbstring, xml, zip, bcmath, intl, opcache, sqlite3, imagick). All images include `git`, `curl`,
`unzip`, `build-essential`.

## How to import into your panel

1. In the admin panel, go to **Nests** and pick (or create) a nest to hold the egg.
2. Click **Import Egg**.
3. Upload whichever of these you need from this repo's [`eggs/`](eggs) folder:
   [`egg-nodejs-waifly.json`](eggs/egg-nodejs-waifly.json),
   [`egg-python-waifly.json`](eggs/egg-python-waifly.json),
   [`egg-go-waifly.json`](eggs/egg-go-waifly.json),
   [`egg-nginx-php-waifly.json`](eggs/egg-nginx-php-waifly.json).
4. That's it - each egg's Docker Images list already points at the public GHCR images, nothing else to
   configure. Wings will pull them anonymously (no `docker login` needed).

### Node.js / Python

No install script, you upload your own files (SFTP or the panel's file manager), then set two free-form
shell commands - **Startup Command 1** (`STARTUP_CMD`, e.g. installing dependencies) runs first, then
**Startup Command 2** (`SECOND_CMD`, e.g. starting the app) becomes the running process. Defaults are
`npm install --save --production` / `node .` for Node, and `pip install -r requirements.txt` /
`python bot.py` for Python - edit either field to whatever your app needs (including a `git clone ...`
as part of Startup Command 1 if you'd rather deploy from a repo).

### Go

Clones a Git repo (or use `USER_UPLOAD` if you upload files yourself), then `go build`s it and runs the
resulting binary. The binary is only rebuilt when missing or when `AUTO_UPDATE` is enabled, so restarts
after the first boot are fast. `BINARY_NAME` / `BUILD_PATH` / `BUILD_ARGS` / `RUN_ARGS` control the
build and run invocation.

### Nginx + PHP-FPM

Intentionally bounded: this is a static/PHP web-hosting egg, not a general-purpose reverse proxy. Nginx
and PHP-FPM run together in the container and serve **only** `/home/container/webroot` (or
`/home/container/www` if that already exists - e.g. migrating from another nginx egg, no rename
needed). There is no exposed nginx config field and no `proxy_pass` target a customer could point at
internal infrastructure. Clones a Git repo into webroot/www (or use `USER_UPLOAD`); set `COMPOSER_MODULES`
to have Composer packages installed on startup.

## Rebuilding the images yourself

The `docker/` directory has the exact Dockerfiles and scripts used to build these images, in case you'd
rather build and host your own copies:

```
docker build -t your-registry/nodejs:22    --build-arg NODE_VERSION=22    docker/nodejs
docker build -t your-registry/python:3.12  --build-arg PYTHON_VERSION=3.12 docker/python
docker build -t your-registry/go:1.25      --build-arg GO_VERSION=1.25    docker/go
docker build -t your-registry/nginx-php:8.4 --build-arg PHP_VERSION=8.4   docker/nginx-php
```

The `entrypoint.sh` in the nodejs/python/go images reads the `STARTUP` environment variable that Wings
sets (with `{{VARIABLE}}` placeholders), substitutes them, and executes the result - this is what any
Pterodactyl runtime image needs to actually run whatever Startup Command the egg defines (Wings itself
only sets the environment variables, it does not invoke the command for you). The nodejs/python eggs set
the Startup Command to `/start.sh`, a small script also baked into the image that runs `STARTUP_CMD`
then `exec`s into `SECOND_CMD`. The nginx-php image instead runs a fixed `/start-web.sh` directly as its
Docker `CMD` (no customer-editable startup command at all - that's the "bounded" design).

## Maintenance

These images are rebuilt periodically to track upstream security/patch releases. If you imported an egg
with its `update_url` pointing at this repo, the panel can re-check for egg updates from the admin UI -
though re-fetching the JSON does not itself trigger a Docker image rebuild on your side (only its tag,
e.g. `nodejs:22`, always resolves to the newest patch already built here).

Need a version that isn't listed, or want us to prioritize a rebuild? Contact **contact@waifly.com**.

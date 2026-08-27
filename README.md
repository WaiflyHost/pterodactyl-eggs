# Waifly Pterodactyl Eggs

Custom Node.js and Python "Universal" eggs for [Pterodactyl](https://pterodactyl.io), self-built and
self-maintained by Waifly instead of depending on third-party image maintainers whose update cadence
you don't control.

Images are based on the official Debian-slim `node` and `python` Docker Hub images with "rolling" tags
(`node:22-bookworm-slim`, `python:3.12-slim-bookworm`, ...), so rebuilding always picks up the latest
minor/patch release. All images are public on GHCR - no authentication needed to pull.

## Available versions

- **Node.js**: 16, 18, 19, 20, 21, 22, 23, 24, 25, 26 - `ghcr.io/waiflyhost/nodejs:<version>`
- **Python**: 2.7, 3.8, 3.9, 3.10, 3.11, 3.12, 3.13, 3.14 - `ghcr.io/waiflyhost/python:<version>`

Each image includes: `git`, `curl`, `unzip`, `build-essential` (native module compilation).
Node images additionally ship `typescript`, `ts-node`, `pm2`, `pnpm` (and `yarn`, bundled by the
official Node image). Python images ship an up-to-date `pip`/`setuptools`/`wheel`/`virtualenv`.

## How to import into your panel

1. In the admin panel, go to **Nests** and pick (or create) a nest to hold the egg.
2. Click **Import Egg**.
3. Upload [`eggs/egg-nodejs-waifly.json`](eggs/egg-nodejs-waifly.json) and/or
   [`eggs/egg-python-waifly.json`](eggs/egg-python-waifly.json) from this repo.
4. That's it - the egg's Docker Images list already points at the public GHCR images, nothing else to
   configure. Wings will pull them anonymously (no `docker login` needed).

Both eggs use the same pattern: no install script, you upload your own files (SFTP or the panel's file
manager), then set two free-form shell commands - **Startup Command 1** (`STARTUP_CMD`, e.g. installing
dependencies) runs first, then **Startup Command 2** (`SECOND_CMD`, e.g. starting the app) becomes the
running process. Defaults are `npm install --save --production` / `node .` for Node, and
`pip install -r requirements.txt` / `python bot.py` for Python - edit either field to whatever your app
needs (including a `git clone ...` as part of Startup Command 1 if you'd rather deploy from a repo).

## Rebuilding the images yourself

The `docker/` directory has the exact Dockerfiles and entrypoint scripts used to build these images,
in case you'd rather build and host your own copies:

```
docker build -t your-registry/nodejs:22 --build-arg NODE_VERSION=22 docker/nodejs
docker build -t your-registry/python:3.12 --build-arg PYTHON_VERSION=3.12 docker/python
```

The `entrypoint.sh` in each image reads the `STARTUP` environment variable that Wings sets (with
`{{VARIABLE}}` placeholders), substitutes them, and executes the result - this is what any Pterodactyl
runtime image needs to actually run whatever Startup Command the egg defines (Wings itself only sets
the environment variables, it does not invoke the command for you). These eggs set the Startup Command
to `/start.sh`, a small script also baked into the image that runs `STARTUP_CMD` then `exec`s into
`SECOND_CMD` as the long-running process.

## Maintenance

These images are rebuilt periodically to track upstream security/patch releases. If you imported the
egg with the `update_url` pointing at this repo, the panel can re-check for egg updates from the admin
UI - though re-fetching the JSON does not itself trigger a Docker image rebuild on your side (only its
tag, e.g. `nodejs:22`, always resolves to the newest patch already built here).

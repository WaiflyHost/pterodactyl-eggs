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

Both eggs use the same generic pattern: clone a Git repo (or set `USER_UPLOAD=1` if you upload files
yourself), install dependencies, then run the app. See the egg's variables for details (`MAIN_FILE`,
`NODE_ARGS` / `PY_FILE`, `PY_ARGS`, `AUTO_UPDATE`, etc.).

## Rebuilding the images yourself

The `docker/` directory has the exact Dockerfiles and entrypoint scripts used to build these images,
in case you'd rather build and host your own copies:

```
docker build -t your-registry/nodejs:22 --build-arg NODE_VERSION=22 docker/nodejs
docker build -t your-registry/python:3.12 --build-arg PYTHON_VERSION=3.12 docker/python
```

The `entrypoint.sh` in each image reads the `STARTUP` environment variable that Wings sets (with
`{{VARIABLE}}` placeholders), substitutes them, and executes the result - this is what makes the
"generic" startup pattern (a raw `node`/`python3` command in the egg's Startup Command) work. `start.sh`
is a convenience wrapper for eggs that use a fixed `/start.sh` startup command with `STARTUP_CMD` /
`SECOND_CMD` variables (run first, then exec into second).

## Maintenance

These images are rebuilt periodically to track upstream security/patch releases. If you imported the
egg with the `update_url` pointing at this repo, the panel can re-check for egg updates from the admin
UI - though re-fetching the JSON does not itself trigger a Docker image rebuild on your side (only its
tag, e.g. `nodejs:22`, always resolves to the newest patch already built here).

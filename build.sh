#!/usr/bin/env bash
set -euo pipefail

REGISTRY="5.180.34.45:5000/waifly-eggs"
NODE_VERSIONS=(16 18 20 21 22 23 24 25 26)
PYTHON_VERSIONS=(3.8 3.9 3.10 3.11 3.12 3.13 3.14)

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "===== Building Node.js images ====="
NPM_REGISTRY_CACHE="$(mktemp)"
trap 'rm -f "${NPM_REGISTRY_CACHE}"' EXIT
for v in "${NODE_VERSIONS[@]}"; do
    tag="${REGISTRY}/nodejs:${v}"
    npm_version="$(node "${DIR}/resolve-npm-version.js" "${v}" "${NPM_REGISTRY_CACHE}")"
    echo "--- node ${v} (npm ${npm_version}) -> ${tag} ---"
    docker build --pull -t "${tag}" --build-arg NODE_VERSION="${v}" --build-arg NPM_VERSION="${npm_version}" "${DIR}/node"
    docker push "${tag}"
done

echo "===== Building Python images ====="
for v in "${PYTHON_VERSIONS[@]}"; do
    tag="${REGISTRY}/python:${v}"
    echo "--- python ${v} -> ${tag} ---"
    docker build --pull -t "${tag}" --build-arg PYTHON_VERSION="${v}" "${DIR}/python"
    docker push "${tag}"
done

echo "===== Done ====="

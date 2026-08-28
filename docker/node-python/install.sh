#!/bin/bash
# Node.js + Python App Installation Script (Waifly combo egg)
#
# Server Files: /mnt/server

NODE_VERSION="${NODE_VERSION:-22}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12.7}"

if [[ -d "/usr/local/nodeversions/${NODE_VERSION}/bin" ]]; then
    export PATH="/usr/local/nodeversions/${NODE_VERSION}/bin:${PATH}"
else
    export PATH="/usr/local/nodeversions/22/bin:${PATH}"
fi
export PYENV_VERSION="${PYTHON_VERSION}"

mkdir -p /mnt/server
cd /mnt/server

if [ "${USER_UPLOAD}" == "true" ] || [ "${USER_UPLOAD}" == "1" ]; then
    echo -e "USER_UPLOAD is set, skipping git clone. Upload your files manually."
    exit 0
fi

if [[ ${GIT_ADDRESS} != *.git ]]; then
    GIT_ADDRESS=${GIT_ADDRESS}.git
fi

if [ -z "${USERNAME}" ] && [ -z "${ACCESS_TOKEN}" ]; then
    echo -e "using anonymous git access"
else
    GIT_ADDRESS="https://${USERNAME}:${ACCESS_TOKEN}@$(echo -e ${GIT_ADDRESS} | cut -d/ -f3-)"
fi

if [ "$(ls -A /mnt/server)" ]; then
    echo -e "/mnt/server is not empty"
    if [ -d .git ]; then
        ORIGIN=$(git config --get remote.origin.url)
    fi
    if [ "${ORIGIN}" == "${GIT_ADDRESS}" ]; then
        echo -e "pulling latest from git"
        git pull
    fi
else
    echo -e "/mnt/server is empty, cloning repo"
    if [ -z "${BRANCH}" ]; then
        git clone ${GIT_ADDRESS} .
    else
        git clone --single-branch --branch ${BRANCH} ${GIT_ADDRESS} .
    fi
fi

if [ "${RUNTIME}" == "python" ]; then
    pip install --upgrade pip
    if [ -f "/mnt/server/${REQUIREMENTS_FILE}" ]; then
        echo "Installing requirements from ${REQUIREMENTS_FILE}"
        pip install --no-cache-dir -r "/mnt/server/${REQUIREMENTS_FILE}"
    fi
    if [[ ! -z ${PY_PACKAGES} ]]; then
        pip install --no-cache-dir ${PY_PACKAGES}
    fi
else
    echo "Installing npm packages"
    if [[ ! -z ${NODE_PACKAGES} ]]; then
        npm install ${NODE_PACKAGES}
    fi
    if [ -f /mnt/server/package.json ]; then
        npm install --production
    fi
fi

echo -e "install complete"
exit 0

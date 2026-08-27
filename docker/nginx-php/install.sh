#!/bin/bash
# WebHost (nginx+PHP-FPM) Installation Script (Waifly)
#
# Server Files: /mnt/server
apt update
apt install -y git curl unzip ca-certificates

cd /mnt/server

# Accept either an existing www/ (legacy layout, e.g. migrated from another nginx egg) or
# webroot/ (this egg's default for fresh installs). webroot wins if both somehow exist.
if [[ -d webroot ]]; then
    TARGET="webroot"
elif [[ -d www ]]; then
    TARGET="www"
else
    TARGET="webroot"
    mkdir -p webroot
fi

if [ "${USER_UPLOAD}" == "true" ] || [ "${USER_UPLOAD}" == "1" ]; then
    echo -e "USER_UPLOAD is set, skipping git clone. Upload your site into the ${TARGET}/ folder manually."
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

cd "${TARGET}"

if [ "$(ls -A .)" ]; then
    echo -e "${TARGET} is not empty"
    if [ -d .git ]; then
        ORIGIN=$(git config --get remote.origin.url)
    fi
    if [ "${ORIGIN}" == "${GIT_ADDRESS}" ]; then
        echo -e "pulling latest from git"
        git pull
    fi
else
    echo -e "${TARGET} is empty, cloning repo"
    if [ -z "${BRANCH}" ]; then
        git clone ${GIT_ADDRESS} .
    else
        git clone --single-branch --branch ${BRANCH} ${GIT_ADDRESS} .
    fi
fi

echo -e "install complete"
exit 0

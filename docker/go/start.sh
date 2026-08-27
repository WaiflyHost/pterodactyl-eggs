#!/bin/bash
cd /home/container || exit 1

if [[ -n "${STARTUP_CMD}" ]]; then
    echo -e ":/home/container$ ${STARTUP_CMD}"
    eval "${STARTUP_CMD}"
fi

if [[ -n "${SECOND_CMD}" ]]; then
    echo -e ":/home/container$ ${SECOND_CMD}"
    exec bash -c "${SECOND_CMD}"
fi

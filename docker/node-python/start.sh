#!/bin/bash
cd /home/container || exit 1

NODE_VERSION="${NODE_VERSION:-22}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12.7}"

# Node: prepend the chosen version's bin dir (symlinked at build time, see Dockerfile).
if [[ -d "/usr/local/nodeversions/${NODE_VERSION}/bin" ]]; then
    export PATH="/usr/local/nodeversions/${NODE_VERSION}/bin:${PATH}"
else
    echo "Unknown NODE_VERSION '${NODE_VERSION}', falling back to 22"
    export PATH="/usr/local/nodeversions/22/bin:${PATH}"
fi

# Python: pyenv resolves via this env var through its shims (already on PATH) - accepts either a
# short form ("3.12") or the exact installed patch ("3.12.7"); pyenv matches the latest installed
# patch for a short form automatically.
export PYENV_VERSION="${PYTHON_VERSION}"

if [[ -d .git ]] && [[ "${AUTO_UPDATE}" == "1" ]]; then git pull; fi

if [[ "${RUNTIME}" == "python" ]]; then
    if [[ ! -z ${PY_PACKAGES} ]]; then pip install --no-cache-dir --user ${PY_PACKAGES}; fi
    if [[ ! -z ${UNPY_PACKAGES} ]]; then pip uninstall -y ${UNPY_PACKAGES}; fi
    if [ -f "/home/container/${REQUIREMENTS_FILE}" ]; then pip install --no-cache-dir --user -r "/home/container/${REQUIREMENTS_FILE}"; fi
    exec python3 "/home/container/${PY_FILE}" ${PY_ARGS}
else
    if [[ ! -z ${NODE_PACKAGES} ]]; then npm install ${NODE_PACKAGES}; fi
    if [[ ! -z ${UNNODE_PACKAGES} ]]; then npm uninstall ${UNNODE_PACKAGES}; fi
    if [ -f /home/container/package.json ]; then npm install; fi
    if [[ "${MAIN_FILE}" == *.ts ]]; then
        exec ts-node --esm "/home/container/${MAIN_FILE}" ${NODE_ARGS}
    else
        exec node "/home/container/${MAIN_FILE}" ${NODE_ARGS}
    fi
fi

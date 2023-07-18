#!/bin/bash
# exit when any command fails
set -e

# Required to suppress some git errors further down the line
git config --global --add safe.directory /home/***

# Create required directory structure (if it does not already exist)
if [[ ! -d "$ARIUS_STATIC_ROOT" ]]; then
    echo "Creating directory $ARIUS_STATIC_ROOT"
    mkdir -p $ARIUS_STATIC_ROOT
fi

if [[ ! -d "$ARIUS_MEDIA_ROOT" ]]; then
    echo "Creating directory $ARIUS_MEDIA_ROOT"
    mkdir -p $ARIUS_MEDIA_ROOT
fi

if [[ ! -d "$ARIUS_BACKUP_DIR" ]]; then
    echo "Creating directory $ARIUS_BACKUP_DIR"
    mkdir -p $ARIUS_BACKUP_DIR
fi

# Check if "config.yaml" has been copied into the correct location
if test -f "$ARIUS_CONFIG_FILE"; then
    echo "Loading config file : $ARIUS_CONFIG_FILE"
else
    echo "Copying config file to $ARIUS_CONFIG_FILE"
    cp $ARIUS_HOME/Arius/config_template.yaml $ARIUS_CONFIG_FILE
fi

# Setup a python virtual environment
# This should be done on the *mounted* filesystem,
# so that the installed modules persist!
if [[ -n "$ARIUS_PY_ENV" ]]; then

    if test -d "$ARIUS_PY_ENV"; then
        # venv already exists
        echo "Using Python virtual environment: ${ARIUS_PY_ENV}"
    else
        # Setup a virtual environment (within the "data/env" directory)
        echo "Running first time setup for python environment"
        python3 -m venv ${ARIUS_PY_ENV} --system-site-packages --upgrade-deps
    fi

    # Now activate the venv
    source ${ARIUS_PY_ENV}/bin/activate
fi

cd ${ARIUS_HOME}

# Launch the CMD *after* the ENTRYPOINT completes
exec "$@"

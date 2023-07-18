#!/bin/bash
#
# packager.io postinstall script functions
#

function detect_docker() {
  if [ -n "$(grep docker </proc/1/cgroup)" ]; then
    DOCKER="yes"
  else
    DOCKER="no"
  fi
}

function detect_initcmd() {
  if [ -n "$(which systemctl 2>/dev/null)" ]; then
    INIT_CMD="systemctl"
  elif [ -n "$(which initctl 2>/dev/null)" ]; then
    INIT_CMD="initctl"
  else
    function sysvinit() {
      service $2 $1
    }
    INIT_CMD="sysvinit"
  fi

  if [ "${DOCKER}" == "yes" ]; then
    INIT_CMD="initctl"
  fi
}

function detect_ip() {
  # Get the IP address of the server

  if [ "${SETUP_NO_CALLS}" == "true" ]; then
    # Use local IP address
    echo "# Getting the IP address of the first local IP address"
    export ARIUS_IP=$(hostname -I | awk '{print $1}')
  else
    # Use web service to get the IP address
    echo "# Getting the IP address of the server via web service"
    export ARIUS_IP=$(curl -s https://checkip.amazonaws.com)
  fi

  echo "IP address is ${ARIUS_IP}"
}

function get_env() {
  envname=$1

  pid=$$
  while [ -z "${!envname}" -a $pid != 1 ]; do
      ppid=`ps -oppid -p$pid|tail -1|awk '{print $1}'`
      env=`strings /proc/$ppid/environ`
      export $envname=`echo "$env"|awk -F= '$1 == "'$envname'" { print $2; }'`
      pid=$ppid
  done

  if [ -n "${SETUP_DEBUG}" ]; then
    echo "Done getting env $envname: ${!envname}"
  fi
}

function detect_local_env() {
  # Get all possible envs for the install

  if [ -n "${SETUP_DEBUG}" ]; then
    echo "# Printing local envs - before #++#"
    printenv
  fi

  for i in ${SETUP_ENVS//,/ }
  do
      get_env $i
  done

  if [ -n "${SETUP_DEBUG}" ]; then
    echo "# Printing local envs - after #++#"
    printenv
  fi
}

function detect_envs() {
  # Detect all envs that should be passed to setup commands

  echo "# Setting base environment variables"

  export ARIUS_CONFIG_FILE=${ARIUS_CONFIG_FILE:-${CONF_DIR}/config.yaml}

  if test -f "${ARIUS_CONFIG_FILE}"; then
    echo "# Using existing config file: ${ARIUS_CONFIG_FILE}"

    # Install parser
    pip install jc -q

    # Load config
    local CONF=$(cat ${ARIUS_CONFIG_FILE} | jc --yaml)

    # Parse the config file
    export ARIUS_MEDIA_ROOT=$(jq -r '.[].media_root' <<< ${CONF})
    export ARIUS_STATIC_ROOT=$(jq -r '.[].static_root' <<< ${CONF})
    export ARIUS_BACKUP_DIR=$(jq -r '.[].backup_dir' <<< ${CONF})
    export ARIUS_PLUGINS_ENABLED=$(jq -r '.[].plugins_enabled' <<< ${CONF})
    export ARIUS_PLUGIN_FILE=$(jq -r '.[].plugin_file' <<< ${CONF})
    export ARIUS_SECRET_KEY_FILE=$(jq -r '.[].secret_key_file' <<< ${CONF})

    export ARIUS_DB_ENGINE=$(jq -r '.[].database.ENGINE' <<< ${CONF})
    export ARIUS_DB_NAME=$(jq -r '.[].database.NAME' <<< ${CONF})
    export ARIUS_DB_USER=$(jq -r '.[].database.USER' <<< ${CONF})
    export ARIUS_DB_PASSWORD=$(jq -r '.[].database.PASSWORD' <<< ${CONF})
    export ARIUS_DB_HOST=$(jq -r '.[].database.HOST' <<< ${CONF})
    export ARIUS_DB_PORT=$(jq -r '.[].database.PORT' <<< ${CONF})
  else
    echo "# No config file found: ${ARIUS_CONFIG_FILE}, using envs or defaults"

    if [ -n "${SETUP_DEBUG}" ]; then
      echo "# Print current envs"
      printenv | grep ARIUS_
      printenv | grep SETUP_
    fi

    export ARIUS_MEDIA_ROOT=${ARIUS_MEDIA_ROOT:-${DATA_DIR}/media}
    export ARIUS_STATIC_ROOT=${DATA_DIR}/static
    export ARIUS_BACKUP_DIR=${DATA_DIR}/backup
    export ARIUS_PLUGINS_ENABLED=true
    export ARIUS_PLUGIN_FILE=${CONF_DIR}/plugins.txt
    export ARIUS_SECRET_KEY_FILE=${CONF_DIR}/secret_key.txt

    export ARIUS_DB_ENGINE=${ARIUS_DB_ENGINE:-sqlite3}
    export ARIUS_DB_NAME=${ARIUS_DB_NAME:-${DATA_DIR}/database.sqlite3}
    export ARIUS_DB_USER=${ARIUS_DB_USER:-sampleuser}
    export ARIUS_DB_PASSWORD=${ARIUS_DB_PASSWORD:-samplepassword}
    export ARIUS_DB_HOST=${ARIUS_DB_HOST:-samplehost}
    export ARIUS_DB_PORT=${ARIUS_DB_PORT:-123456}

    export SETUP_CONF_LOADED=true
  fi

  # For debugging pass out the envs
  echo "# Collected environment variables:"
  echo "#    ARIUS_MEDIA_ROOT=${ARIUS_MEDIA_ROOT}"
  echo "#    ARIUS_STATIC_ROOT=${ARIUS_STATIC_ROOT}"
  echo "#    ARIUS_BACKUP_DIR=${ARIUS_BACKUP_DIR}"
  echo "#    ARIUS_PLUGINS_ENABLED=${ARIUS_PLUGINS_ENABLED}"
  echo "#    ARIUS_PLUGIN_FILE=${ARIUS_PLUGIN_FILE}"
  echo "#    ARIUS_SECRET_KEY_FILE=${ARIUS_SECRET_KEY_FILE}"
  echo "#    ARIUS_DB_ENGINE=${ARIUS_DB_ENGINE}"
  echo "#    ARIUS_DB_NAME=${ARIUS_DB_NAME}"
  echo "#    ARIUS_DB_USER=${ARIUS_DB_USER}"
  if [ -n "${SETUP_DEBUG}" ]; then
    echo "#    ARIUS_DB_PASSWORD=${ARIUS_DB_PASSWORD}"
  fi
  echo "#    ARIUS_DB_HOST=${ARIUS_DB_HOST}"
  echo "#    ARIUS_DB_PORT=${ARIUS_DB_PORT}"
}

function create_initscripts() {

  # Make sure python env exists
  if test -f "${APP_HOME}/env"; then
    echo "# python environment already present - skipping"
  else
    echo "# Setting up python environment"
    sudo -u ${APP_USER} --preserve-env=$SETUP_ENVS bash -c "cd ${APP_HOME} && ${SETUP_PYTHON} -m venv env"
    sudo -u ${APP_USER} --preserve-env=$SETUP_ENVS bash -c "cd ${APP_HOME} && env/bin/pip install invoke wheel"

    if [ -n "${SETUP_EXTRA_PIP}" ]; then
      echo "# Installing extra pip packages"
      if [ -n "${SETUP_DEBUG}" ]; then
        echo "# Extra pip packages: ${SETUP_EXTRA_PIP}"
      fi
      sudo -u ${APP_USER} --preserve-env=$SETUP_ENVS bash -c "cd ${APP_HOME} && env/bin/pip install ${SETUP_EXTRA_PIP}"
    fi
  fi

  # Unlink default config if it exists
  if test -f "/etc/nginx/sites-enabled/default"; then
    echo "# Unlinking default nginx config\n# Old file still in /etc/nginx/sites-available/default"
    sudo unlink /etc/nginx/sites-enabled/default
  fi

  # Create arius specific nginx config
  echo "# Stopping nginx"
  ${INIT_CMD} stop nginx
  echo "# Setting up nginx to ${SETUP_NGINX_FILE}"
  # Always use the latest nginx config; important if new headers are added / needed for security
  cp ${APP_HOME}/docker/production/nginx.prod.conf ${SETUP_NGINX_FILE}
  sed -i s/arius-server:8000/localhost:6000/g ${SETUP_NGINX_FILE}
  sed -i s=var/www=opt/arius/data=g ${SETUP_NGINX_FILE}
  # Start nginx
  echo "# Starting nginx"
  ${INIT_CMD} start nginx

  echo "# (Re)creating init scripts"
  # This resets scale parameters to a known state
  arius scale web="1" worker="1"

  echo "# Enabling Arius on boot"
  ${INIT_CMD} enable arius
}

function create_admin() {
  # Create data for admin user

  if test -f "${SETUP_ADMIN_PASSWORD_FILE}"; then
    echo "# Admin data already exists - skipping"
  else
    echo "# Creating admin user data"

    # Static admin data
    export ARIUS_ADMIN_USER=${ARIUS_ADMIN_USER:-admin}
    export ARIUS_ADMIN_EMAIL=${ARIUS_ADMIN_EMAIL:-admin@example.com}

    # Create password if not set
    if [ -z "${ARIUS_ADMIN_PASSWORD}" ]; then
      openssl rand -base64 32 >${SETUP_ADMIN_PASSWORD_FILE}
      export ARIUS_ADMIN_PASSWORD=$(cat ${SETUP_ADMIN_PASSWORD_FILE})
    fi
  fi
}

function start_arius() {
  echo "# Starting Arius"
  ${INIT_CMD} start arius
}

function stop_arius() {
  echo "# Stopping Arius"
  ${INIT_CMD} stop arius
}

function update_or_install() {

  # Set permissions so app user can write there
  chown ${APP_USER}:${APP_GROUP} ${APP_HOME} -R

  # Run update as app user
  echo "# Updating Arius"
  sudo -u ${APP_USER} --preserve-env=$SETUP_ENVS bash -c "cd ${APP_HOME} && invoke update | sed -e 's/^/# inv update| /;'"

  # Make sure permissions are correct again
  echo "# Set permissions for data dir and media: ${DATA_DIR}"
  chown ${APP_USER}:${APP_GROUP} ${DATA_DIR} -R
  chown ${APP_USER}:${APP_GROUP} ${CONF_DIR} -R
}

function set_env() {
  echo "# Setting up Arius config values"

  arius config:set ARIUS_CONFIG_FILE=${ARIUS_CONFIG_FILE}

  # Changing the config file
  echo "# Writing the settings to the config file ${ARIUS_CONFIG_FILE}"
  # Media Root
  sed -i s=#media_root:\ \'/home/arius/data/media\'=media_root:\ \'${ARIUS_MEDIA_ROOT}\'=g ${ARIUS_CONFIG_FILE}
  # Static Root
  sed -i s=#static_root:\ \'/home/arius/data/static\'=static_root:\ \'${ARIUS_STATIC_ROOT}\'=g ${ARIUS_CONFIG_FILE}
  # Backup dir
  sed -i s=#backup_dir:\ \'/home/arius/data/backup\'=backup_dir:\ \'${ARIUS_BACKUP_DIR}\'=g ${ARIUS_CONFIG_FILE}
  # Plugins enabled
  sed -i s=plugins_enabled:\ False=plugins_enabled:\ ${ARIUS_PLUGINS_ENABLED}=g ${ARIUS_CONFIG_FILE}
  # Plugin file
  sed -i s=#plugin_file:\ \'/path/to/plugins.txt\'=plugin_file:\ \'${ARIUS_PLUGIN_FILE}\'=g ${ARIUS_CONFIG_FILE}
  # Secret key file
  sed -i s=#secret_key_file:\ \'/etc/arius/secret_key.txt\'=secret_key_file:\ \'${ARIUS_SECRET_KEY_FILE}\'=g ${ARIUS_CONFIG_FILE}
  # Debug mode
  sed -i s=debug:\ True=debug:\ False=g ${ARIUS_CONFIG_FILE}

  # Database engine
  sed -i s=#ENGINE:\ sampleengine=ENGINE:\ ${ARIUS_DB_ENGINE}=g ${ARIUS_CONFIG_FILE}
  # Database name
  sed -i s=#NAME:\ \'/path/to/database\'=NAME:\ \'${ARIUS_DB_NAME}\'=g ${ARIUS_CONFIG_FILE}
  # Database user
  sed -i s=#USER:\ sampleuser=USER:\ ${ARIUS_DB_USER}=g ${ARIUS_CONFIG_FILE}
  # Database password
  sed -i s=#PASSWORD:\ samplepassword=PASSWORD:\ ${ARIUS_DB_PASSWORD}=g ${ARIUS_CONFIG_FILE}
  # Database host
  sed -i s=#HOST:\ samplehost=HOST:\ ${ARIUS_DB_HOST}=g ${ARIUS_CONFIG_FILE}
  # Database port
  sed -i s=#PORT:\ 123456=PORT:\ ${ARIUS_DB_PORT}=g ${ARIUS_CONFIG_FILE}

  # Fixing the permissions
  chown ${APP_USER}:${APP_GROUP} ${DATA_DIR} ${ARIUS_CONFIG_FILE}
}

function final_message() {
  echo -e "####################################################################################"
  echo -e "This Arius install uses nginx, the settings for the webserver can be found in"
  echo -e "${SETUP_NGINX_FILE}"
  echo -e "Try opening Arius with either\nhttp://localhost/ or http://${ARIUS_IP}/\n"
  echo -e "Admin user data:"
  echo -e "   Email: ${ARIUS_ADMIN_EMAIL}"
  echo -e "   Username: ${ARIUS_ADMIN_USER}"
  echo -e "   Password: ${ARIUS_ADMIN_PASSWORD}"
  echo -e "####################################################################################"
}

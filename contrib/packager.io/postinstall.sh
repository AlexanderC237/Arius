#!/bin/bash
#
# packager.io postinstall script
#

exec > >(tee ${APP_HOME}/log/setup_$(date +"%F_%H_%M_%S").log) 2>&1

PATH=${APP_HOME}/env/bin:${APP_HOME}/:/sbin:/bin:/usr/sbin:/usr/bin:

# import functions
. ${APP_HOME}/contrib/packager.io/functions.sh

# Envs that should be passed to setup commands
export SETUP_ENVS=PATH,APP_HOME,ARIUS_MEDIA_ROOT,ARIUS_STATIC_ROOT,ARIUS_BACKUP_DIR,ARIUS_PLUGINS_ENABLED,ARIUS_PLUGIN_FILE,ARIUS_CONFIG_FILE,ARIUS_SECRET_KEY_FILE,ARIUS_DB_ENGINE,ARIUS_DB_NAME,ARIUS_DB_USER,ARIUS_DB_PASSWORD,ARIUS_DB_HOST,ARIUS_DB_PORT,ARIUS_ADMIN_USER,ARIUS_ADMIN_EMAIL,ARIUS_ADMIN_PASSWORD,SETUP_NGINX_FILE,SETUP_ADMIN_PASSWORD_FILE,SETUP_NO_CALLS,SETUP_DEBUG,SETUP_EXTRA_PIP,SETUP_PYTHON

# Get the envs
detect_local_env

# default config
export CONF_DIR=/etc/arius
export DATA_DIR=${APP_HOME}/data
# Setup variables
export SETUP_NGINX_FILE=${SETUP_NGINX_FILE:-/etc/nginx/sites-enabled/arius.conf}
export SETUP_ADMIN_PASSWORD_FILE=${CONF_DIR}/admin_password.txt
export SETUP_NO_CALLS=${SETUP_NO_CALLS:-false}
export SETUP_PYTHON=${SETUP_PYTHON:-python3}
# SETUP_DEBUG can be set to get debug info
# SETUP_EXTRA_PIP can be set to install extra pip packages
# SETUP_PYTHON can be set to use a different python version

# get base info
detect_envs
detect_docker
detect_initcmd
detect_ip

# create processes
create_initscripts
create_admin

# run updates
stop_arius
update_or_install
# Write config file
if [ "${SETUP_CONF_LOADED}" = "true" ]; then
  set_env
fi
start_arius

# show info
final_message

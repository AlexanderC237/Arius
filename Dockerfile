# The arius dockerfile provides two build targets:
#
# production:
# - Required files are copied into the image
# - Runs arius web server under gunicorn
#
# dev:
# - Expects source directories to be loaded as a run-time volume
# - Runs arius web server under django development server
# - Monitors source files for any changes, and live-reloads server

FROM python:3.9-slim as arius_base

# Build arguments for this image
ARG commit_hash=""
ARG commit_date=""
ARG commit_tag=""

ENV PYTHONUNBUFFERED 1

ENV ARIUS_LOG_LEVEL="WARNING"
ENV ARIUS_DOCKER="true"

# arius paths
ENV ARIUS_HOME="/home/arius"
ENV ARIUS_MNG_DIR="${ARIUS_HOME}/Arius"
ENV ARIUS_DATA_DIR="${ARIUS_HOME}/data"
ENV ARIUS_STATIC_ROOT="${ARIUS_DATA_DIR}/static"
ENV ARIUS_MEDIA_ROOT="${ARIUS_DATA_DIR}/media"
ENV ARIUS_BACKUP_DIR="${ARIUS_DATA_DIR}/backup"
ENV ARIUS_PLUGIN_DIR="${ARIUS_DATA_DIR}/plugins"

# arius configuration files
ENV ARIUS_CONFIG_FILE="${ARIUS_DATA_DIR}/config.yaml"
ENV ARIUS_SECRET_KEY_FILE="${ARIUS_DATA_DIR}/secret_key.txt"
ENV ARIUS_PLUGIN_FILE="${ARIUS_DATA_DIR}/plugins.txt"

# Worker configuration (can be altered by user)
ENV ARIUS_GUNICORN_WORKERS="4"
ENV ARIUS_BACKGROUND_WORKERS="4"

# Default web server address:port
ENV ARIUS_WEB_ADDR=0.0.0.0
ENV ARIUS_WEB_PORT=8000

LABEL org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=${DATE} \
    org.label-schema.vendor="arius" \
    org.label-schema.name="arius/arius" \
    org.label-schema.url="https://hub.docker.com/r/arius/arius" \
    org.label-schema.vcs-url="https://github.com/ariustechnology/Arius.git" \
    org.label-schema.vcs-ref=${commit_tag}

# RUN apt-get upgrade && apt-get update
RUN apt-get update

# Install required system packages
RUN apt-get install -y  --no-install-recommends \
    git gcc g++ gettext gnupg libffi-dev libssl-dev \
    # Weasyprint requirements : https://doc.courtbouillon.org/weasyprint/stable/first_steps.html#debian-11
    poppler-utils libpango-1.0-0 libpangoft2-1.0-0 \
    # Image format support
    libjpeg-dev webp libwebp-dev \
    # SQLite support
    sqlite3 \
    # PostgreSQL support
    libpq-dev postgresql-client \
    # MySQL / MariaDB support
    default-libmysqlclient-dev mariadb-client && \
    apt-get autoclean && apt-get autoremove

# Update pip
RUN pip install --upgrade pip

# For ARMv7 architecture, add the pinwheels repo (for cryptography library)
# Otherwise, we have to build from source, which is difficult
# Ref: https://github.com/ariustechnology/Arius/pull/4598
RUN \
    if [ `dpkg --print-architecture` = "armhf" ]; then \
    printf "[global]\nextra-index-url=https://www.piwheels.org/simple\n" > /etc/pip.conf ; \
    fi

# Install required base-level python packages
COPY ./docker/requirements.txt base_requirements.txt
RUN pip install --disable-pip-version-check -U -r base_requirements.txt

# arius production image:
# - Copies required files from local directory
# - Installs required python packages from requirements.txt
# - Starts a gunicorn webserver

FROM arius_base as production

ENV ARIUS_DEBUG=False

# As .git directory is not available in production image, we pass the commit information via ENV
ENV ARIUS_COMMIT_HASH="${commit_hash}"
ENV ARIUS_COMMIT_DATE="${commit_date}"

# Copy source code
COPY arius ${ARIUS_HOME}/Arius

# Copy other key files
COPY requirements.txt ${ARIUS_HOME}/requirements.txt
COPY tasks.py ${ARIUS_HOME}/tasks.py
COPY docker/gunicorn.conf.py ${ARIUS_HOME}/gunicorn.conf.py
COPY docker/init.sh ${ARIUS_MNG_DIR}/init.sh

# Need to be running from within this directory
WORKDIR ${ARIUS_MNG_DIR}

# Drop to the arius user for the production image
#RUN adduser arius
#RUN chown -R arius:arius ${ARIUS_HOME}
#USER arius

# Install arius packages
RUN pip3 install --user --disable-pip-version-check -r ${ARIUS_HOME}/requirements.txt

# Server init entrypoint
ENTRYPOINT ["/bin/bash", "./init.sh"]

# Launch the production server
# TODO: Work out why environment variables cannot be interpolated in this command
# TODO: e.g. -b ${ARIUS_WEB_ADDR}:${ARIUS_WEB_PORT} fails here
CMD gunicorn -c ./gunicorn.conf.py Arius.wsgi -b 0.0.0.0:8000 --chdir ./Arius

FROM arius_base as dev

# The development image requires the source code to be mounted to /home/arius/
# So from here, we don't actually "do" anything, apart from some file management

ENV ARIUS_DEBUG=True

# Location for python virtual environment
# If the ARIUS_PY_ENV variable is set, the entrypoint script will use it!
ENV ARIUS_PY_ENV="${ARIUS_DATA_DIR}/env"

WORKDIR ${ARIUS_HOME}

# Entrypoint ensures that we are running in the python virtual environment
ENTRYPOINT ["/bin/bash", "./docker/init.sh"]

# Launch the development server
CMD ["invoke", "server", "-a", "${ARIUS_WEB_ADDR}:${ARIUS_WEB_PORT}"]

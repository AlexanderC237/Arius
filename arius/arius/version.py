"""Version information for arius.

Provides information on the current arius version
"""

import os
import pathlib
import platform
import re
from datetime import datetime as dt
from datetime import timedelta as td

import django
from django.conf import settings

from dulwich.repo import NotGitRepository, Repo

from .api_version import ARIUS_API_VERSION

# arius software version
ARIUS_SW_VERSION = "0.13.0 dev"

# Discover git
try:
    main_repo = Repo(pathlib.Path(__file__).parent.parent.parent)
    main_commit = main_repo[main_repo.head()]
except (NotGitRepository, FileNotFoundError):
    main_commit = None


def ariusInstanceName():
    """Returns the InstanceName settings for the current database."""
    import common.models

    return common.models.AriusSetting.get_setting("ARIUS_INSTANCE", "")


def ariusInstanceTitle():
    """Returns the InstanceTitle for the current database."""
    import common.models

    if common.models.AriusSetting.get_setting("ARIUS_INSTANCE_TITLE", False):
        return common.models.AriusSetting.get_setting("ARIUS_INSTANCE", "")
    else:
        return 'arius'


def ariusVersion():
    """Returns the arius version string."""
    return ARIUS_SW_VERSION.lower().strip()


def ariusVersionTuple(version=None):
    """Return the arius version string as (maj, min, sub) tuple."""
    if version is None:
        version = ARIUS_SW_VERSION

    match = re.match(r"^.*(\d+)\.(\d+)\.(\d+).*$", str(version))

    return [int(g) for g in match.groups()]


def isAriusDevelopmentVersion():
    """Return True if current arius version is a "development" version."""
    return ariusVersion().endswith('dev')


def ariusDocsVersion():
    """Return the version string matching the latest documentation.

    Development -> "latest"
    Release -> "major.minor.sub" e.g. "0.5.2"
    """
    if isAriusDevelopmentVersion():
        return "latest"
    else:
        return ARIUS_SW_VERSION  # pragma: no cover


def isAriusUpToDate():
    """Test if the arius instance is "up to date" with the latest version.

    A background task periodically queries GitHub for latest version, and stores it to the database as "_ARIUS_LATEST_VERSION"
    """
    import common.models
    latest = common.models.AriusSetting.get_setting('_ARIUS_LATEST_VERSION', backup_value=None, create=False)

    # No record for "latest" version - we must assume we are up to date!
    if not latest:
        return True

    # Extract "tuple" version (Python can directly compare version tuples)
    latest_version = ariusVersionTuple(latest)  # pragma: no cover
    arius_version = ariusVersionTuple()  # pragma: no cover

    return arius_version >= latest_version  # pragma: no cover


def ariusApiVersion():
    """Returns current API version of arius."""
    return ARIUS_API_VERSION


def ariusDjangoVersion():
    """Returns the version of Django library."""
    return django.get_version()


def ariusCommitHash():
    """Returns the git commit hash for the running codebase."""
    # First look in the environment variables, i.e. if running in docker
    commit_hash = os.environ.get('ARIUS_COMMIT_HASH', '')

    if commit_hash:
        return commit_hash

    if main_commit is None:
        return None
    return main_commit.sha().hexdigest()[0:7]


def ariusCommitDate():
    """Returns the git commit date for the running codebase."""
    # First look in the environment variables, e.g. if running in docker
    commit_date = os.environ.get('ARIUS_COMMIT_DATE', '')

    if commit_date:
        return commit_date.split(' ')[0]

    if main_commit is None:
        return None

    commit_dt = dt.fromtimestamp(main_commit.commit_time) + td(seconds=main_commit.commit_timezone)
    return str(commit_dt.date())


def ariusInstaller():
    """Returns the installer for the running codebase - if set."""
    # First look in the environment variables, e.g. if running in docker

    installer = os.environ.get('ARIUS_PKG_INSTALLER', '')

    if installer:
        return installer
    elif settings.DOCKER:
        return 'DOC'
    elif main_commit is not None:
        return 'GIT'

    return None


def ariusBranch():
    """Returns the branch for the running codebase - if set."""
    # First look in the environment variables, e.g. if running in docker

    branch = os.environ.get('ARIUS_PKG_BRANCH', '')

    if branch:
        return branch

    if main_commit is None:
        return None

    branch = main_repo.refs.follow(b'HEAD')[0][1].decode()
    return branch.removeprefix('refs/heads/')


def ariusTarget():
    """Returns the target platform for the running codebase - if set."""
    # First look in the environment variables, e.g. if running in docker

    return os.environ.get('ARIUS_PKG_TARGET', None)


def ariusPlatform():
    """Returns the platform for the instance."""

    return platform.platform(aliased=True)

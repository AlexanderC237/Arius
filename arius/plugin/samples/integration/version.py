"""Sample plugin for versioning."""
from plugin import AriusPlugin


class VersionPlugin(AriusPlugin):
    """A small version sample."""

    NAME = "version"
    MAX_VERSION = '0.1.0'

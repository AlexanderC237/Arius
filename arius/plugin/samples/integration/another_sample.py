"""Sample implementation for IntegrationPlugin."""
from plugin import AriusPlugin
from plugin.mixins import UrlsMixin


class NoIntegrationPlugin(AriusPlugin):
    """A basic plugin."""

    NAME = "NoIntegrationPlugin"


class WrongIntegrationPlugin(UrlsMixin, AriusPlugin):
    """A basic wrong plugin with urls."""

    NAME = "WrongIntegrationPlugin"

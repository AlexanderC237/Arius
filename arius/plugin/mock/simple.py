"""Very simple sample plugin"""

from plugin import AriusPlugin


class SimplePlugin(AriusPlugin):
    """A very simple plugin."""

    NAME = 'SimplePlugin'
    SLUG = "simple"

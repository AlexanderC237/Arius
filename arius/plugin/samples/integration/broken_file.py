"""Sample of a broken python file that will be ignored on import."""

from plugin import AriusPlugin


class BrokenFileIntegrationPlugin(AriusPlugin):
    """An very broken plugin."""


aaa = bb  # noqa: F821

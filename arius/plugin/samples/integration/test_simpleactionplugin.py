"""Unit tests for action plugins."""

from arius.unit_test import AriusTestCase
from plugin.samples.integration.simpleactionplugin import SimpleActionPlugin


class SimpleActionPluginTests(AriusTestCase):
    """Tests for SampleIntegrationPlugin."""

    def setUp(self):
        """Setup for tests."""
        super().setUp()

        self.plugin = SimpleActionPlugin()

    def test_name(self):
        """Check plugn names."""
        self.assertEqual(self.plugin.plugin_name(), "SimpleActionPlugin")
        self.assertEqual(self.plugin.action_name(), "simple")

    def test_function(self):
        """Check if functions work."""
        # test functions
        response = self.client.post('/api/action/', data={'action': "simple", 'data': {'foo': "bar", }})
        self.assertEqual(response.status_code, 200)
        self.assertJSONEqual(
            str(response.content, encoding='utf8'),
            {
                "action": 'simple',
                "result": True,
                "info": {
                    "user": self.username,
                    "hello": "world",
                },
            }
        )

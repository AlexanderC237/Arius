"""Unit tests for action plugins."""

from arius.unit_test import AriusTestCase


class SampleIntegrationPluginTests(AriusTestCase):
    """Tests for SampleIntegrationPlugin."""

    def test_view(self):
        """Check the function of the custom  sample plugin."""
        response = self.client.get('/plugin/sample/ho/he/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.content, b'Hi there testuser this works')

"""Custom management command to cleanup old settings that are not defined anymore."""

import logging

from django.core.management.base import BaseCommand

logger = logging.getLogger('arius')


class Command(BaseCommand):
    """Cleanup old (undefined) settings in the database."""

    def handle(self, *args, **kwargs):
        """Cleanup old (undefined) settings in the database."""
        logger.info("Collecting settings")
        from common.models import AriusSetting, AriusUserSetting

        # general settings
        db_settings = AriusSetting.objects.all()
        model_settings = AriusSetting.SETTINGS

        # check if key exist and delete if not
        for setting in db_settings:
            if setting.key not in model_settings:
                setting.delete()
                logger.info(f"deleted setting '{setting.key}'")

        # user settings
        db_settings = AriusUserSetting.objects.all()
        model_settings = AriusUserSetting.SETTINGS

        # check if key exist and delete if not
        for setting in db_settings:
            if setting.key not in model_settings:
                setting.delete()
                logger.info(f"deleted user setting '{setting.key}'")

        logger.info("checked all settings")

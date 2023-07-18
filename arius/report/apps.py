"""Config options for the 'report' app"""

import logging
import os
import shutil
from pathlib import Path

from django.apps import AppConfig
from django.conf import settings

logger = logging.getLogger("arius")


class ReportConfig(AppConfig):
    """Configuration class for the 'report' app"""
    name = 'report'

    def ready(self):
        """This function is called whenever the report app is loaded."""

        from arius.ready import canAppAccessDatabase

        # Configure logging for PDF generation (disable "info" messages)
        logging.getLogger('fontTools').setLevel(logging.WARNING)
        logging.getLogger('weasyprint').setLevel(logging.WARNING)

        # Create entries for default report templates
        if canAppAccessDatabase(allow_test=False):
            self.create_default_test_reports()
            self.create_default_build_reports()
            self.create_default_bill_of_materials_reports()
            self.create_default_purchase_order_reports()
            self.create_default_sales_order_reports()
            self.create_default_return_order_reports()

    def create_default_reports(self, model, reports):
        """Copy default report files across to the media directory."""
        # Source directory for report templates
        src_dir = Path(__file__).parent.joinpath(
            'templates',
            'report',
        )

        # Destination directory
        dst_dir = settings.MEDIA_ROOT.joinpath(
            'report',
            'arius',
            model.getSubdir(),
        )

        if not dst_dir.exists():
            logger.info(f"Creating missing directory: '{dst_dir}'")
            dst_dir.mkdir(parents=True, exist_ok=True)

        # Copy each report template across (if required)
        for report in reports:

            # Destination filename
            filename = os.path.join(
                'report',
                'arius',
                model.getSubdir(),
                report['file'],
            )

            src_file = src_dir.joinpath(report['file'])
            dst_file = settings.MEDIA_ROOT.joinpath(filename)

            if not dst_file.exists():
                logger.info(f"Copying test report template '{dst_file}'")
                shutil.copyfile(src_file, dst_file)

            try:
                # Check if a report matching the template already exists
                if model.objects.filter(template=filename).exists():
                    continue

                logger.info(f"Creating new TestReport for '{report['name']}'")

                model.objects.create(
                    name=report['name'],
                    description=report['description'],
                    template=filename,
                    enabled=True
                )

            except Exception:
                pass

    def create_default_test_reports(self):
        """Create database entries for the default TestReport templates, if they do not already exist."""
        try:
            from .models import TestReport
        except Exception:  # pragma: no cover
            # Database is not ready yet
            return

        # List of test reports to copy across
        reports = [
            {
                'file': 'arius_test_report.html',
                'name': 'arius Test Report',
                'description': 'Stock item test report',
            },
        ]

        self.create_default_reports(TestReport, reports)

    def create_default_bill_of_materials_reports(self):
        """Create database entries for the default Bill of Material templates (if they do not already exist)"""
        try:
            from .models import BillOfMaterialsReport
        except Exception:  # pragma: no cover
            # Database is not ready yet
            return

        # List of Build reports to copy across
        reports = [
            {
                'file': 'arius_bill_of_materials_report.html',
                'name': 'Bill of Materials',
                'description': 'Bill of Materials report',
            }
        ]

        self.create_default_reports(BillOfMaterialsReport, reports)

    def create_default_build_reports(self):
        """Create database entries for the default BuildReport templates (if they do not already exist)"""
        try:
            from .models import BuildReport
        except Exception:  # pragma: no cover
            # Database is not ready yet
            return

        # List of Build reports to copy across
        reports = [
            {
                'file': 'arius_build_order.html',
                'name': 'arius Build Order',
                'description': 'Build Order job sheet',
            }
        ]

        self.create_default_reports(BuildReport, reports)

    def create_default_purchase_order_reports(self):
        """Create database entries for the default SalesOrderReport templates (if they do not already exist)"""
        try:
            from .models import PurchaseOrderReport
        except Exception:  # pragma: no cover
            # Database is not ready yet
            return

        # List of Build reports to copy across
        reports = [
            {
                'file': 'arius_po_report.html',
                'name': 'arius Purchase Order',
                'description': 'Purchase Order example report',
            }
        ]

        self.create_default_reports(PurchaseOrderReport, reports)

    def create_default_sales_order_reports(self):
        """Create database entries for the default Sales Order report templates (if they do not already exist)"""
        try:
            from .models import SalesOrderReport
        except Exception:  # pragma: no cover
            # Database is not ready yet
            return

        # List of Build reports to copy across
        reports = [
            {
                'file': 'arius_so_report.html',
                'name': 'arius Sales Order',
                'description': 'Sales Order example report',
            }
        ]

        self.create_default_reports(SalesOrderReport, reports)

    def create_default_return_order_reports(self):
        """Create database entries for the default ReturnOrderReport templates"""

        try:
            from report.models import ReturnOrderReport
        except Exception:  # pragma: no cover
            # Database not yet ready
            return

        # List of templates to copy across
        reports = [
            {
                'file': 'arius_return_order_report.html',
                'name': 'arius Return Order',
                'description': 'Return Order example report',
            }
        ]

        self.create_default_reports(ReturnOrderReport, reports)

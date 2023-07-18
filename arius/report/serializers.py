"""API serializers for the reporting models"""

from arius.serializers import (AriusAttachmentSerializerField,
                               AriusModelSerializer)

from .models import (BillOfMaterialsReport, BuildReport, PurchaseOrderReport,
                     ReturnOrderReport, SalesOrderReport, TestReport)


class ReportSerializerBase(AriusModelSerializer):
    """Base class for report serializer"""

    template = AriusAttachmentSerializerField(required=True)

    @staticmethod
    def report_fields():
        """Generic serializer fields for a report template"""

        return [
            'pk',
            'name',
            'description',
            'template',
            'filters',
            'enabled',
        ]


class TestReportSerializer(ReportSerializerBase):
    """Serializer class for the TestReport model"""

    class Meta:
        """Metaclass options."""

        model = TestReport
        fields = ReportSerializerBase.report_fields()


class BuildReportSerializer(ReportSerializerBase):
    """Serializer class for the BuildReport model"""

    class Meta:
        """Metaclass options."""

        model = BuildReport
        fields = ReportSerializerBase.report_fields()


class BOMReportSerializer(ReportSerializerBase):
    """Serializer class for the BillOfMaterialsReport model"""

    class Meta:
        """Metaclass options."""

        model = BillOfMaterialsReport
        fields = ReportSerializerBase.report_fields()


class PurchaseOrderReportSerializer(ReportSerializerBase):
    """Serializer class for the PurchaseOrdeReport model"""

    class Meta:
        """Metaclass options."""

        model = PurchaseOrderReport
        fields = ReportSerializerBase.report_fields()


class SalesOrderReportSerializer(ReportSerializerBase):
    """Serializer class for the SalesOrderReport model"""

    class Meta:
        """Metaclass options."""

        model = SalesOrderReport
        fields = ReportSerializerBase.report_fields()


class ReturnOrderReportSerializer(ReportSerializerBase):
    """Serializer class for the ReturnOrderReport model"""

    class Meta:
        """Metaclass options"""

        model = ReturnOrderReport
        fields = ReportSerializerBase.report_fields()

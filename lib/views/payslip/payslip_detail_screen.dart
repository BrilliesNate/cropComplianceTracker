import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/models/payslip_model.dart';
import 'package:cropCompliance/providers/payslip_provider.dart';
import 'package:cropCompliance/views/payslip/utils/payslip_pdf_builder.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PayslipDetailScreen extends StatelessWidget {
  final String payslipId;

  const PayslipDetailScreen({Key? key, required this.payslipId})
      : super(key: key);

  static final _currency =
      NumberFormat.currency(locale: 'en_ZA', symbol: 'R ', decimalDigits: 2);
  static final _dateFormat = DateFormat('d MMM yyyy');
  static final _shortDate = DateFormat('d-MMM-yyyy');

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PayslipProvider>(context);
    final payslip = provider.getPayslipById(payslipId);

    if (payslip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payslip')),
        body: const Center(child: Text('Payslip not found')),
      );
    }

    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payslip',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text(payslip.employeeName,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Colors.white),
            tooltip: 'Print / Save PDF',
            onPressed: () => _printPayslip(context, payslip),
          ),
          if (!payslip.isFinalised)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Edit',
              onPressed: () => _edit(context, payslip),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Delete',
            onPressed: () => _delete(context, provider, payslip),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPayslipDocument(context, payslip, primaryColor),
            const SizedBox(height: 16),
            _buildStatusBanner(payslip),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context, PayslipModel p) {
    Navigator.of(context).pushNamed(
      RouteConstants.payslipForm,
      arguments: {
        'payslipId': p.id,
        'companyId': p.companyId,
        'companyName': p.companyName,
      },
    );
  }

  Future<void> _delete(
      BuildContext context, PayslipProvider provider, PayslipModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Payslip'),
        content: Text('Delete this payslip for ${p.employeeName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await provider.deletePayslip(p.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  // ── Payslip document ──────────────────────────────────────────────────────

  Widget _buildPayslipDocument(
      BuildContext context, PayslipModel p, Color primaryColor) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDocHeader(p, primaryColor),
          isMobile
              ? _buildMobileBody(p, primaryColor)
              : _buildDesktopBody(p, primaryColor),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildDocHeader(PayslipModel p, Color primaryColor) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(p.companyName.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('SALARIS STROKIE',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: primaryColor),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }

  // ── Desktop (two-column) ──────────────────────────────────────────────────

  Widget _buildDesktopBody(PayslipModel p, Color primaryColor) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildLeftColumn(p, primaryColor)),
          Container(width: 1, color: Colors.grey.shade300),
          Expanded(child: _buildRightColumn(p, primaryColor)),
        ],
      ),
    );
  }

  // ── Mobile (stacked) ─────────────────────────────────────────────────────

  Widget _buildMobileBody(PayslipModel p, Color primaryColor) {
    return Column(
      children: [
        _buildLeftColumn(p, primaryColor),
        Divider(color: Colors.grey.shade300, height: 1),
        _buildRightColumn(p, primaryColor),
      ],
    );
  }

  // ── Left column ───────────────────────────────────────────────────────────

  Widget _buildLeftColumn(PayslipModel p, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('PERSOONLIKE BESONDERHEDE', primaryColor),
          _detailRow('Naam', p.employeeName),
          _detailRow('ID Nommer', p.employeeIdNumber),
          _detailRow('Periode Begin', _shortDate.format(p.payPeriodStart)),
          _detailRow('Periode Einde', _shortDate.format(p.payPeriodEnd)),
          const SizedBox(height: 20),
          _sectionHeader('VERDIENSTE', primaryColor),
          _rateRow('Uurlikse Loon', p.normalRate),
          if (p.overtimeHours > 0) _rateRow('Oortyd Loon', p.overtimeRate),
          if (p.doubleTimeHours > 0)
            _rateRow('Dubbel Tyd Loon', p.doubleTimeRate),
          const SizedBox(height: 8),
          _hoursRow('Normale Loon', p.normalHours, p.normalPay),
          if (p.overtimePay > 0)
            _hoursRow('Oortyd Loon', p.overtimeHours, p.overtimePay),
          if (p.doubleTimePay > 0)
            _hoursRow('Dubbel Tyd', p.doubleTimeHours, p.doubleTimePay),
          if (p.publicHolidayPay > 0)
            _hoursRow(
                'Openbare Vakansie', p.publicHolidayHours, p.publicHolidayPay),
          if (p.sickLeavePay > 0)
            _hoursRowColored('Siekteverlof (SL)', p.sickLeaveHours,
                p.sickLeavePay, Colors.blue.shade700),
          if (p.holidayLeavePay > 0)
            _hoursRowColored('Vakansieverlof (HL)', p.holidayLeaveHours,
                p.holidayLeavePay, Colors.orange.shade700),
          if (p.familyLeavePay > 0)
            _hoursRowColored('Gesinsverlof (FL)', p.familyLeaveHours,
                p.familyLeavePay, Colors.purple.shade700),
          const Divider(),
          _totalRow('TOTALE INKOMSTE', p.totalEarnings, primaryColor),
        ],
      ),
    );
  }

  // ── Right column ──────────────────────────────────────────────────────────

  Widget _buildRightColumn(PayslipModel p, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('ANDER BESONDERHEDE', primaryColor),
          _detailRow('Betaaldatum', _shortDate.format(p.payDate)),
          _detailRow(
              'UIF Reg Nr', p.uifRegNumber.isNotEmpty ? p.uifRegNumber : '-'),
          const SizedBox(height: 20),
          _sectionHeader('AFTREKKINGS', primaryColor),
          _deductionRow('UIF Werknemer (1%)', p.uifDeduction),
          if (p.payeDeduction > 0)
            _deductionRow('PAYE Belasting', p.payeDeduction),
          for (final d in p.additionalDeductions)
            _deductionRow(d.description, d.amount),
          const Divider(),
          _totalRow(
              'TOTALE AFTREKKINGS', p.totalDeductions, Colors.red.shade700),
          const SizedBox(height: 16),
          _sectionHeader('NETTO SALARIS', primaryColor),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nett Salaris',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 14)),
                Text(_currency.format(p.netSalary),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Row widgets ───────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: primaryColor,
              letterSpacing: 0.5)),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _rateRow(String label, double rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(_currency.format(rate),
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _hoursRow(String label, double hours, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          SizedBox(
              width: 60,
              child: Text(hours.toStringAsFixed(2),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center)),
          SizedBox(
            width: 90,
            child: Text(_currency.format(amount),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _hoursRowColored(
      String label, double hours, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13, color: color, fontWeight: FontWeight.w500))),
          SizedBox(
              width: 60,
              child: Text(hours.toStringAsFixed(2),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center)),
          SizedBox(
            width: 90,
            child: Text(_currency.format(amount),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _deductionRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(_currency.format(amount),
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          Text(_currency.format(amount),
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ],
      ),
    );
  }

  // ── PDF ───────────────────────────────────────────────────────────────────

  Future<void> _printPayslip(BuildContext context, PayslipModel p) async {
    try {
      await PayslipPdfBuilder.openInBrowser(p);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Status banner ─────────────────────────────────────────────────────────

  Widget _buildStatusBanner(PayslipModel p) {
    final isFinal = p.isFinalised;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isFinal ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isFinal ? Colors.green.shade300 : Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(
            isFinal ? Icons.verified_outlined : Icons.edit_note_outlined,
            color: isFinal ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 10),
          Text(
            isFinal
                ? 'This payslip has been finalised'
                : 'This payslip is a draft',
            style: TextStyle(
              color:
                  isFinal ? Colors.green.shade800 : Colors.orange.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

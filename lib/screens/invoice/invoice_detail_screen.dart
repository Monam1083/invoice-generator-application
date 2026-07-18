import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../database/hive_service.dart';
import '../../models/invoice_model.dart';
import '../../models/invoice_status.dart';
import '../../pdf/invoice_pdf_generator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_badge.dart';
import 'create_invoice_screen.dart';

/// Read-only view of a single invoice, with export / share / print /
/// status-update / edit / delete actions.
class InvoiceDetailScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late InvoiceModel invoice;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    invoice = widget.invoice;
  }

  Future<void> _updateStatus(InvoiceStatus status) async {
    final updated = invoice.copyWith(status: status);
    await HiveService.saveInvoice(updated);
    setState(() => invoice = updated);
  }

  Future<void> _runAndReport(Future<void> Function() action, String successMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: Text('This will permanently delete ${invoice.invoiceNumber}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await HiveService.deleteInvoice(invoice.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        actions: [
          PopupMenuButton<InvoiceStatus>(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Mark as',
            onSelected: _updateStatus,
            itemBuilder: (context) => InvoiceStatus.values
                .map((s) => PopupMenuItem(value: s, child: Text('Mark as ${s.label}')))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateInvoiceScreen(existingInvoice: invoice),
                ),
              );
              if (updated == true) {
                final fresh = HiveService.getInvoiceById(invoice.id);
                if (fresh != null) setState(() => invoice = fresh);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(invoice.invoiceNumber,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.title)),
                        StatusBadge(status: invoice.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Invoice Date: ${dateFmt.format(invoice.invoiceDate)}'),
                    Text('Due Date: ${dateFmt.format(invoice.dueDate)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _infoCard('From', invoice.business.name, invoice.business.address,
                  invoice.business.email, invoice.business.phone),
              const SizedBox(height: 16),
              _infoCard('Bill To', invoice.customer.name, invoice.customer.address,
                  invoice.customer.email, invoice.customer.phone),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Items',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    ...invoice.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(item.name),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                    '${item.quantity} × ${invoice.currencySymbol}${item.unitPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(color: AppColors.subtitle, fontSize: 12)),
                              ),
                              Text('${invoice.currencySymbol}${item.total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                    const Divider(),
                    _totalsRow('Subtotal', invoice.subtotal),
                    _totalsRow('Tax (${invoice.taxPercent.toStringAsFixed(1)}%)', invoice.taxAmount),
                    _totalsRow('Grand Total', invoice.grandTotal, bold: true),
                  ],
                ),
              ),
              if (invoice.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notes',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(invoice.notes),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Download PDF',
                      icon: Icons.download_outlined,
                      isLoading: _busy,
                      onPressed: () => _runAndReport(
                        () async => InvoicePdfGenerator.saveToDevice(invoice),
                        'PDF saved to app documents folder',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Share',
                      icon: Icons.share_outlined,
                      isLoading: _busy,
                      onPressed: () => _runAndReport(
                        () => InvoicePdfGenerator.share(invoice),
                        'Shared',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Print',
                icon: Icons.print_outlined,
                isLoading: _busy,
                onPressed: () => _runAndReport(
                  () => InvoicePdfGenerator.print(invoice),
                  'Sent to printer',
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, String name, String address, String email, String phone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtitle)),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (address.isNotEmpty) Text(address),
          if (email.isNotEmpty) Text(email),
          if (phone.isNotEmpty) Text(phone),
        ],
      ),
    );
  }

  Widget _totalsRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '${invoice.currencySymbol}${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: bold ? 17 : 14,
              color: bold ? AppColors.primary : AppColors.title,
            ),
          ),
        ],
      ),
    );
  }
}

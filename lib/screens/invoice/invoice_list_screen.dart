import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../database/hive_service.dart';
import '../../models/invoice_model.dart';
import '../../models/invoice_status.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/invoice_card.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final searchCtrl = TextEditingController();
  final _uuid = const Uuid();

  List<InvoiceModel> _allInvoices = [];
  InvoiceStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
    searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void _load() {
    setState(() => _allInvoices = HiveService.getInvoices());
  }

  List<InvoiceModel> get _filtered {
    final query = searchCtrl.text.trim().toLowerCase();
    return _allInvoices.where((inv) {
      final matchesQuery = query.isEmpty ||
          inv.invoiceNumber.toLowerCase().contains(query) ||
          inv.customer.name.toLowerCase().contains(query);
      final matchesStatus = _statusFilter == null || inv.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  Future<void> _duplicate(InvoiceModel invoice) async {
    final newNumber = await HiveService.nextInvoiceNumber();
    final copy = invoice.copyWith(
      id: _uuid.v4(),
      invoiceNumber: newNumber,
      status: InvoiceStatus.unpaid,
      createdAt: DateTime.now(),
    );
    await HiveService.saveInvoice(copy);
    _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Duplicated as $newNumber')));
  }

  Future<void> _confirmDelete(InvoiceModel invoice) async {
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
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoices = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Invoices')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );
          if (saved == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(
              labelText: 'Search',
              hintText: 'Search by invoice number or customer',
              controller: searchCtrl,
              icon: Icons.search,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip('All', null),
                  ...InvoiceStatus.values.map((s) => _filterChip(s.label, s)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: invoices.isEmpty
                  ? const SingleChildScrollView(
                      child: EmptyState(
                        icon: Icons.receipt_long,
                        title: 'No invoices found',
                        subtitle: 'Try a different search or create a new invoice.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return Dismissible(
                          key: ValueKey(invoice.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            await _confirmDelete(invoice);
                            return false; // list already reloads itself
                          },
                          child: GestureDetector(
                            onLongPress: () => _showActions(invoice),
                            child: InvoiceCard(
                              invoice: invoice,
                              onTap: () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InvoiceDetailScreen(invoice: invoice),
                                  ),
                                );
                                if (changed == true) _load();
                                _load();
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, InvoiceStatus? status) {
    final selected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = status),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.title),
      ),
    );
  }

  void _showActions(InvoiceModel invoice) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(ctx);
                _duplicate(invoice);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(invoice);
              },
            ),
          ],
        ),
      ),
    );
  }
}

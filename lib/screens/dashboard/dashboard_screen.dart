import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../database/hive_service.dart';
import '../../models/invoice_model.dart';
import '../../models/invoice_status.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/invoice_card.dart';
import '../invoice/create_invoice_screen.dart';
import '../invoice/invoice_detail_screen.dart';
import '../invoice/invoice_list_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<InvoiceModel> _invoices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _invoices = HiveService.getInvoices());
  }

  double get _totalRevenue => _invoices
      .where((i) => i.status == InvoiceStatus.paid)
      .fold(0.0, (sum, i) => sum + i.grandTotal);

  int get _paidCount => _invoices.where((i) => i.status == InvoiceStatus.paid).length;

  int get _unpaidCount => _invoices.where((i) => i.status == InvoiceStatus.unpaid).length;

  String get _currencySymbol =>
      _invoices.isNotEmpty ? _invoices.first.currencySymbol : HiveService.getSettings().currencySymbol;

  @override
  Widget build(BuildContext context) {
    final recent = _invoices.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _load();
            },
          ),
        ],
      ),
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
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(AppStrings.welcome,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.title)),
              const SizedBox(height: 6),
              const Text(AppStrings.subtitle, style: TextStyle(fontSize: 15, color: AppColors.subtitle)),
              const SizedBox(height: 25),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.15,
                children: [
                  DashboardCard(
                    title: AppStrings.totalRevenue,
                    value: '$_currencySymbol${_totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.attach_money_rounded,
                    iconColor: Colors.green,
                  ),
                  DashboardCard(
                    title: AppStrings.totalInvoices,
                    value: '${_invoices.length}',
                    icon: Icons.receipt_long_rounded,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InvoiceListScreen()),
                      );
                      _load();
                    },
                  ),
                  DashboardCard(
                    title: AppStrings.paidInvoices,
                    value: '$_paidCount',
                    icon: Icons.check_circle,
                    iconColor: Colors.blue,
                  ),
                  DashboardCard(
                    title: AppStrings.pendingInvoices,
                    value: '$_unpaidCount',
                    icon: Icons.schedule,
                    iconColor: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(AppStrings.recentInvoices,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.title)),
              const SizedBox(height: 15),
              if (recent.isEmpty)
                const EmptyState(
                  icon: Icons.receipt_long,
                  title: AppStrings.noInvoices,
                  subtitle: 'Tap + to create your first invoice.',
                )
              else
                ...recent.map(
                  (invoice) => InvoiceCard(
                    invoice: invoice,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: invoice)),
                      );
                      _load();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../screens/dashboard/dashboard_screen.dart';
import '../screens/invoice/create_invoice_screen.dart';
import '../screens/invoice/invoice_list_screen.dart';
import '../screens/settings/settings_screen.dart';

/// Named routes are provided for completeness; screens that need to pass
/// data (like editing a specific invoice) are pushed directly via
/// MaterialPageRoute instead of these named routes.
class AppRoutes {
  AppRoutes._();

  static const String dashboard = '/';
  static const String createInvoice = '/create-invoice';
  static const String invoiceList = '/invoices';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> routes = {
    dashboard: (context) => const DashboardScreen(),
    createInvoice: (context) => const CreateInvoiceScreen(),
    invoiceList: (context) => const InvoiceListScreen(),
    settings: (context) => const SettingsScreen(),
  };
}

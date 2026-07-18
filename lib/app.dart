import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/dashboard/dashboard_screen.dart';

class InvoiceGeneratorApp extends StatelessWidget {
  const InvoiceGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Invoice Generator',
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
    );
  }
}

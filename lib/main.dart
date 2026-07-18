import 'package:flutter/material.dart';

import 'app.dart';
import 'database/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const InvoiceGeneratorApp());
}

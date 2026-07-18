import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/invoice_model.dart';

/// Local persistence layer built on Hive. Invoices and settings are stored
/// as plain Map<String, dynamic> values (no generated TypeAdapters needed),
/// which keeps the project buildable without running build_runner.
class HiveService {
  HiveService._();

  static const String invoiceBoxName = 'invoiceBox';
  static const String settingsBoxName = 'settingsBox';
  static const String _settingsKey = 'appSettings';

  static late Box _invoiceBox;
  static late Box _settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _invoiceBox = await Hive.openBox(invoiceBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);
  }

  // ---------------------------------------------------------------------
  // Invoices
  // ---------------------------------------------------------------------

  static Future<void> saveInvoice(InvoiceModel invoice) async {
    await _invoiceBox.put(invoice.id, invoice.toMap());
  }

  static List<InvoiceModel> getInvoices() {
    return _invoiceBox.values
        .map((e) => InvoiceModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static InvoiceModel? getInvoiceById(String id) {
    final raw = _invoiceBox.get(id);
    if (raw == null) return null;
    return InvoiceModel.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  static Future<void> deleteInvoice(String id) async {
    await _invoiceBox.delete(id);
  }

  static Future<void> clearInvoices() async {
    await _invoiceBox.clear();
  }

  // ---------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------

  static AppSettings getSettings() {
    final raw = _settingsBox.get(_settingsKey);
    if (raw == null) return AppSettings.defaults();
    return AppSettings.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  static Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put(_settingsKey, settings.toMap());
  }

  /// Reserves and returns the next invoice number (e.g. "INV-004"),
  /// incrementing the persisted counter so numbers stay unique.
  static Future<String> nextInvoiceNumber() async {
    final settings = getSettings();
    final seq = settings.nextInvoiceSeq;
    final number = '${settings.invoicePrefix}${seq.toString().padLeft(3, '0')}';
    await saveSettings(settings.copyWith(nextInvoiceSeq: seq + 1));
    return number;
  }
}

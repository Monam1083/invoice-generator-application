import 'business_info.dart';

/// App-wide configuration, edited from the Settings screen and used as
/// the default starting point for every new invoice.
class AppSettings {
  final BusinessInfo business;
  final String currencyCode;
  final String currencySymbol;
  final double defaultTaxPercent;
  final String invoicePrefix;

  /// Running counter used to generate the next sequential invoice number.
  final int nextInvoiceSeq;

  final bool darkMode;

  const AppSettings({
    required this.business,
    this.currencyCode = 'USD',
    this.currencySymbol = '\$',
    this.defaultTaxPercent = 0,
    this.invoicePrefix = 'INV-',
    this.nextInvoiceSeq = 1,
    this.darkMode = false,
  });

  AppSettings copyWith({
    BusinessInfo? business,
    String? currencyCode,
    String? currencySymbol,
    double? defaultTaxPercent,
    String? invoicePrefix,
    int? nextInvoiceSeq,
    bool? darkMode,
  }) {
    return AppSettings(
      business: business ?? this.business,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      defaultTaxPercent: defaultTaxPercent ?? this.defaultTaxPercent,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceSeq: nextInvoiceSeq ?? this.nextInvoiceSeq,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'business': business.toMap(),
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'defaultTaxPercent': defaultTaxPercent,
      'invoicePrefix': invoicePrefix,
      'nextInvoiceSeq': nextInvoiceSeq,
      'darkMode': darkMode,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      business: BusinessInfo.fromMap(Map<String, dynamic>.from(map['business'] as Map)),
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      currencySymbol: map['currencySymbol'] as String? ?? '\$',
      defaultTaxPercent: (map['defaultTaxPercent'] as num?)?.toDouble() ?? 0,
      invoicePrefix: map['invoicePrefix'] as String? ?? 'INV-',
      nextInvoiceSeq: map['nextInvoiceSeq'] as int? ?? 1,
      darkMode: map['darkMode'] as bool? ?? false,
    );
  }

  factory AppSettings.defaults() => AppSettings(business: BusinessInfo.empty());
}

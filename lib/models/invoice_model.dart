import 'business_info.dart';
import 'customer_info.dart';
import 'invoice_item.dart';
import 'invoice_status.dart';

/// Full invoice record persisted to local storage.
class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;

  final BusinessInfo business;
  final CustomerInfo customer;

  final List<InvoiceItem> items;

  /// Overall tax percentage applied to the subtotal.
  final double taxPercent;

  final String notes;
  final InvoiceStatus status;

  /// Currency symbol snapshot (e.g. "$", "Rs", "€") at time of creation.
  final String currencySymbol;

  final DateTime createdAt;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.business,
    required this.customer,
    required this.items,
    required this.currencySymbol,
    this.taxPercent = 0,
    this.notes = '',
    this.status = InvoiceStatus.unpaid,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);

  double get taxAmount => subtotal * (taxPercent / 100);

  double get grandTotal => subtotal + taxAmount;

  /// True if unpaid and past its due date - used to auto-flag overdue invoices.
  bool get isOverdue =>
      status == InvoiceStatus.unpaid && dueDate.isBefore(DateTime.now());

  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    BusinessInfo? business,
    CustomerInfo? customer,
    List<InvoiceItem>? items,
    double? taxPercent,
    String? notes,
    InvoiceStatus? status,
    String? currencySymbol,
    DateTime? createdAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      business: business ?? this.business,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      taxPercent: taxPercent ?? this.taxPercent,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'business': business.toMap(),
      'customer': customer.toMap(),
      'items': items.map((e) => e.toMap()).toList(),
      'taxPercent': taxPercent,
      'notes': notes,
      'status': status.name,
      'currencySymbol': currencySymbol,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] as String,
      invoiceNumber: map['invoiceNumber'] as String,
      invoiceDate: DateTime.parse(map['invoiceDate'] as String),
      dueDate: DateTime.parse(map['dueDate'] as String),
      business: BusinessInfo.fromMap(Map<String, dynamic>.from(map['business'] as Map)),
      customer: CustomerInfo.fromMap(Map<String, dynamic>.from(map['customer'] as Map)),
      items: (map['items'] as List)
          .map((e) => InvoiceItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String? ?? '',
      status: InvoiceStatusX.fromString(map['status'] as String? ?? 'unpaid'),
      currencySymbol: map['currencySymbol'] as String? ?? '\$',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

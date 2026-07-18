/// A single line item (product or service) on an invoice.
class InvoiceItem {
  final String id;
  final String name;
  final double quantity;
  final double unitPrice;

  /// Discount for this line, expressed as a percentage (0-100). Optional.
  final double discountPercent;

  InvoiceItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0,
  });

  /// Quantity * unit price, before discount.
  double get lineAmount => quantity * unitPrice;

  double get discountAmount => lineAmount * (discountPercent / 100);

  /// Final amount for this line after discount is applied.
  double get total => lineAmount - discountAmount;

  InvoiceItem copyWith({
    String? id,
    String? name,
    double? quantity,
    double? unitPrice,
    double? discountPercent,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercent': discountPercent,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}

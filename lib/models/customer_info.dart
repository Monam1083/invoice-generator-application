/// Customer (buyer) details captured on an invoice.
class CustomerInfo {
  final String name;
  final String address;
  final String email;
  final String phone;

  const CustomerInfo({
    required this.name,
    required this.address,
    required this.email,
    required this.phone,
  });

  CustomerInfo copyWith({
    String? name,
    String? address,
    String? email,
    String? phone,
  }) {
    return CustomerInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'email': email,
      'phone': phone,
    };
  }

  factory CustomerInfo.fromMap(Map<String, dynamic> map) {
    return CustomerInfo(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  factory CustomerInfo.empty() => const CustomerInfo(
        name: '',
        address: '',
        email: '',
        phone: '',
      );
}

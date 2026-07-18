/// Snapshot of the business (seller) details shown on an invoice.
class BusinessInfo {
  final String name;
  final String address;
  final String email;
  final String phone;

  /// Local file path to an uploaded logo image, if any.
  final String? logoPath;

  const BusinessInfo({
    required this.name,
    required this.address,
    required this.email,
    required this.phone,
    this.logoPath,
  });

  BusinessInfo copyWith({
    String? name,
    String? address,
    String? email,
    String? phone,
    String? logoPath,
  }) {
    return BusinessInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'email': email,
      'phone': phone,
      'logoPath': logoPath,
    };
  }

  factory BusinessInfo.fromMap(Map<String, dynamic> map) {
    return BusinessInfo(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      logoPath: map['logoPath'],
    );
  }

  factory BusinessInfo.empty() => const BusinessInfo(
        name: '',
        address: '',
        email: '',
        phone: '',
        logoPath: null,
      );
}

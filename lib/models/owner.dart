class Owner {
  final String id;
  final String fullName;
  final String? phone;
  final String? idDocument;
  final String? userId;
  final String personType;
  final DateTime createdAt;
  final String? companyId; // Multi-tenant

  Owner({
    required this.id,
    required this.fullName,
    this.phone,
    this.idDocument,
    this.userId,
    this.personType = 'Persona Natural',
    required this.createdAt,
    this.companyId,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'],
      fullName: json['full_name'],
      phone: json['phone'],
      idDocument: json['id_document'],
      userId: json['user_id'],
      personType: json['person_type'] ?? 'Persona Natural',
      createdAt: DateTime.parse(json['created_at']),
      companyId: json['company_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'id_document': idDocument,
      'user_id': userId,
      'person_type': personType,
      if (companyId != null) 'company_id': companyId,
    };
  }
}


class Salesperson {
  final String id;
  final String alias;
  final String fullName;
  final String? email;
  final double commissionPct;
  final bool isActive;
  final DateTime? createdAt;

  Salesperson({
    required this.id,
    required this.alias,
    required this.fullName,
    this.email,
    this.commissionPct = 20.0,
    this.isActive = true,
    this.createdAt,
  });

  factory Salesperson.fromJson(Map<String, dynamic> json) {
    return Salesperson(
      id: json['id'] ?? '',
      alias: json['alias'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'],
      commissionPct: (json['commission_pct'] ?? 20.0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alias': alias,
      'full_name': fullName,
      'email': email,
      'commission_pct': commissionPct,
      'is_active': isActive,
    };
  }

  static Salesperson get empty => Salesperson(id: '', alias: '', fullName: '');
}

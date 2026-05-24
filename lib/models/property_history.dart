class PropertyHistory {
  final String id;
  final String propertyId;
  final String companyId;
  final String operationType;
  final double finalPrice;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final DateTime createdAt;

  PropertyHistory({
    required this.id,
    required this.propertyId,
    required this.companyId,
    required this.operationType,
    required this.finalPrice,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.createdAt,
  });

  factory PropertyHistory.fromJson(Map<String, dynamic> json) {
    return PropertyHistory(
      id: json['id'],
      propertyId: json['property_id'],
      companyId: json['company_id'],
      operationType: json['operation_type'],
      finalPrice: (json['final_price'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'company_id': companyId,
      'operation_type': operationType,
      'final_price': finalPrice,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

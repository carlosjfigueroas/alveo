import 'commission_agent.dart';
import 'property.dart';

class PropertyCommission {
  final String id;
  final String companyId;
  final String? propertyId;
  final String? clientName;
  final String? historyId;
  final double finalPrice;
  final String refNumber;
  final double totalCollected;
  final String operationType;
  final String status;
  final DateTime closedDate;
  final DateTime? collectedDate;
  final DateTime? paidDate;
  final String? notes;
  final double agencyRetentionPct;
  final double agencyRetentionAmount;
  final DateTime createdAt;

  // Joined data
  final List<CommissionAgent> agents;
  final Property? property;

  PropertyCommission({
    required this.id,
    required this.companyId,
    this.propertyId,
    this.clientName,
    this.historyId,
    this.finalPrice = 0.0,
    required this.refNumber,
    required this.totalCollected,
    required this.operationType,
    required this.status,
    required this.closedDate,
    this.collectedDate,
    this.paidDate,
    this.notes,
    this.agencyRetentionPct = 0,
    this.agencyRetentionAmount = 0,
    required this.createdAt,
    this.agents = const [],
    this.property,
  });

  factory PropertyCommission.fromJson(Map<String, dynamic> json) {
    return PropertyCommission(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      propertyId: json['property_id']?.toString(),
      clientName: json['client_name']?.toString(),
      historyId: json['history_id']?.toString(),
      finalPrice: (json['final_price'] as num? ?? 0).toDouble(),
      refNumber: json['ref_number']?.toString() ?? 'N/A',
      totalCollected: (json['total_collected'] as num? ?? 0).toDouble(),
      operationType: json['operation_type']?.toString() ?? 'Venta',
      status: json['status']?.toString() ?? 'pending',
      closedDate: json['closed_date'] != null ? DateTime.parse(json['closed_date'].toString()) : DateTime.now(),
      collectedDate: json['collected_date'] != null ? DateTime.parse(json['collected_date'].toString()) : null,
      paidDate: json['paid_date'] != null ? DateTime.parse(json['paid_date'].toString()) : null,
      notes: json['notes']?.toString(),
      agencyRetentionPct: (json['agency_retention_pct'] as num? ?? 0).toDouble(),
      agencyRetentionAmount: (json['agency_retention_amount'] as num? ?? 0).toDouble(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      agents: json['commission_agents'] != null
          ? (json['commission_agents'] as List).map((e) => CommissionAgent.fromJson(e)).toList()
          : [],
      property: json['properties'] != null ? Property.fromJson(json['properties']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'property_id': propertyId,
      'client_name': clientName,
      'history_id': historyId,
      'final_price': finalPrice,
      'ref_number': refNumber,
      'total_collected': totalCollected,
      'operation_type': operationType,
      'status': status,
      'closed_date': closedDate.toIso8601String().split('T').first,
      'collected_date': collectedDate?.toIso8601String().split('T').first,
      'paid_date': paidDate?.toIso8601String().split('T').first,
      'notes': notes,
      'agency_retention_pct': agencyRetentionPct,
      'agency_retention_amount': agencyRetentionAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

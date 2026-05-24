class CommissionAgent {
  final String id;
  final String commissionId;
  final String agentId;
  final double percentage;
  final double amount;
  final bool isPaid;
  final DateTime? paidDate;
  final String companyId;

  // Additional fields for UI convenience
  final String? agentName;
  final String? agentEmail;

  CommissionAgent({
    required this.id,
    required this.commissionId,
    required this.agentId,
    required this.companyId,
    required this.percentage,
    required this.amount,
    this.isPaid = false,
    this.paidDate,
    this.agentName,
    this.agentEmail,
  });

  factory CommissionAgent.fromJson(Map<String, dynamic> json) {
    return CommissionAgent(
      id: json['id']?.toString() ?? '',
      commissionId: json['commission_id']?.toString() ?? '',
      agentId: json['agent_id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      percentage: (json['percentage'] as num? ?? 0).toDouble(),
      amount: (json['amount'] as num? ?? 0).toDouble(),
      isPaid: json['is_paid'] ?? false,
      paidDate: json['paid_date'] != null ? DateTime.parse(json['paid_date'].toString()) : null,
      agentName: json['profiles']?['full_name']?.toString(),
      agentEmail: json['profiles']?['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commission_id': commissionId,
      'agent_id': agentId,
      'company_id': companyId,
      'percentage': percentage,
      'amount': amount,
      'is_paid': isPaid,
      'paid_date': paidDate?.toIso8601String().split('T').first,
    };
  }
}

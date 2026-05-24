
class Payment {
  final String id;
  final String companyId;
  final String? companyName;
  final double amount;
  final String currency;
  final String billingCycle;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String status;
  final String paymentMethod;
  final String? reference;
  final String? notes;
  final String? receiptUrl;
  final String? confirmedBy;
  final DateTime? confirmedAt;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.companyId,
    this.companyName,
    required this.amount,
    this.currency = 'USD',
    required this.billingCycle,
    required this.periodStart,
    required this.periodEnd,
    this.status = 'pending',
    this.paymentMethod = 'bank_transfer',
    this.reference,
    this.receiptUrl,
    this.notes,
    this.confirmedBy,
    this.confirmedAt,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      companyName: json['companies'] != null ? json['companies']['name'] as String? : null,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      billingCycle: json['billing_cycle'] as String,
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String? ?? 'bank_transfer',
      reference: json['reference'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      notes: json['notes'] as String?,
      confirmedBy: json['confirmed_by'] as String?,
      confirmedAt: json['confirmed_at'] != null ? DateTime.parse(json['confirmed_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'company_id': companyId,
      'amount': amount,
      'currency': currency,
      'billing_cycle': billingCycle,
      'period_start': periodStart.toIso8601String().split('T')[0],
      'period_end': periodEnd.toIso8601String().split('T')[0],
      'status': status,
      'payment_method': paymentMethod,
      'reference': reference,
      'receipt_url': receiptUrl,
      'notes': notes,
      'confirmed_by': confirmedBy,
      'confirmed_at': confirmedAt?.toIso8601String(),
    };
  }
}

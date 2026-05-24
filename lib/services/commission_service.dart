import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/property_commission.dart';
import '../models/property_history.dart';

class CommissionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- PROPERTY HISTORY ---

  Future<List<PropertyHistory>> getPropertyHistory(String propertyId) async {
    final response = await _supabase
        .from('property_history')
        .select()
        .eq('property_id', propertyId)
        .order('start_date', ascending: false);

    return response.map((json) => PropertyHistory.fromJson(json)).toList();
  }

  // --- COMMISSIONS ---

  Future<List<PropertyCommission>> getCommissions({String? agentId, String? companyId}) async {
    var query = _supabase.from('property_commissions').select('''
          *,
          commission_agents(*, profiles(full_name)),
          properties(id, title, ref_number, city, address, type, price, owner_id)
        ''');

    if (companyId != null) {
      query = query.eq('company_id', companyId);
    }

    final response = await query.order('created_at', ascending: false);

    // Si pasamos agentId, filtramos en el cliente (o podriamos usar inner join en supabase)
    var commissions = response.map((json) => PropertyCommission.fromJson(json)).toList();

    if (agentId != null) {
      commissions = commissions.where((c) => c.agents.any((a) => a.agentId == agentId)).toList();
    }

    return commissions;
  }

  Future<String> _generateRefNumber(String companyId) async {
    final year = DateTime.now().year;
    // Obtener la cantidad de comisiones de este año para esta empresa
    final countResponse = await _supabase
        .from('property_commissions')
        .select('id')
        .eq('company_id', companyId)
        .gte('created_at', '$year-01-01T00:00:00Z')
        .lt('created_at', '${year + 1}-01-01T00:00:00Z')
        .count(CountOption.exact);

    final count = countResponse.count + 1;
    final paddedCount = count.toString().padLeft(3, '0');
    return 'COM-$year-$paddedCount';
  }

  Future<PropertyCommission> createCommission({
    required String companyId,
    String? propertyId,
    String? clientName,
    required String operationType,
    required double finalPrice,
    required double totalCollected,
    required DateTime closedDate,
    required List<Map<String, dynamic>> agentsData, // {agentId, percentage, amount}
    required double agencyRetentionPct,
    required double agencyRetentionAmount,
    String? notes,
  }) async {
    // 1. Generar history si hay inmueble asociado
    String? historyId;
    if (propertyId != null) {
      final historyRes = await _supabase.from('property_history').insert({
        'company_id': companyId,
        'property_id': propertyId,
        'operation_type': operationType,
        'final_price': finalPrice,
        'start_date': DateFormat('yyyy-MM-dd').format(closedDate),
        'notes': notes,
      }).select().single();

      historyId = historyRes['id'];
    }

    // 2. Generate Ref Number
    final refNumber = await _generateRefNumber(companyId);

    // 3. Crear Comisión
    final commissionRes = await _supabase.from('property_commissions').insert({
      'company_id': companyId,
      if (propertyId != null) 'property_id': propertyId,
      if (clientName != null) 'client_name': clientName,
      if (historyId != null) 'history_id': historyId,
      'ref_number': refNumber,
      'final_price': finalPrice,
      'total_collected': totalCollected,
      'operation_type': operationType,
      'closed_date': DateFormat('yyyy-MM-dd').format(closedDate),
      'agency_retention_pct': agencyRetentionPct,
      'agency_retention_amount': agencyRetentionAmount,
      'notes': notes,
    }).select().single();

    final commissionId = commissionRes['id'];

    // 4. Crear Commission Agents
    for (var agent in agentsData) {
      await _supabase.from('commission_agents').insert({
        'commission_id': commissionId,
        'agent_id': agent['agentId'],
        'company_id': companyId,
        'percentage': agent['percentage'],
        'amount': agent['amount'],
      });
    }
    
    // 5. Actualizar estado del inmueble automáticamente (Solo si es venta o alquiler tradicional)
    if (propertyId != null && (operationType == 'Venta' || operationType == 'Alquiler')) {
      final newPropertyStatus = operationType == 'Venta' ? 'Vendido' : 'Alquilado';
      await _supabase.from('properties').update({'status': newPropertyStatus}).eq('id', propertyId);
    }

    // 6. Retornar comisión creada (con relaciones)
    final newCommissionRes = await _supabase.from('property_commissions').select('''
          *,
          commission_agents(*, profiles(full_name)),
          properties(id, title, ref_number, city, address, type, price, owner_id)
        ''').eq('id', commissionId).single();

    return PropertyCommission.fromJson(newCommissionRes);
  }

  Future<void> updateCommissionStatus(String commissionId, String newStatus, {DateTime? date}) async {
    final Map<String, dynamic> updates = {'status': newStatus};
    
    if (newStatus == 'collected') {
      updates['collected_date'] = (date ?? DateTime.now()).toIso8601String();
    } else if (newStatus == 'paid') {
      updates['paid_date'] = (date ?? DateTime.now()).toIso8601String();
    }

    await _supabase.from('property_commissions').update(updates).eq('id', commissionId);
  }

  Future<void> updateCommission({
    required String commissionId,
    required String companyId,
    required double finalPrice,
    required double totalCollected,
    required DateTime closedDate,
    required List<Map<String, dynamic>> agentsData, // {agentId, percentage, amount}
    required double agencyRetentionPct,
    required double agencyRetentionAmount,
    String? notes,
  }) async {
    // 1. Update commission main record
    await _supabase.from('property_commissions').update({
      'final_price': finalPrice,
      'total_collected': totalCollected,
      'closed_date': DateFormat('yyyy-MM-dd').format(closedDate),
      'agency_retention_pct': agencyRetentionPct,
      'agency_retention_amount': agencyRetentionAmount,
      'notes': notes,
    }).eq('id', commissionId);

    // 2. Reconcile Agents (Delete ones not in agentsData)
    final existingAgentsRes = await _supabase.from('commission_agents').select('agent_id').eq('commission_id', commissionId);
    final existingAgentIds = (existingAgentsRes as List).map((e) => e['agent_id'] as String).toList();
    final newAgentIds = agentsData.map((a) => a['agentId'] as String).toList();

    for (var eid in existingAgentIds) {
      if (!newAgentIds.contains(eid)) {
        await _supabase.from('commission_agents').delete().match({'commission_id': commissionId, 'agent_id': eid});
      }
    }

    // 3. Update existing or insert new (though the user said no additions, we'll keep it robust)
    for (var agent in agentsData) {
      await _supabase.from('commission_agents').upsert({
        'commission_id': commissionId,
        'agent_id': agent['agentId'],
        'company_id': companyId,
        'percentage': agent['percentage'],
        'amount': agent['amount'],
      }, onConflict: 'commission_id, agent_id');
    }
  }

  Future<void> payAgent(String commissionAgentId, {DateTime? date}) async {
    await _supabase.from('commission_agents').update({
      'is_paid': true,
      'paid_date': (date ?? DateTime.now()).toIso8601String(),
    }).eq('id', commissionAgentId);
  }

  Future<void> deleteCommission(String commissionId, String? propertyId) async {
    // 1. Revertir estado del inmueble a 'Disponible' si había inmueble asociado
    if (propertyId != null) {
      await _supabase.from('properties').update({'status': 'Disponible'}).eq('id', propertyId);
    }
    
    // 2. Eliminar agentes asociados (por si no hay cascada en BD)
    await _supabase.from('commission_agents').delete().eq('commission_id', commissionId);
    
    // 3. Eliminar comisión
    await _supabase.from('property_commissions').delete().eq('id', commissionId);
  }
}

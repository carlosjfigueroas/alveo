import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/property_commission.dart';

class CommissionExcelService {
  static const Map<String, Map<String, String>> _i18n = {
    'es': {
      'summary_tab': 'Resumen',
      'detail_tab': 'Detalle de Comisiones',
      'col_ref': 'Referencia',
      'col_date': 'Fecha Cierre',
      'col_prop': 'Inmueble',
      'col_op': 'Operación',
      'col_total': 'Total Cobrado',
      'col_status': 'Estado Gral',
      'col_agent': 'Agente',
      'col_agent_pct': '% Agente',
      'col_agent_amt': 'Monto Agente',
      'col_agent_status': 'Estado Agente',
      'sum_agent': 'Agente',
      'sum_total_earned': 'Total Ganado',
      'sum_pending': 'Pendiente',
      'sum_paid': 'Pagado',
    },
    'en': {
      'summary_tab': 'Summary',
      'detail_tab': 'Commissions Detail',
      'col_ref': 'Reference',
      'col_date': 'Close Date',
      'col_prop': 'Property',
      'col_op': 'Operation',
      'col_total': 'Total Collected',
      'col_status': 'General Status',
      'col_agent': 'Agent',
      'col_agent_pct': 'Agent %',
      'col_agent_amt': 'Agent Amount',
      'col_agent_status': 'Agent Status',
      'sum_agent': 'Agent',
      'sum_total_earned': 'Total Earned',
      'sum_pending': 'Pending',
      'sum_paid': 'Paid',
    }
  };

  Future<List<int>> generateExcel(List<PropertyCommission> commissions, {String languageCode = 'es'}) async {
    var excel = Excel.createExcel();
    final t = _i18n[languageCode] ?? _i18n['es']!;
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Rename default sheet
    final detailTab = t['detail_tab']!;
    excel.rename('Sheet1', detailTab);
    
    // --- 1. DETAIL SHEET ---
    Sheet sheetObject = excel[detailTab];
    
    // Headers
    sheetObject.appendRow([
      TextCellValue(t['col_ref']!),
      TextCellValue(t['col_date']!),
      TextCellValue(t['col_prop']!),
      TextCellValue(t['col_op']!),
      TextCellValue(t['col_total']!),
      TextCellValue(t['col_status']!),
      TextCellValue(t['col_agent']!),
      TextCellValue(t['col_agent_pct']!),
      TextCellValue(t['col_agent_amt']!),
      TextCellValue(t['col_agent_status']!),
    ]);

    // Data rows
    // Since one commission can have multiple agents, we duplicate the commission data per agent row for detail
    Map<String, Map<String, double>> agentSummary = {}; // name: { 'total': X, 'paid': Y, 'pending': Z }

    for (var comm in commissions) {
      for (var agent in comm.agents) {
        final agentName = agent.agentName ?? 'N/A';
        
        sheetObject.appendRow([
          TextCellValue(comm.refNumber),
          TextCellValue(dateFormat.format(comm.closedDate)),
          TextCellValue(comm.property?.title ?? 'N/A'),
          TextCellValue(comm.operationType),
          DoubleCellValue(comm.totalCollected),
          TextCellValue(comm.status),
          TextCellValue(agentName),
          DoubleCellValue(agent.percentage),
          DoubleCellValue(agent.amount),
          TextCellValue(agent.isPaid ? 'Pagado/Paid' : 'Pendiente/Pending'),
        ]);

        // Accumulate for summary
        if (!agentSummary.containsKey(agentName)) {
          agentSummary[agentName] = {'total': 0, 'paid': 0, 'pending': 0};
        }
        agentSummary[agentName]!['total'] = agentSummary[agentName]!['total']! + agent.amount;
        if (agent.isPaid) {
          agentSummary[agentName]!['paid'] = agentSummary[agentName]!['paid']! + agent.amount;
        } else {
          agentSummary[agentName]!['pending'] = agentSummary[agentName]!['pending']! + agent.amount;
        }
      }
    }

    // --- 2. SUMMARY SHEET ---
    final summaryTab = t['summary_tab']!;
    Sheet summarySheet = excel[summaryTab];
    
    summarySheet.appendRow([
      TextCellValue(t['sum_agent']!),
      TextCellValue(t['sum_total_earned']!),
      TextCellValue(t['sum_paid']!),
      TextCellValue(t['sum_pending']!),
    ]);

    for (var entry in agentSummary.entries) {
      summarySheet.appendRow([
        TextCellValue(entry.key),
        DoubleCellValue(entry.value['total']!),
        DoubleCellValue(entry.value['paid']!),
        DoubleCellValue(entry.value['pending']!),
      ]);
    }

    return excel.encode()!;
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/company_provider.dart';
import '../services/commission_service.dart';
import '../services/commission_excel_service.dart';
import '../models/property_commission.dart';
import '../utils/file_saver.dart';
import '../services/app_themes.dart';
import '../services/app_localizations.dart';
import 'commission_form_screen.dart';
import 'commission_detail_screen.dart';
import '../widgets/admin_drawer.dart';

class CommissionsListScreen extends StatefulWidget {
  final String? initialStatus;
  const CommissionsListScreen({Key? key, this.initialStatus}) : super(key: key);

  @override
  State<CommissionsListScreen> createState() => _CommissionsListScreenState();
}

class _CommissionsListScreenState extends State<CommissionsListScreen> {
  final _commissionService = CommissionService();
  final _excelService = CommissionExcelService();
  bool _isLoading = true;
  List<PropertyCommission> _commissions = [];
  String _filterStatus = 'all'; // all, pending, collected, paid
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null) {
      _filterStatus = widget.initialStatus!;
    }
    _loadCommissions();
  }

  Future<void> _loadCommissions() async {
    setState(() => _isLoading = true);
    try {
      final companyId = context.read<CompanyProvider>().companyId;
      if (companyId == null) return;
      
      final commissions = await _commissionService.getCommissions(companyId: companyId);
      setState(() {
        _commissions = commissions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading my commissions: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    if (_filteredCommissions.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final bytes = await _excelService.generateExcel(_filteredCommissions, languageCode: Localizations.localeOf(context).languageCode);
      await saveFile(bytes, "Comisiones_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context).get('excel_report_generated'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).get('excel_generation_error', [e.toString()]))));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppThemes.primaryGreen,
              primary: AppThemes.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  List<PropertyCommission> get _filteredCommissions {
    List<PropertyCommission> list = _commissions;
    
    if (_filterStatus != 'all') {
      list = list.where((c) => c.status == _filterStatus).toList();
    }
    
    if (_startDate != null && _endDate != null) {
      list = list.where((c) {
        final date = c.closedDate;
        return (date.isAfter(_startDate!) || date.isAtSameMomentAs(_startDate!)) &&
               (date.isBefore(_endDate!.add(const Duration(days: 1))) || date.isAtSameMomentAs(_endDate!));
      }).toList();
    }
    
    return list;
  }

  double get _totalEstimated {
    return _filteredCommissions.fold(0.0, (sum, c) => sum + c.totalCollected);
  }

  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('commissions')),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: l10n.get('export_excel'),
            onPressed: _exportToExcel,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCommissions,
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // --- FILTROS ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppThemes.primaryGreen.withValues(alpha: 0.05),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            _startDate == null 
                              ? (l10n.get('filter_by_date') ?? 'Filtrar por fecha')
                              : '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (_startDate != null) ...[
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _clearDateFilter,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _filterStatus,
                  underline: const SizedBox(),
                  onChanged: (val) {
                    if (val != null) setState(() => _filterStatus = val);
                  },
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(l10n.get('all_f') ?? 'Todas')),
                    DropdownMenuItem(value: 'pending', child: Text(l10n.get('pending_plural') ?? 'Pendientes')),
                    DropdownMenuItem(value: 'collected', child: Text(l10n.get('collected_plural') ?? 'Cobradas')),
                    DropdownMenuItem(value: 'paid', child: Text(l10n.get('paid_plural') ?? 'Pagadas')),
                  ],
                ),
              ],
            ),
          ),

          // Dashboard / Totals
          Container(
            padding: const EdgeInsets.all(16),
            color: AppThemes.primaryGreen.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.get('total_filtered'), style: const TextStyle(fontSize: 14)),
                    Text(
                      currencyFormat.format(_totalEstimated),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppThemes.primaryGreen,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_filteredCommissions.length} ${l10n.get('commissions')}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCommissions.isEmpty
                    ? Center(child: Text(l10n.get('no_commissions')))
                    : ListView.builder(
                        itemCount: _filteredCommissions.length,
                        itemBuilder: (context, index) {
                          final commission = _filteredCommissions[index];
                          final propTitle = commission.property?.title ?? commission.clientName ?? l10n.get('unknown_property');
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text('${commission.refNumber} - $propTitle', maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                "${commission.operationType} | ${l10n.get('closed')}: ${DateFormat('dd/MM/yyyy').format(commission.closedDate)}\n${l10n.get('agents')}: ${commission.agents.map((a) => a.agentName ?? l10n.get('unknown')).join(', ')}",
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormat.format(commission.totalCollected),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  _StatusBadge(status: commission.status),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CommissionDetailScreen(commission: commission),
                                  ),
                                ).then((_) => _loadCommissions());
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CommissionFormScreen()),
          ).then((_) => _loadCommissions());
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.get('register_commission')),
        backgroundColor: AppThemes.terracottaRed,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color color;
    String label;

    switch (status) {
      case 'collected':
        color = Colors.blue;
        label = l10n.get('collected_f');
        break;
      case 'paid':
        color = Colors.green;
        label = l10n.get('paid_f');
        break;
      case 'pending':
      default:
        color = Colors.orange;
        label = l10n.get('pending');
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

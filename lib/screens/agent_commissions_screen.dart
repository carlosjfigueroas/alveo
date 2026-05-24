import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/commission_service.dart';
import '../services/commission_pdf_service.dart';
import '../models/property_commission.dart';
import '../models/company.dart';
import '../services/supabase_service.dart'; // To get auth info
import 'package:printing/printing.dart';
import '../widgets/admin_drawer.dart';

class AgentCommissionsScreen extends StatefulWidget {
  const AgentCommissionsScreen({Key? key}) : super(key: key);

  @override
  State<AgentCommissionsScreen> createState() => _AgentCommissionsScreenState();
}

class _AgentCommissionsScreenState extends State<AgentCommissionsScreen> {
  final _commissionService = CommissionService();
  final _supabaseService = SupabaseService();
  
  bool _isLoading = true;
  List<PropertyCommission> _commissions = [];
  String _filterStatus = 'all'; // all, paid, pending

  @override
  void initState() {
    super.initState();
    _loadMyCommissions();
  }

  Future<void> _loadMyCommissions() async {
    setState(() => _isLoading = true);
    try {
      final myAgentId = _supabaseService.client.auth.currentUser?.id;
      if (myAgentId == null) return;

      final allComms = await _commissionService.getCommissions(agentId: myAgentId);
      
      setState(() {
        _commissions = allComms;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading my commissions: \$e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
      }
    }
  }

  List<PropertyCommission> get _filteredCommissions {
    final myAgentId = _supabaseService.client.auth.currentUser?.id;
    if (_filterStatus == 'all') return _commissions;
    
    return _commissions.where((c) {
      final myAgentSplit = c.agents.firstWhere((a) => a.agentId == myAgentId);
      if (_filterStatus == 'paid') return myAgentSplit.isPaid;
      return !myAgentSplit.isPaid; // pending
    }).toList();
  }

  Future<void> _downloadReceipt(PropertyCommission commission) async {
    setState(() => _isLoading = true);
    try {
      // Mock company for now, ideally fetch from provider
      final company = Company(
        id: commission.companyId,
        name: 'Empresa',
        abbr: 'DEMO',
        domain: 'demo.com',
        isActive: true,
      );
      final pdfService = CommissionPdfService();
      final bytes = await pdfService.generateReceipt(commission, company, languageCode: 'es');
      await Printing.sharePdf(bytes: bytes, filename: 'comprobante_agente_${commission.refNumber}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error PDF: \$e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myAgentId = _supabaseService.client.auth.currentUser?.id;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Comisiones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyCommissions,
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Filtrar por: '),
                DropdownButton<String>(
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Todas')),
                    DropdownMenuItem(value: 'pending', child: Text('Pendientes')),
                    DropdownMenuItem(value: 'paid', child: Text('Pagadas')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _filterStatus = val);
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCommissions.isEmpty
                    ? const Center(child: Text('No tienes comisiones registradas.'))
                    : ListView.builder(
                        itemCount: _filteredCommissions.length,
                        itemBuilder: (context, index) {
                          final commission = _filteredCommissions[index];
                          final propTitle = commission.property?.title ?? 'Desconocido';
                          
                          // Find my specific split
                          final mySplit = commission.agents.firstWhere((a) => a.agentId == myAgentId, orElse: () => commission.agents.first);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text('${commission.refNumber} - $propTitle'),
                              subtitle: Text(
                                "${commission.operationType} | Mi Parte: ${mySplit.percentage}%\nCierre: ${DateFormat('dd/MM/yyyy').format(commission.closedDate)}",
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormat.format(mySplit.amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 16,
                                      color: mySplit.isPaid ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    mySplit.isPaid ? 'PAGADA' : 'PENDIENTE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: mySplit.isPaid ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                if (mySplit.isPaid) {
                                  _downloadReceipt(commission);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('El comprobante estará disponible cuando la comisión sea pagada.')),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

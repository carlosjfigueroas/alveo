import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/property_commission.dart';
import '../models/commission_agent.dart';
import '../services/commission_service.dart';
import '../services/commission_pdf_service.dart';
import '../services/app_themes.dart';
import '../services/app_localizations.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'commission_form_screen.dart';
import '../providers/company_provider.dart';
import '../services/supabase_service.dart';
import '../models/owner.dart';

class CommissionDetailScreen extends StatefulWidget {
  final PropertyCommission commission;

  const CommissionDetailScreen({Key? key, required this.commission}) : super(key: key);

  @override
  State<CommissionDetailScreen> createState() => _CommissionDetailScreenState();
}

class _CommissionDetailScreenState extends State<CommissionDetailScreen> {
  final _commissionService = CommissionService();
  late PropertyCommission _commission;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _commission = widget.commission;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await _commissionService.updateCommissionStatus(_commission.id, newStatus);
      // Reload the commission to get updated dates
      // For now we just mock the update locally for speed
      setState(() {
        // We'd ideally fetch it again, but simulating it:
        _commission = PropertyCommission(
          id: _commission.id,
          companyId: _commission.companyId,
          propertyId: _commission.propertyId,
          historyId: _commission.historyId,
          refNumber: _commission.refNumber,
          totalCollected: _commission.totalCollected,
          operationType: _commission.operationType,
          status: newStatus,
          closedDate: _commission.closedDate,
          collectedDate: newStatus == 'collected' ? DateTime.now() : _commission.collectedDate,
          paidDate: newStatus == 'paid' ? DateTime.now() : _commission.paidDate,
          notes: _commission.notes,
          agencyRetentionPct: _commission.agencyRetentionPct,
          agencyRetentionAmount: _commission.agencyRetentionAmount,
          createdAt: _commission.createdAt,
          agents: _commission.agents,
          property: _commission.property,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _payAgent(String agentCommissionId) async {
    setState(() => _isLoading = true);
    try {
      await _commissionService.payAgent(agentCommissionId);
      // Update local state
      setState(() {
        for (var i = 0; i < _commission.agents.length; i++) {
          if (_commission.agents[i].id == agentCommissionId) {
            final old = _commission.agents[i];
            _commission.agents[i] = CommissionAgent(
              id: old.id,
              commissionId: old.commissionId,
              agentId: old.agentId,
              companyId: old.companyId,
              percentage: old.percentage,
              amount: old.amount,
              isPaid: true,
              paidDate: DateTime.now(),
              agentName: old.agentName,
              agentEmail: old.agentEmail,
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.get('delete_commission')),
        content: Text(l10n.get('delete_commission_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.get('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.get('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _commissionService.deleteCommission(_commission.id, _commission.propertyId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.get('commission_deleted'))));
          Navigator.pop(context, true); // Regresa con un flag para refrescar lista
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.get('delete_error', [e.toString()]))));
        }
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateAgentReceipts(AppLocalizations l10n) async {
    setState(() => _isLoading = true);
    try {
      final company = context.read<CompanyProvider>().company;
      if (company == null) return;

      final pdfService = CommissionPdfService();
      final receipts = await pdfService.generateAgentReceipts(_commission, company, languageCode: Localizations.localeOf(context).languageCode);

      if (receipts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.get('no_agents_to_pay') ?? 'No hay agentes asignados')));
        return;
      }

      for (var entry in receipts.entries) {
        await Printing.sharePdf(bytes: entry.value, filename: 'recibo_${entry.key}_${_commission.refNumber}.pdf');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.get('pdf_error', [e.toString()]))));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateOwnerInvoice(AppLocalizations l10n) async {
    final ownerId = _commission.property?.ownerId;
    
    // If no owner but has client name (Other Services), we can generate a generic invoice
    if (ownerId == null && _commission.clientName == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.get('no_owner_found') ?? 'No hay propietario asociado')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final company = context.read<CompanyProvider>().company;
      if (company == null) return;

      final supabase = SupabaseService();
      Owner? owner;
      
      if (ownerId != null) {
        owner = await supabase.getOwner(ownerId);
      } else {
        // Mock owner for "Other Services"
        owner = Owner(
          id: 'temp',
          fullName: _commission.clientName ?? 'Cliente',
          createdAt: DateTime.now(),
          personType: 'Persona Natural', // Default for other services unless we add a toggle
        );
      }
      
      if (owner == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.get('no_owner_found') ?? 'Propietario no encontrado')));
        return;
      }

      final pdfService = CommissionPdfService();
      final bytes = await pdfService.generateOwnerInvoicePdf(_commission, company, owner, languageCode: Localizations.localeOf(context).languageCode);
      await Printing.sharePdf(bytes: bytes, filename: 'factura_${owner.fullName}_${_commission.refNumber}.pdf');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.get('pdf_error', [e.toString()]))));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateInternalReceipt(AppLocalizations l10n) async {
    setState(() => _isLoading = true);
    try {
      final company = context.read<CompanyProvider>().company;
      if (company == null) return;

      final pdfService = CommissionPdfService();
      final bytes = await pdfService.generateReceipt(_commission, company, languageCode: Localizations.localeOf(context).languageCode);
      await Printing.sharePdf(bytes: bytes, filename: 'interno_${_commission.refNumber}.pdf');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.get('pdf_error', [e.toString()]))));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.get('commission_detail')} ${_commission.refNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommissionFormScreen(existingCommission: _commission),
                ),
              );
              if (result == true && mounted) {
                // Refresh logic would go here, for now we pop or the user can reload
                Navigator.pop(context, true);
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.picture_as_pdf),
            onSelected: (value) {
              if (value == 'internal') _generateInternalReceipt(l10n);
              if (value == 'invoice') _generateOwnerInvoice(l10n);
              if (value == 'agents') _generateAgentReceipts(l10n);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'internal', child: Text(l10n.get('pdf_internal') ?? 'Uso Interno')),
              PopupMenuItem(value: 'invoice', child: Text(l10n.get('pdf_invoice') ?? 'Factura Propietario')),
              PopupMenuItem(value: 'agents', child: Text(l10n.get('pdf_agent_receipts') ?? 'Recibos Agentes')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _confirmDelete(l10n),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado General
                  _buildStatusCard(l10n),
                  const SizedBox(height: 20),

                  // Detalles del Inmueble y Operacion
                  Text(l10n.get('operation_details'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (_commission.property != null) ...[
                            _DetailRow(label: l10n.get('property'), value: _commission.property!.title),
                            _DetailRow(label: l10n.get('location'), value: _commission.property!.city ?? 'N/A'),
                          ] else if (_commission.clientName != null) ...[
                            _DetailRow(label: l10n.get('client_name') ?? 'Cliente', value: _commission.clientName!),
                          ],
                          const Divider(),
                          _DetailRow(label: l10n.get('operation'), value: _commission.operationType),
                          _DetailRow(label: l10n.get('close_date'), value: dateFormat.format(_commission.closedDate)),
                          const Divider(),
                          _DetailRow(
                            label: l10n.get('total_commission'),
                            value: currencyFormat.format(_commission.totalCollected),
                            valueStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppThemes.primaryGreen),
                          ),
                          const Divider(),
                          _DetailRow(label: l10n.get('agency_retention_pct', [NumberFormat("#,###.##").format(_commission.agencyRetentionPct)]), value: currencyFormat.format(_commission.agencyRetentionAmount)),
                          _DetailRow(
                            label: l10n.get('agent_pool'), 
                            value: currencyFormat.format(_commission.totalCollected - _commission.agencyRetentionAmount),
                            valueStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Agentes
                  Text(l10n.get('agent_distribution'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._commission.agents.map((agent) {
                    return Card(
                      child: ListTile(
                        title: Text(agent.agentName ?? l10n.get('agent_unknown')),
                        subtitle: Text(l10n.get('commission_pct_of', [agent.percentage.toString()])),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(agent.amount),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (agent.isPaid)
                              Text(l10n.get('paid_f').toUpperCase(), style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))
                            else
                              Text(l10n.get('pending').toUpperCase(), style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        // Botón de pago individual para el agente si la comisión ya fue cobrada por la empresa
                        onTap: () {
                          if (_commission.status != 'collected' && _commission.status != 'paid') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.get('company_must_collect_first'))),
                            );
                            return;
                          }
                          if (!agent.isPaid) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l10n.get('confirm_payment')),
                                content: Text(l10n.get('confirm_payment_body', [currencyFormat.format(agent.amount), agent.agentName])),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.get('cancel'))),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _payAgent(agent.id);
                                    },
                                    child: Text(l10n.get('confirm')),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                  if (_commission.notes != null && _commission.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(_commission.operationType == 'Otros Servicios' ? (l10n.get('concept_label') ?? 'Por concepto de:') : (l10n.get('notes') ?? 'Notas:'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(_commission.notes!),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = _commission.status == 'paid'
        ? (isDark ? Colors.green.shade900.withValues(alpha: 0.5) : Colors.green.shade50)
        : _commission.status == 'collected'
            ? (isDark ? Colors.blue.shade900.withValues(alpha: 0.5) : Colors.blue.shade50)
            : (isDark ? Colors.orange.shade900.withValues(alpha: 0.5) : Colors.orange.shade50);
    final statusColor = _commission.status == 'paid'
        ? Colors.green.shade400
        : _commission.status == 'collected'
            ? Colors.blue.shade400
            : Colors.orange.shade400;

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.get('current_status'), style: const TextStyle(fontSize: 16)),
                Text(
                  _commission.status == 'paid' ? l10n.get('paid_f').toUpperCase() 
                  : _commission.status == 'collected' ? l10n.get('collected_f').toUpperCase()
                  : l10n.get('pending').toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _commission.status == 'pending' ? () => _updateStatus('collected') : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text(l10n.get('mark_collected'), style: const TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: _commission.status == 'collected' ? () => _updateStatus('paid') : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text(l10n.get('mark_paid'), style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

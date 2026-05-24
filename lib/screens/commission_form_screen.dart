import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../providers/company_provider.dart';
import '../services/app_localizations.dart';
import '../services/app_themes.dart';
import '../services/commission_service.dart';
import '../services/supabase_service.dart';
import '../utils/formatters.dart';
import '../models/property_commission.dart';

class CommissionFormScreen extends StatefulWidget {
  final PropertyCommission? existingCommission;
  const CommissionFormScreen({Key? key, this.existingCommission}) : super(key: key);

  @override
  State<CommissionFormScreen> createState() => _CommissionFormScreenState();
}

class _CommissionFormScreenState extends State<CommissionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commissionService = CommissionService();
  final _supabaseService = SupabaseService();
  
  bool _isLoading = false;
  
  // Selectores
  Property? _selectedProperty;
  List<Property> _properties = [];
  
  String _operationType = 'Venta';
  DateTime _closedDate = DateTime.now();
  
  final _finalPriceCtrl = TextEditingController();
  final _totalCommissionCtrl = TextEditingController();
  final _agencyRetentionPctCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Propietarios
  String _selectedOwnerId = 'all';
  List<Map<String, dynamic>> _owners = [];
  List<Property> _allProperties = [];

  // Multi-agente
  List<Map<String, dynamic>> _agentSplits = []; // { agentId: string, name: string, percentage: double }
  List<Map<String, dynamic>> _availableAgents = []; // { id: string, name: string }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final companyId = context.read<CompanyProvider>().companyId;
      if (companyId == null) return;
      
      // Load properties (only available ones)
      final props = await _supabaseService.getProperties(companyId: companyId);
      
      // Load owners
      final ownersRes = await _supabaseService.client
          .from('owners')
          .select('id, full_name')
          .eq('company_id', companyId)
          .order('full_name');

      // Load agents for this company (mock via profiles with agent role)
      final res = await _supabaseService.client
          .from('profiles')
          .select('id, full_name, default_commission_pct')
          .eq('company_id', companyId)
          .inFilter('role', ['agent', 'admin', 'company_admin']);
          
      setState(() {
        _owners = List<Map<String, dynamic>>.from(ownersRes);
        _allProperties = props;
        
        // if editing, we show all properties but mark current one
        if (widget.existingCommission != null) {
          _properties = _allProperties.where((p) => 
            p.status == 'Disponible' || p.id == widget.existingCommission!.propertyId
          ).toList();
          _selectedProperty = widget.existingCommission!.propertyId == null 
            ? null 
            : _properties.firstWhere((p) => p.id == widget.existingCommission!.propertyId, orElse: () => _properties.first);
          _operationType = widget.existingCommission!.operationType;
          _closedDate = widget.existingCommission!.closedDate;
          _clientNameCtrl.text = widget.existingCommission!.clientName ?? '';
          _finalPriceCtrl.text = NumberFormat('#,###.##').format(widget.existingCommission!.finalPrice);
          _totalCommissionCtrl.text = NumberFormat('#,###.##').format(widget.existingCommission!.totalCollected);
          _agencyRetentionPctCtrl.text = widget.existingCommission!.agencyRetentionPct.toString();
          _notesCtrl.text = widget.existingCommission!.notes ?? '';
          _agentSplits = widget.existingCommission!.agents.map((a) => {
            'agentId': a.agentId,
            'name': a.agentName,
            'percentage': a.percentage,
            'id': a.id,
          }).toList();
        } else {
          _properties = _allProperties.where((p) => p.status == 'Disponible').toList();
          final company = context.read<CompanyProvider>().company;
          if (company != null) {
            _agencyRetentionPctCtrl.text = NumberFormat("#,###.##").format(company.defaultAgencySplitPct);
          }
        }

        _availableAgents = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
      
      // Listen to total commission and retention to trigger re-renders for Monto Agencia
      _totalCommissionCtrl.addListener(() => setState(() {}));
      _agencyRetentionPctCtrl.addListener(() => setState(() {}));
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addAgentSplit() {
    if (_availableAgents.isEmpty) return;
    final agent = _availableAgents.first;
    setState(() {
      _agentSplits.add({
        'agentId': agent['id'],
        'name': agent['full_name'],
        'percentage': (agent['default_commission_pct'] as num?)?.toDouble() ?? 0.0,
      });
    });
  }

  void _removeAgentSplit(int index) {
    setState(() {
      _agentSplits.removeAt(index);
    });
  }

  double get _currentTotalPercentage {
    return _agentSplits.fold(0.0, (sum, item) => sum + (item['percentage'] as double));
  }

  void _recalculateTotalCommission() {
    final priceStr = _finalPriceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final price = double.tryParse(priceStr) ?? 0;
    if (price <= 0) {
      _totalCommissionCtrl.text = '';
      return;
    }

    final company = context.read<CompanyProvider>().company;
    double calcCommission = 0;

    if (_operationType == 'Venta') {
      calcCommission = price * ((company?.defaultSaleCommissionPct ?? 5.0) / 100.0);
    } else if (_operationType == 'Alquiler') {
      final isCommercial = _selectedProperty?.type != null && !const {'Casa', 'Apartamento', 'Loft', 'Estudio'}.contains(_selectedProperty!.type);
      final months = isCommercial 
          ? (company?.defaultCommercialRentalMonths ?? 1.0)
          : (company?.defaultResidentialRentalMonths ?? 1.0);
      calcCommission = price * months;
    } else if (_operationType == 'Gestión de Alquileres' && company != null) {
      // Use property-specific override if available, else company default
      final adminPct = (_selectedProperty?.adminCommissionPct != null && _selectedProperty!.adminCommissionPct! > 0)
          ? _selectedProperty!.adminCommissionPct!
          : company.defaultAdminCommissionPct;
      calcCommission = price * (adminPct / 100.0);
    }
    
    if (calcCommission > 0) {
      _totalCommissionCtrl.text = NumberFormat('#,###.##').format(calcCommission);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    // Validar repartición de agentes antes de pedir confirmación
    if (_agentSplits.isNotEmpty && _currentTotalPercentage != 100.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('agent_split_error', [_currentTotalPercentage.toString()])),
          backgroundColor: Colors.redAccent,
        )
      );
      return;
    }

    // Confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.get('confirm_save_commission')),
        content: Text(l10n.get('confirm_save_commission_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.get('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.get('confirm')),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    
    if (_operationType != 'Otros Servicios' && _selectedProperty == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).get('required'))));
      return;
    }
    
    if (_operationType == 'Otros Servicios' && _clientNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).get('client_name_required'))));
      return;
    }



    setState(() => _isLoading = true);
    try {
      final finalPrice = double.parse(_finalPriceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''));
      final totalCommission = double.parse(_totalCommissionCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''));
      final agencyPct = _agentSplits.isEmpty ? 100.0 : double.parse(_agencyRetentionPctCtrl.text.isEmpty ? '0' : _agencyRetentionPctCtrl.text);
      
      final agencyAmount = totalCommission * (agencyPct / 100.0);
      final agentsPool = totalCommission - agencyAmount;
      
      // Preparar datos de agentes con monto calculado sobre el POOL (no sobre el total cobrado)
      List<Map<String, dynamic>> formattedAgents = _agentSplits.map((a) {
        final pct = a['percentage'] as double;
        final amount = agentsPool * (pct / 100.0);
        return {
          'agentId': a['agentId'],
          'percentage': pct,
          'amount': amount,
        };
      }).toList();

      if (widget.existingCommission != null) {
        await _commissionService.updateCommission(
          commissionId: widget.existingCommission!.id,
          companyId: context.read<CompanyProvider>().companyId!,
          finalPrice: finalPrice,
          totalCollected: totalCommission,
          closedDate: _closedDate,
          agentsData: formattedAgents,
          agencyRetentionPct: agencyPct,
          agencyRetentionAmount: agencyAmount,
          notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
        );
      } else {
        await _commissionService.createCommission(
          companyId: context.read<CompanyProvider>().companyId!,
          propertyId: _operationType == 'Otros Servicios' ? null : _selectedProperty?.id,
          clientName: _clientNameCtrl.text.isEmpty ? null : _clientNameCtrl.text,
          operationType: _operationType,
          finalPrice: finalPrice,
          totalCollected: totalCommission,
          closedDate: _closedDate,
          agentsData: formattedAgents,
          agencyRetentionPct: agencyPct,
          agencyRetentionAmount: agencyAmount,
          notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.existingCommission != null ? (l10n.get('commission_updated') ?? 'Comisión actualizada') : l10n.get('commission_registered'))));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('register_commission'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- DATOS OPERACION ---
                    Text(l10n.get('operation_details'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    if (_operationType != 'Otros Servicios') ...[
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: l10n.get('owner') ?? 'Propietario', border: const OutlineInputBorder()),
                        value: _selectedOwnerId,
                        items: [
                          DropdownMenuItem<String>(value: 'all', child: Text(l10n.get('all') ?? 'Todos')),
                          ..._owners.map((o) => DropdownMenuItem<String>(value: o['id'], child: Text(o['full_name']))).toList(),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedOwnerId = val!;
                            if (_selectedOwnerId == 'all') {
                              _properties = _allProperties.where((p) => 
                                p.status == 'Disponible' || (widget.existingCommission != null && p.id == widget.existingCommission!.propertyId)
                              ).toList();
                            } else {
                              _properties = _allProperties.where((p) => 
                                p.ownerId == _selectedOwnerId && 
                                (p.status == 'Disponible' || (widget.existingCommission != null && p.id == widget.existingCommission!.propertyId))
                              ).toList();
                            }
                            _selectedProperty = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Property>(
                        decoration: InputDecoration(labelText: l10n.get('property'), border: const OutlineInputBorder()),
                        value: _selectedProperty,
                        items: _properties.map((p) => DropdownMenuItem(value: p, child: Text('${p.refNumber} - ${p.title}', maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: widget.existingCommission != null ? null : (val) {
                          setState(() {
                            _selectedProperty = val;
                            if (val?.price != null) {
                              _finalPriceCtrl.text = NumberFormat('#,###.##').format(val!.price!);
                              _recalculateTotalCommission();
                            }
                          });
                        },
                        validator: (val) => val == null ? l10n.get('required') : null,
                        isExpanded: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    if (_operationType == 'Otros Servicios' || _clientNameCtrl.text.isNotEmpty) ...[
                      TextFormField(
                        controller: _clientNameCtrl,
                        decoration: InputDecoration(labelText: l10n.get('client_name'), border: const OutlineInputBorder()),
                        validator: (val) => _operationType == 'Otros Servicios' && val!.isEmpty ? l10n.get('required') : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width < 400 ? double.infinity : (MediaQuery.of(context).size.width - 48) / 2,
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: l10n.get('operation'), 
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            value: _operationType,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: 'Venta', child: Text(l10n.get('op_sale'))),
                              DropdownMenuItem(value: 'Alquiler', child: Text(l10n.get('op_rent'))),
                              DropdownMenuItem(value: 'Gestión de Alquileres', child: Text(l10n.get('op_rental_mgmt'))),
                              DropdownMenuItem(value: 'Otros Servicios', child: Text(l10n.get('op_other_services'))),
                            ],
                            onChanged: (val) => setState(() {
                              _operationType = val!;
                              if (_operationType == 'Otros Servicios') {
                                _selectedProperty = null;
                              }
                              _recalculateTotalCommission();
                            }),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width < 400 ? double.infinity : (MediaQuery.of(context).size.width - 48) / 2,
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: l10n.get('close_date'), 
                              border: const OutlineInputBorder(), 
                              suffixIcon: const Icon(Icons.calendar_today, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            readOnly: true,
                            controller: TextEditingController(text: DateFormat('dd/MM/yyyy').format(_closedDate)),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _closedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) setState(() => _closedDate = date);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width < 400 ? double.infinity : (MediaQuery.of(context).size.width - 48) / 2,
                          child: TextFormField(
                            controller: _finalPriceCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.get('final_price'), 
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [CurrencyInputFormatter()],
                            onChanged: (val) {
                              _recalculateTotalCommission();
                            },
                            validator: (val) => val!.isEmpty ? l10n.get('required') : null,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width < 400 ? double.infinity : (MediaQuery.of(context).size.width - 48) / 2,
                          child: TextFormField(
                            controller: _totalCommissionCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.get('commission_collected'), 
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [CurrencyInputFormatter()],
                            validator: (val) => val!.isEmpty ? l10n.get('required') : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _agencyRetentionPctCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.get('agency_retention'), 
                              border: const OutlineInputBorder(), 
                              suffixText: '%',
                              helperText: 'Parte que queda para la inmobiliaria',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [DecimalInputFormatter()],
                            validator: (val) => val!.isEmpty ? l10n.get('required') : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                            ),
                            child: Text(
                              _agentSplits.isEmpty 
                                ? '${l10n.get('agency_amount')}: ${context.read<CompanyProvider>().company?.currencySymbol ?? '\$'}${NumberFormat('#,###.##').format(double.tryParse(_totalCommissionCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0)} (100%)'
                                : '${l10n.get('agency_amount')}: ${context.read<CompanyProvider>().company?.currencySymbol ?? '\$'}${NumberFormat('#,###.##').format(
                                  (double.tryParse(_totalCommissionCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0) * 
                                  ((double.tryParse(_agencyRetentionPctCtrl.text) ?? 0) / 100.0)
                                )}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: InputDecoration(
                        labelText: _operationType == 'Otros Servicios' 
                          ? (l10n.get('concept_label') ?? 'Por concepto de:') 
                          : l10n.get('notes_optional'), 
                        border: const OutlineInputBorder()
                      ),
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // --- MULTI AGENTE ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.get('agent_split'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (widget.existingCommission == null)
                        TextButton.icon(
                          onPressed: _addAgentSplit,
                          icon: const Icon(Icons.add),
                          label: Text(l10n.get('add_agent')),
                        ),
                      ],
                    ),
                    const Text('Reparto del fondo restante entre los asesores', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    
                    // Alerta si no es 100%
                    if (_agentSplits.isNotEmpty && _currentTotalPercentage != 100.0)
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade100,
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(l10n.get('total_must_be_100', [_currentTotalPercentage.toString()]), style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.orangeAccent : Colors.deepOrange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      
                    const SizedBox(height: 8),
                    
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _agentSplits.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(labelText: l10n.get('agent')),
                                    value: _agentSplits[index]['agentId'],
                                    items: _availableAgents.map((a) => DropdownMenuItem<String>(value: a['id'], child: Text(a['full_name']))).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _agentSplits[index]['agentId'] = val;
                                        final selectedAgent = _availableAgents.firstWhere((a) => a['id'] == val);
                                        _agentSplits[index]['name'] = selectedAgent['full_name'];
                                        _agentSplits[index]['percentage'] = (selectedAgent['default_commission_pct'] as num?)?.toDouble() ?? 0.0;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      TextFormField(
                                        key: ValueKey('percentage_${_agentSplits[index]["agentId"]}'),
                                        decoration: const InputDecoration(labelText: '%', suffixText: '%'),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [DecimalInputFormatter()],
                                        initialValue: _agentSplits[index]['percentage'].toString(),
                                        onChanged: (val) {
                                          setState(() {
                                            _agentSplits[index]['percentage'] = double.tryParse(val) ?? 0.0;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 4),
                                      Builder(builder: (context) {
                                        final totalCollected = double.tryParse(_totalCommissionCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                                        final agencyPct = (double.tryParse(_agencyRetentionPctCtrl.text) ?? 0.0) / 100.0;
                                        final agentPool = totalCollected * (1.0 - agencyPct);
                                        final agentAmount = agentPool * ((_agentSplits[index]['percentage'] as num?)?.toDouble() ?? 0.0) / 100.0;
                                        final symbol = context.read<CompanyProvider>().company?.currencySymbol ?? '\$';
                                        return Text(
                                          '$symbol${NumberFormat('#,###.##').format(agentAmount)}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeAgentSplit(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppThemes.primaryGreen),
                        onPressed: _submit,
                        child: Text(l10n.get('register_operation'), style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

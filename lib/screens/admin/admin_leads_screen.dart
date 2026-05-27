import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin_drawer.dart';
import '../../services/app_localizations.dart';
import '../../services/app_provider.dart';
import '../../services/supabase_service.dart';
import '../../providers/company_provider.dart';
import '../../widgets/suspension_wrapper.dart';

class AdminLeadsScreen extends StatefulWidget {
  const AdminLeadsScreen({super.key});

  @override
  State<AdminLeadsScreen> createState() => _AdminLeadsScreenState();
}

class _AdminLeadsScreenState extends State<AdminLeadsScreen> {
  final SupabaseService _service = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _leads = [];
  Map<String, String> _propertyTitles = {};
  Map<String, String> _agentNames = {};
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';

  List<Map<String, dynamic>> get _filteredLeads {
    return _leads.where((lead) {
      // 1. Status Filter
      if (_selectedStatusFilter != 'all') {
        final status = lead['status'] ?? 'pending';
        if (status != _selectedStatusFilter) return false;
      }
      
      // 2. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (lead['client_name'] ?? '').toString().toLowerCase();
        final email = (lead['client_email'] ?? '').toString().toLowerCase();
        final phone = (lead['phone'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q) || phone.contains(q);
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    setState(() => _isLoading = true);
    try {
      final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
      final appProv = Provider.of<AppProvider>(context, listen: false);
      final agentId = appProv.userProfile?.role == 'agent' ? appProv.userProfile?.id : null;
      
      final leads = await _service.getBudgetRequests(companyId, agentId: agentId);
      // Ensure local sorting newest first
      leads.sort((a, b) {
        final aTime = DateTime.tryParse(a['sent_at']?.toString() ?? '') ?? DateTime(0);
        final bTime = DateTime.tryParse(b['sent_at']?.toString() ?? '') ?? DateTime(0);
        return bTime.compareTo(aTime);
      });
      final props = await _service.getAllProperties(companyId);
      final titles = {
        for (var p in props)
          p.id: p.refNumber != null
              ? 'Ref. ${p.refNumber.toString().padLeft(3, '0')} - ${p.title}'
              : p.title
      };
      final agents = await _service.getCompanyUsers(companyId);
      final agentNames = {for (var a in agents) a['id'].toString(): a['full_name'].toString()};

      if (mounted) {
        setState(() {
          _leads = leads;
          _propertyTitles = titles;
          _agentNames = agentNames;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.get("error_generic")}$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'responded':
        return const Color(0xFF10B981); // beautiful emerald green
      case 'rejected':
        return const Color(0xFFEF4444); // beautiful red
      default:
        return const Color(0xFFF59E0B); // beautiful amber/orange
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'responded':
        return Icons.check;
      case 'rejected':
        return Icons.close;
      default:
        return Icons.more_horiz;
    }
  }

  /// Returns the visual color, icon, and label for a given lead source value.
  /// Follows Regla #92 (source discriminator) and Regla #5 (premium aesthetics).
  ({Color color, Color bgColor, IconData icon, String label}) _sourceStyle(String? source, AppLocalizations l10n) {
    switch (source) {
      case 'ava':
        return (
          color: const Color(0xFF7C3AED), // HSL violet — AI/Ava brand
          bgColor: const Color(0xFF7C3AED).withValues(alpha: 0.12),
          icon: Icons.auto_awesome,
          label: l10n.get('source_ava') ?? 'Agente IA',
        );
      case 'manual':
        return (
          color: const Color(0xFF0369A1), // HSL sky blue — manual/calendar
          bgColor: const Color(0xFF0369A1).withValues(alpha: 0.12),
          icon: Icons.calendar_today,
          label: l10n.get('source_manual') ?? 'Manual',
        );
      case 'web':
      default:
        return (
          color: const Color(0xFF059669), // HSL emerald — organic web
          bgColor: const Color(0xFF059669).withValues(alpha: 0.12),
          icon: Icons.language,
          label: l10n.get('source_web') ?? 'Web',
        );
    }
  }

  /// Premium source badge widget (Regla #5 — premium aesthetics).
  Widget _buildSourceBadge(String? source, AppLocalizations l10n) {
    final style = _sourceStyle(source, l10n);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: style.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 11, color: style.color),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetail(Map<String, dynamic> lead) async {
    final l10n = AppLocalizations.of(context);
    final isSpanish = Provider.of<AppProvider>(context, listen: false).locale.languageCode == 'es';
    final status = lead['status'] ?? 'pending';
    final propertyList = lead['property_list'];
    final sentAt = lead['sent_at'] != null
        ? (DateTime.tryParse(lead['sent_at'].toString())?.toLocal().toString().substring(0, 16) ?? '—')
        : '—';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(_statusIcon(status), color: _statusColor(status)),
            const SizedBox(width: 8),
            Expanded(child: Text(lead['client_name'] ?? l10n.get('leads_no_name'))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(Icons.email, l10n.get('email'), lead['client_email'] ?? '—'),
              _detailRow(Icons.phone, l10n.get('phone'), lead['phone'] ?? '—'),
              _detailRow(Icons.calendar_today, l10n.get('leads_date'), sentAt),
              _detailRow(Icons.flag, l10n.get('status_field'), l10n.get('leads_status_$status')),
              _detailRow(
                Icons.campaign_outlined,
                l10n.get('lead_source') ?? 'Origen del Lead',
                _sourceStyle(lead['source'], l10n).label,
              ),
              if (lead['notes'] != null && lead['notes'].toString().isNotEmpty)
                _detailRow(Icons.notes, l10n.get('additional_notes'), lead['notes']),
              if (propertyList != null && propertyList is List && propertyList.isNotEmpty)
                _detailRow(Icons.business, l10n.get('property'), _propertyTitles[propertyList.first] ?? propertyList.first.toString()),
              if (lead['assigned_agent_id'] != null)
                _detailRow(Icons.person, isSpanish ? 'Agente Asignado' : 'Assigned Agent', _agentNames[lead['assigned_agent_id']] ?? '—'),
            ],
          ),
        ),
        actions: [
          if (status != 'responded')
            TextButton.icon(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              label: Text(l10n.get('leads_mark_responded')),
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              onPressed: () async {
                try {
                  await _service.updateBudgetStatus(lead['id'], 'responded');
                  if (mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          if (status != 'rejected')
            TextButton.icon(
              icon: const Icon(Icons.cancel, color: Colors.red),
              label: Text(l10n.get('leads_mark_rejected')),
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              onPressed: () async {
                try {
                  await _service.updateBudgetStatus(lead['id'], 'rejected');
                  if (mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          if (Provider.of<AppProvider>(context, listen: false).isCompanyAdmin)
            TextButton.icon(
              icon: const Icon(Icons.person_add, color: Colors.blue),
              label: Text(isSpanish ? 'Asignar Agente' : 'Assign Agent'),
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              onPressed: () => _assignAgent(lead),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: Text(l10n.get('cancel')),
          ),
        ],
      ),
    );
  }


  Future<void> _assignAgent(Map<String, dynamic> lead) async {
    final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
    final agents = await _service.getCompanyUsers(companyId);
    
    if (!mounted) return;
    
    final isSpanish = Provider.of<AppProvider>(context, listen: false).locale.languageCode == 'es';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSpanish ? 'Asignar Agente' : 'Assign Agent'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: agents.length,
            itemBuilder: (c, i) {
              final agent = agents[i];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(agent['full_name'] ?? 'Unknown'),
                subtitle: Text(agent['role'] ?? ''),
                onTap: () async {
                  try {
                    await _service.client.from('budget_requests').update({
                      'assigned_agent_id': agent['id']
                    }).eq('id', lead['id']);
                    
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      Navigator.pop(context, true); // Close details
                      _loadLeads(); // Refresh
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isSpanish ? 'Agente asignado: ${agent['full_name']}' : 'Agent assigned: ${agent['full_name']}'))
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLead(String id) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.get('delete')),
        content: Text(l10n.get('delete_confirm_short')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.get('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.get('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _service.deleteBudgetRequest(id);
        _loadLeads();
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.get("error_generic")}$e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('leads')),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      drawer: const AdminDrawer(),
      body: SuspensionWrapper(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: 400,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: l10n.get('search_leads'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    _buildFilterChip('all', l10n.get('filter_all') ?? 'Todos'),
                    _buildFilterChip('pending', l10n.get('leads_status_pending') ?? 'Pendiente'),
                    _buildFilterChip('responded', l10n.get('leads_status_responded') ?? 'Respondida'),
                    _buildFilterChip('rejected', l10n.get('leads_status_rejected') ?? 'Rechazada'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredLeads.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inbox, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(l10n.get('leads_empty'), style: const TextStyle(fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        )
                    : RefreshIndicator(
                        onRefresh: _loadLeads,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredLeads.length,
                          itemBuilder: (context, index) {
                            final lead = _filteredLeads[index];
                            final status = lead['status'] ?? 'pending';
                            final source = lead['source'] ?? 'web';
                            final email = lead['client_email'] ?? '';
                            final showEmail = email.isNotEmpty && !email.toString().endsWith('@local');
                            final propertyList = lead['property_list'];
                            final hasProperty = propertyList != null && propertyList is List && propertyList.isNotEmpty;
                            
                            final sentAt = lead['sent_at'] != null
                                ? (DateTime.tryParse(lead['sent_at'].toString())?.toLocal().toString().substring(0, 16) ?? '')
                                : '';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _statusColor(status),
                                  child: Icon(_statusIcon(status), color: Colors.white),
                                ),
                                title: Text(
                                  lead['client_name'] ?? l10n.get('leads_no_name'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (showEmail) ...[
                                      const SizedBox(height: 2),
                                      Text(email),
                                    ],
                                    if (hasProperty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.business, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _propertyTitles[propertyList.first] ?? propertyList.first.toString(),
                                              style: const TextStyle(color: Colors.grey),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        _buildSourceBadge(source, l10n),
                                        if (lead['assigned_agent_id'] != null) ...[
                                          const Text('•', style: TextStyle(color: Colors.grey)),
                                          Icon(Icons.person, size: 12, color: Colors.blue.shade300),
                                          Text(
                                            _agentNames[lead['assigned_agent_id']] ?? '',
                                            style: TextStyle(fontSize: 12, color: Colors.blue.shade300, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(sentAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _statusColor(status).withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        l10n.get('leads_status_$status'),
                                        style: TextStyle(
                                          color: _statusColor(status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _deleteLead(lead['id']),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await _showDetail(lead);
                                  await _loadLeads();
                                },
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF003366),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? const Color(0xFF003366) : Colors.grey.shade300),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatusFilter = value;
          });
        }
      },
    );
  }
}

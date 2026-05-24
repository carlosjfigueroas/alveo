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

  List<Map<String, dynamic>> get _filteredLeads {
    if (_searchQuery.isEmpty) return _leads;
    final q = _searchQuery.toLowerCase();
    return _leads.where((lead) {
      final name = (lead['client_name'] ?? '').toString().toLowerCase();
      final email = (lead['client_email'] ?? '').toString().toLowerCase();
      final phone = (lead['phone'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || phone.contains(q);
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
      final titles = {for (var p in props) p.id: p.title};
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
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'responded':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
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
                            final sentAt = lead['sent_at'] != null
                                ? (DateTime.tryParse(lead['sent_at'].toString())?.toLocal().toString().substring(0, 16) ?? '')
                                : '';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _statusColor(status).withValues(alpha: 0.15),
                                  child: Icon(_statusIcon(status), color: _statusColor(status)),
                                ),
                                title: Text(
                                  lead['client_name'] ?? l10n.get('leads_no_name'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(lead['client_email'] ?? ''),
                                    Row(
                                      children: [
                                        Text(sentAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        if (lead['assigned_agent_id'] != null) ...[
                                          const SizedBox(width: 8),
                                          const Text('•', style: TextStyle(color: Colors.grey)),
                                          const SizedBox(width: 8),
                                          Icon(Icons.person, size: 12, color: Colors.blue.shade300),
                                          const SizedBox(width: 4),
                                          Text(
                                            _agentNames[lead['assigned_agent_id']] ?? '',
                                            style: TextStyle(fontSize: 12, color: Colors.blue.shade300, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ],
                                    ),
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
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin_drawer.dart';
import '../../services/app_localizations.dart';
import '../../services/supabase_service.dart';
import '../../providers/company_provider.dart';
import '../../widgets/suspension_wrapper.dart';

class AdminOwnersScreen extends StatefulWidget {
  const AdminOwnersScreen({super.key});

  @override
  State<AdminOwnersScreen> createState() => _AdminOwnersScreenState();
}

class _AdminOwnersScreenState extends State<AdminOwnersScreen> {
  final _service = SupabaseService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  List<Map<String, dynamic>> _owners = [];
  bool _isLoading = true;
  String _personType = 'Persona Natural';

  @override
  void initState() {
    super.initState();
    _loadOwners();
  }

  Future<void> _loadOwners() async {
    setState(() => _isLoading = true);
    try {
      final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
      final response = await _service.getOwners(companyId);
      setState(() => _owners = response);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showOwnerDialog([Map<String, dynamic>? owner]) async {
    final l10n = AppLocalizations.of(context);
    final isEditing = owner != null;
    
    if (isEditing) {
      _nameController.text = owner['full_name'] ?? '';
      _phoneController.text = owner['phone'] ?? '';
      _personType = owner['person_type'] ?? 'Persona Natural';
    } else {
      _nameController.clear();
      _phoneController.clear();
      _personType = 'Persona Natural';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? l10n.get('edit') : l10n.get('add_owner')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.get('owner_full_name')),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: l10n.get('owner_phone')),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _personType,
              decoration: InputDecoration(labelText: l10n.get('person_type') ?? 'Tipo de Persona'),
              items: const [
                DropdownMenuItem(value: 'Persona Natural', child: Text('Persona Natural')),
                DropdownMenuItem(value: 'Persona Juridica', child: Text('Persona Jurídica')),
                DropdownMenuItem(value: 'Ente Gubernamental', child: Text('Ente Gubernamental')),
              ],
              onChanged: (v) => setDialogState(() => _personType = v!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.trim().isNotEmpty) {
                try {
                  if (isEditing) {
                    await _service.updateOwner(owner['id'], {
                      'full_name': _nameController.text.trim(),
                      'phone': _phoneController.text.trim(),
                      'person_type': _personType,
                    });
                  } else {
                    final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
                    await _service.createOwner({
                      'full_name': _nameController.text.trim(),
                      'phone': _phoneController.text.trim(),
                      'company_id': companyId,
                      'person_type': _personType,
                    });
                  }
                  if (mounted) Navigator.pop(context);
                  _loadOwners();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10n.get("error_generic")}$e')),
                    );
                  }
                }
              }
            },
            child: Text(l10n.get('save')),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _deleteOwner(String id) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.get('delete')),
        content: Text(l10n.get('delete_owner_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.get('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.get('delete'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _service.deleteOwner(id);
        _loadOwners();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.get("owner_delete_error")}$e')),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('owners')),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      drawer: const AdminDrawer(),
      body: SuspensionWrapper(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
              itemCount: _owners.length,
              itemBuilder: (context, index) {
                final owner = _owners[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(owner['full_name']),
                  subtitle: Text(owner['phone'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showOwnerDialog(owner),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteOwner(owner['id'] as String),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
      floatingActionButton: context.watch<CompanyProvider>().isSuspended 
        ? null 
        : FloatingActionButton(
        onPressed: () => _showOwnerDialog(),
        backgroundColor: const Color(0xFF003366),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

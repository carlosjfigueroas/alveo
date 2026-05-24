import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/app_localizations.dart';
import '../../services/company_service.dart';
import '../../models/company.dart';

class SuperAdminUsersScreen extends StatefulWidget {
  const SuperAdminUsersScreen({super.key});
  @override
  State<SuperAdminUsersScreen> createState() => _SuperAdminUsersScreenState();
}

class _SuperAdminUsersScreenState extends State<SuperAdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Company> _companies = [];
  bool _isLoading = true;
  final SupabaseClient _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        _client.from('profiles').select('*, companies(name)').order('full_name'),
        CompanyService.getAllCompanies(),
      ]);
      if (mounted) {
        setState(() {
          _users = (results[0] as List).cast<Map<String, dynamic>>();
          _companies = results[1] as List<Company>;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final l10n = AppLocalizations.of(context);
    final passCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.get('change_password_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user['full_name'] ?? user['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: l10n.get('new_password'), border: const OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.get('cancel'))),
          ElevatedButton(
            onPressed: () async {
              try {
                // LLamada a la función segura RPC que creamos en Postgres
                await _client.rpc('admin_change_password', params: {
                  'user_id': user['id'],
                  'new_password': passCtrl.text.trim(),
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(l10n.get('password_updated'))));
                }
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.get('delete_confirm_title')),
        content: Text('${l10n.get('delete_confirm_body')}\n\n${l10n.get('full_name')}: ${user['full_name']}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.get('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.get('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _client.rpc('admin_delete_user', params: {'target_user_id': user['id']});
        _loadAll();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.get('user_deleted_success'))));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showUserDialog([Map<String, dynamic>? existing]) async {
    final l10n = AppLocalizations.of(context);
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?['full_name'] ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] ?? '');
    final passCtrl = TextEditingController();
    String selectedRole = existing?['role'] ?? 'company_admin';
    String? selectedCompanyId = existing?['company_id'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: Text(isEdit ? l10n.get('edit_user') : l10n.get('new_user')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nameCtrl, l10n.get('full_name')),
              if (!isEdit) ...[
                const SizedBox(height: 8),
                _field(emailCtrl, l10n.get('email'), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 8),
                _field(passCtrl, l10n.get('password'), obscure: true),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: l10n.get('role'), border: const OutlineInputBorder(), isDense: true),
                value: selectedRole,
                items: [
                  DropdownMenuItem(value: 'company_admin', child: Text(l10n.locale.languageCode == 'es' ? 'Admin de Agencia' : 'Agency Admin')),
                  DropdownMenuItem(value: 'super_admin', child: Text(l10n.locale.languageCode == 'es' ? 'Super Admin' : 'Super Admin')),
                ],
                onChanged: (v) => setDs(() => selectedRole = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                decoration: InputDecoration(labelText: l10n.get('assign_company'), border: const OutlineInputBorder(), isDense: true),
                value: selectedCompanyId,
                items: [DropdownMenuItem(value: null, child: Text(l10n.get('no_company'))), ..._companies.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))],
                onChanged: (v) => setDs(() => selectedCompanyId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.get('cancel'))),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (isEdit) {
                    await _client.from('profiles').update({'full_name': nameCtrl.text.trim(), 'role': selectedRole, 'company_id': selectedCompanyId}).eq('id', existing!['id']);
                  } else {
                    final authRes = await _client.auth.signUp(email: emailCtrl.text.trim(), password: passCtrl.text.trim(), data: {'full_name': nameCtrl.text.trim()});
                    if (authRes.user != null) {
                      await _client.from('profiles').upsert({'id': authRes.user!.id, 'full_name': nameCtrl.text.trim(), 'role': selectedRole, 'company_id': selectedCompanyId});
                      // Confirmar email automáticamente — sin esto el login falla con "credenciales inválidas"
                      await _client.rpc('admin_confirm_user_email', params: {'target_user_id': authRes.user!.id});
                      
                      // Opción A: Enviar credenciales en texto explícito en el momento exacto de la creación
                      if (!isEdit && selectedRole == 'company_admin') {
                        try {
                          await _client.functions.invoke('send-subscription-email', body: {
                            'type': 'new_user_credentials',
                            'email': emailCtrl.text.trim(),
                            'password': passCtrl.text.trim(),
                            'name': nameCtrl.text.trim(),
                          });
                        } catch (mailErr) {
                          debugPrint('Error enviando correo de credenciales: $mailErr');
                        }
                      }
                    }
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadAll();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              },
              child: Text(l10n.get('save')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {TextInputType? keyboardType, bool obscure = false}) {
    return TextField(controller: ctrl, obscureText: obscure, keyboardType: keyboardType, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showUserDialog(), icon: const Icon(Icons.person_add), label: Text(l10n.get('new_user'))),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _users.isEmpty ? Center(child: Text(l10n.get('no_users'))) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (_, i) {
          final u = _users[i];
          final role = u['role'] as String? ?? 'unknown';
          final companyName = (u['companies'] as Map<String, dynamic>?)?['name'] as String?;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: role == 'super_admin' ? Colors.deepPurple : Colors.blue,
                child: Text(
                  (() {
                    final name = (u['full_name'] as String? ?? '').trim();
                    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
                  })(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(u['full_name'] as String? ?? l10n.get('no_name'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(companyName ?? role),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showUserDialog(u)),
                IconButton(icon: const Icon(Icons.lock_reset, color: Colors.orange), onPressed: () => _resetPassword(u)),
                IconButton(icon: const Icon(Icons.delete_forever_outlined, color: Colors.red), onPressed: () => _deleteUser(u)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

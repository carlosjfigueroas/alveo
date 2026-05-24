import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/app_localizations.dart';
import '../../providers/company_provider.dart';
import '../../widgets/admin_drawer.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
      final response = await _client
          .from('profiles')
          .select('*')
          .eq('company_id', companyId)
          .order('full_name');
      
      if (mounted) {
        setState(() {
          _users = (response as List).cast<Map<String, dynamic>>();
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
            TextField(
              controller: passCtrl, 
              obscureText: true, 
              decoration: InputDecoration(labelText: l10n.get('new_password'), border: const OutlineInputBorder())
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.get('cancel'))),
          ElevatedButton(
            onPressed: () async {
              try {
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

  Future<void> _showUserDialog([Map<String, dynamic>? existing]) async {
    final l10n = AppLocalizations.of(context);
    final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
    final isEdit = existing != null;
    
    final nameCtrl = TextEditingController(text: existing?['full_name'] ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] ?? ''); // only for login email
    final passCtrl = TextEditingController();
    final commissionPctCtrl = TextEditingController(text: (existing?['default_commission_pct'] ?? 50.0).toString());
    
    // Nuevos campos
    final slugCtrl = TextEditingController(text: existing?['slug'] ?? '');
    final bioCtrl = TextEditingController(text: existing?['bio'] ?? '');
    final whatsappCtrl = TextEditingController(text: existing?['whatsapp_number'] ?? '');
    final contactEmailCtrl = TextEditingController(text: existing?['contact_email'] ?? '');
    String? photoUrl = existing?['profile_photo_url'];
    
    bool isUploading = false;
    
    const String forcedRole = 'agent';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> pickImage() async {
            final picker = ImagePicker();
            final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
            if (image == null) return;

            setStateDialog(() => isUploading = true);
            try {
              final bytes = await image.readAsBytes();
              final userId = existing?['id'] ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
              
              final path = 'profiles/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final url = await SupabaseService().uploadFile('property-images', path, bytes, contentType: 'image/jpeg');
              
              setStateDialog(() => photoUrl = url);
            } catch (e) {
              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
            } finally {
              setStateDialog(() => isUploading = false);
            }
          }

          return AlertDialog(
            title: Text(isEdit ? l10n.get('edit_user') : l10n.get('new_user')),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Photo Upload
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                            child: photoUrl == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                          ),
                          if (isUploading)
                            const Positioned.fill(child: CircularProgressIndicator()),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.blue,
                              radius: 16,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                onPressed: pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    TextField(controller: nameCtrl, decoration: InputDecoration(labelText: l10n.get('full_name'), border: const OutlineInputBorder(), isDense: true, prefixIcon: const Icon(Icons.person))),
                    const SizedBox(height: 12),
                    
                    if (!isEdit) ...[
                      TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo de Login', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.login))),
                      const SizedBox(height: 12),
                      TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: l10n.get('password'), border: const OutlineInputBorder(), isDense: true, prefixIcon: const Icon(Icons.lock))),
                      const SizedBox(height: 12),
                    ],
                    
                    TextField(controller: contactEmailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo Público (Contacto)', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.email))),
                    const SizedBox(height: 12),
                    
                    TextField(controller: whatsappCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'WhatsApp (Ej. +58412...)', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.phone))),
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: slugCtrl, 
                      decoration: InputDecoration(
                        labelText: l10n.get('username_slug'), 
                        border: const OutlineInputBorder(), 
                        isDense: true, 
                        prefixIcon: const Icon(Icons.link),
                        helperText: slugCtrl.text.isEmpty ? null : ' alveo.fyi/agent/${slugCtrl.text}',
                      ),
                      onChanged: (_) => setStateDialog((){}),
                    ),
                    const SizedBox(height: 12),
                    
                    TextField(controller: bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Biografía / Descripción', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.edit_note))),
                    const SizedBox(height: 12),

                    TextField(
                      controller: commissionPctCtrl, 
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: '% Comisión por defecto', border: OutlineInputBorder(), isDense: true, suffixText: '%')
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.get('cancel'))),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final slugVal = slugCtrl.text.trim().toLowerCase().replaceAll(' ', '-');
                    final updateData = {
                      'full_name': nameCtrl.text.trim(),
                      'default_commission_pct': double.tryParse(commissionPctCtrl.text) ?? 50.0,
                      'slug': slugVal.isNotEmpty ? slugVal : null,
                      'bio': bioCtrl.text.trim().isNotEmpty ? bioCtrl.text.trim() : null,
                      'whatsapp_number': whatsappCtrl.text.trim().isNotEmpty ? whatsappCtrl.text.trim() : null,
                      'contact_email': contactEmailCtrl.text.trim().isNotEmpty ? contactEmailCtrl.text.trim() : null,
                      'profile_photo_url': photoUrl,
                    };

                    if (isEdit) {
                      await _client.from('profiles').update(updateData).eq('id', existing!['id']);
                    } else {
                      final adminRefreshToken = _client.auth.currentSession?.refreshToken;
                      final authRes = await _client.auth.signUp(
                        email: emailCtrl.text.trim(), 
                        password: passCtrl.text.trim(), 
                        data: {
                          'role': forcedRole,
                          'company_id': companyId,
                          ...updateData,
                        }
                      );

                      if (adminRefreshToken != null) {
                        try {
                          await _client.auth.setSession(adminRefreshToken);
                        } catch (_) {
                          await _client.auth.signOut();
                        }
                      }
                      if (authRes.user != null) {
                        await _client.rpc('admin_confirm_user_email', params: {'target_user_id': authRes.user!.id});
                      }
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadUsers();
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                },
                child: Text(l10n.get('save')),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('users_management')),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.person_add),
        label: Text(l10n.get('new_user')),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(child: Text(l10n.get('no_users')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    final role = u['role'] as String? ?? 'unknown';
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: role == 'company_admin' ? Colors.orange : Colors.blue,
                          child: Text(
                            (() {
                              final name = (u['full_name'] as String? ?? '').trim();
                              return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
                            })(),
                            style: const TextStyle(color: Colors.white)
                          ),
                        ),
                        title: Text(u['full_name'] as String? ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(l10n.get('role_${u['role'] ?? 'agent'}')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showUserDialog(u),
                            ),
                            IconButton(
                              icon: const Icon(Icons.lock_reset, color: Colors.orange),
                              onPressed: () => _resetPassword(u),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

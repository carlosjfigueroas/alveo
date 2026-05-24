import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../services/app_provider.dart';
import '../../services/app_localizations.dart';
import '../../services/supabase_service.dart';
import '../../providers/company_provider.dart';
import '../../widgets/admin_drawer.dart';
import '../../utils/image_utils.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SupabaseService();
  
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  
  bool _isLoading = false;
  bool _isSaving = false;
  String? _photoUrl;
  Uint8List? _newPhotoBytes;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AppProvider>(context, listen: false).userProfile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _slugController = TextEditingController(text: profile?.slug ?? '');
    _phoneController = TextEditingController(text: profile?.whatsappNumber ?? '');
    _emailController = TextEditingController(text: profile?.contactEmail ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _photoUrl = profile?.profilePhotoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Bajamos el quality inicial a 50 para ayudar a la carga
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      
      // Mostrar indicador de carga si fuera necesario, pero por ahora directo
      final compressedBytes = await ImageUtils.compressImage(
        bytes, 
        maxDimension: 600, // Los perfiles no necesitan ser gigantes
        targetSizeKb: 150,  // Meta agresiva pero suficiente para web
      );
      
      setState(() {
        _newPhotoBytes = compressedBytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final appProv = Provider.of<AppProvider>(context, listen: false);
      final userId = appProv.userProfile!.id;
      
      // Check slug uniqueness if changed
      if (_slugController.text != appProv.userProfile?.slug) {
        final available = await _isSlugAvailable(_slugController.text, userId);
        if (!available) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('El alias (slug) ya está en uso. Por favor elige otro.'), backgroundColor: Colors.orange)
             );
          }
          setState(() => _isSaving = false);
          return;
        }
      }

      String? finalPhotoUrl = _photoUrl;
      if (_newPhotoBytes != null) {
        final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final finalPath = 'profiles/$fileName';
        finalPhotoUrl = await _service.uploadFile('property-images', finalPath, _newPhotoBytes!, contentType: 'image/jpeg');
      }

      final updateData = {
        'full_name': _nameController.text.trim(),
        'slug': _slugController.text.trim().toLowerCase(),
        'whatsapp_number': _phoneController.text.trim(),
        'contact_email': _emailController.text.trim(),
        'bio': _bioController.text.trim(),
        'profile_photo_url': finalPhotoUrl,
      };

      await _service.updateUserProfile(userId, updateData);
      
      // Refresh local profile
      final updatedProfile = await _service.getUserProfile(userId);
      if (updatedProfile != null) {
        appProv.setUserProfile(updatedProfile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _isSlugAvailable(String slug, String userId) async {
    final response = await _service.client
        .from('profiles')
        .select('id')
        .eq('slug', slug)
        .neq('id', userId)
        .maybeSingle();
    return response == null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final company = Provider.of<CompanyProvider>(context).currentCompany;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('my_profile') ?? 'Mi Perfil'),
        backgroundColor: company.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: l10n.get('share_profile'),
            onPressed: () {
              final profile = Provider.of<AppProvider>(context, listen: false).userProfile;
              if (profile?.slug != null) {
                final url = 'https://alveo.fyi/agent/${profile!.slug}';
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).get('copy_link_success') ?? 'Copiado al portapapeles'))
                );
              }
            },
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Photo Header
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _newPhotoBytes != null 
                          ? MemoryImage(_newPhotoBytes!) as ImageProvider
                          : (_photoUrl != null ? NetworkImage(_photoUrl!) as ImageProvider : null),
                      child: (_photoUrl == null && _newPhotoBytes == null)
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: company.primaryColor,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.get('full_name'),
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.isEmpty) ? l10n.get('required') : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _slugController,
                decoration: InputDecoration(
                  labelText: 'Alias (Slug URL)',
                  helperText: 'Esto define tu link: alveo.fyi/agent/tu-alias',
                  prefixIcon: const Icon(Icons.link),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return l10n.get('required');
                  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(val)) return 'Solo minúsculas, números y guiones';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'WhatsApp / Teléfono',
                  prefixIcon: const Icon(Icons.phone),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email de Contacto Público',
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Biografía / Descripción',
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: company.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.get('save').toUpperCase()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

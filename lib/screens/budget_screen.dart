import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/app_localizations.dart';
import '../services/supabase_service.dart';
import '../services/app_themes.dart';
import '../providers/company_provider.dart';
import '../models/property.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  final String? selectedPropertyId;

  const BudgetScreen({super.key, this.selectedPropertyId});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SupabaseService();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _propertyNameController = TextEditingController();
  
  List<Property> _availableProperties = [];
  String? _currentSelectedId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _propertyNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentSelectedId = widget.selectedPropertyId;
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
      final properties = await _service.getPublicProperties(companyId);
      setState(() {
        _availableProperties = properties;
        // If we came from a specific property, ensure it's in the list
        if (_currentSelectedId != null) {
          final found = _availableProperties.where((p) => p.id == _currentSelectedId);
          if (found.isNotEmpty) {
            _propertyNameController.text = found.first.title;
          } else {
            _currentSelectedId = null;
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading properties: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_currentSelectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('select_property'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final selectedProperty = _availableProperties.firstWhere((p) => p.id == _currentSelectedId);
      final isSpanish = Provider.of<AppProvider>(context, listen: false).locale.languageCode == 'es';
      final formattedPrice = selectedProperty.price == 0 
          ? l10n.get('price_on_request')
          : NumberFormat("#,##0", isSpanish ? 'es_ES' : 'en_US').format(selectedProperty.price);

      final propertyData = {
        'id': selectedProperty.id,
        'title': selectedProperty.title,
        'price': formattedPrice,
        'type': selectedProperty.type,
        'operation': selectedProperty.operationType,
      };

      final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
      await _service.createBudgetRequest({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'propertyIds': [_currentSelectedId!],
        'propertyDetails': [propertyData],
        'notes': _notesController.text,
        'locale': Provider.of<AppProvider>(context, listen: false).locale.languageCode,
        'companyEmail': Provider.of<CompanyProvider>(context, listen: false).contactEmail,
        'companyName': Provider.of<CompanyProvider>(context, listen: false).companyName,
        'primaryColor': Provider.of<CompanyProvider>(context, listen: false).primaryColorHex,
        'secondaryColor': Provider.of<CompanyProvider>(context, listen: false).secondaryColorHex,
        'assigned_agent_id': Provider.of<AppProvider>(context, listen: false).agentContext?.id,
        'agentEmail': Provider.of<AppProvider>(context, listen: false).agentContext?.contactEmail,
      }, companyId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('budget_sent'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.get("budget_error")}$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final l10n = AppLocalizations(appProvider.locale);
    final isSpanish = appProvider.locale.languageCode == 'es';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('me_interesa')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.get('budget_intro'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppThemes.primaryGreen),
                    ),
                    const SizedBox(height: 24),
                    // Inmueble Selection (Read-only if coming from property card)
                    widget.selectedPropertyId != null
                      ? Container(
                          margin: const EdgeInsets.only(bottom: 0),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.grey[50], // Adaptive background
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade400),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.business, color: isDark ? Colors.white70 : Colors.grey.shade700, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.get('prop_interest'),
                                      style: TextStyle(
                                        color: isDark ? Colors.white60 : Colors.grey.shade700, 
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _propertyNameController.text,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black, 
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 18),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          value: _currentSelectedId,
                          icon: const Icon(Icons.arrow_drop_down),
                          decoration: InputDecoration(
                            labelText: l10n.get('prop_interest'),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.business),
                          ),
                          items: _availableProperties.map((p) {
                            return DropdownMenuItem(
                              value: p.id,
                              child: Text(p.title, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _currentSelectedId = val),
                          validator: (val) => val == null ? l10n.get('required') : null,
                        ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.get('full_name'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? l10n.get('required') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: l10n.get('email'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => (val == null || !val.contains('@')) ? l10n.get('invalid_email') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: l10n.get('phone'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (val) => (val == null || val.isEmpty) ? l10n.get('required') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: l10n.get('additional_notes'),
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                        helperText: l10n.get('helper_notes'),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemes.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              l10n.get('send').toUpperCase(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_localizations.dart';
import '../../services/app_provider.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/property.dart';
import '../../widgets/admin_drawer.dart';
import '../../providers/company_provider.dart';
import 'property_editor_screen.dart';
import 'package:intl/intl.dart';
import '../../services/like_service.dart';
import '../../services/view_service.dart';
import '../../widgets/suspension_wrapper.dart';
import '../../widgets/subscription_banner.dart';

class AdminPropertiesScreen extends StatefulWidget {
  const AdminPropertiesScreen({super.key});

  @override
  State<AdminPropertiesScreen> createState() => _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends State<AdminPropertiesScreen> {
  final _service = SupabaseService();
  List<Property> _properties = [];
  bool _isLoading = true;
  RealtimeChannel? _subscription;
  Map<String, int> _likeCounts = {};
  Map<String, int> _viewCounts = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedStatusFilter = "all";

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _subscription = Supabase.instance.client
        .channel('public:admin_properties')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'properties',
            callback: (payload) => _loadProperties())
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'property_details',
            callback: (payload) => _loadProperties())
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'gallery',
            callback: (payload) => _loadProperties())
        .subscribe();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
      final response = await _service.getAllProperties(companyId);
      
      final propertyIds = response.map((p) => p.id!).toList();
      final counts = await LikeService.batchGetLikeCounts(propertyIds);
      final viewCounts = await ViewService.batchGetViewCounts(propertyIds);

      setState(() {
        _properties = response;
        _likeCounts = counts;
        _viewCounts = viewCounts;
      });
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

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final l10n = AppLocalizations.of(context);
    final company = Provider.of<CompanyProvider>(context).company;
    final activePropertiesCount = _properties.where((p) => p.status != 'Vendido' && p.status != 'Alquilado').length;
    final bool limitReached = activePropertiesCount >= company.totalAllowedProperties;

    final filteredProperties = _properties.where((p) {
      final query = _searchQuery.toLowerCase();
      final title = p.title.toLowerCase();
      final ref = p.refNumber?.toString().padLeft(3, '0').toLowerCase() ?? "";
      
      final matchesSearch = title.contains(query) || ref.contains(query);
      final matchesStatus = _selectedStatusFilter == 'all' || p.status == _selectedStatusFilter;
      
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('spaces')),
        backgroundColor: company.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: limitReached ? Colors.orange.shade100 : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: limitReached ? Colors.orange : Colors.transparent),
                ),
                child: Text(
                  '$activePropertiesCount / ${company.totalAllowedProperties}',
                  style: TextStyle(
                    color: limitReached ? Colors.orange.shade900 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: SuspensionWrapper(
        child: Column(
          children: [
            SubscriptionBanner(company: company),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: SizedBox(
                  width: 480,
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.get('search'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      _buildFilterChip('all', l10n.get('filter_all')),
                      _buildFilterChip('Disponible', l10n.get('Disponible')),
                      _buildFilterChip('Reservado', l10n.get('Reservado')),
                      _buildFilterChip('Vendido', l10n.get('Vendido')),
                      _buildFilterChip('Alquilado', l10n.get('Alquilado')),
                    ],
                  ),
                ),
              ),
            ),
            _isLoading
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : filteredProperties.isEmpty
                    ? Expanded(child: Center(child: Text(l10n.get('no_results'))))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: filteredProperties.length,
                          itemBuilder: (context, index) {
                            final property = filteredProperties[index];
                            return ListTile(
                      leading: property.imageUrls.isNotEmpty
                          ? Image.network(property.imageUrls.first, width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.business),
                      title: Text(property.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ref: ${property.refNumber?.toString().padLeft(3, '0') ?? '---'} - ${Provider.of<CompanyProvider>(context, listen: false).currencySymbol}${NumberFormat("#,###.##").format(property.price)} - ${l10n.get(property.status)}'),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${l10n.locale.languageCode == 'es' ? 'Captador' : 'Listing Agent'}: ${property.listingAgentName ?? '---'}',
                                  style: TextStyle(fontSize: 10, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.thumb_up, 
                                    size: 14, 
                                    color: (_likeCounts[property.id] ?? 0) > 0 ? Colors.blue : Colors.grey
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_likeCounts[property.id] ?? 0} likes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: (_likeCounts[property.id] ?? 0) > 0 ? Colors.blue : Colors.grey,
                                      fontWeight: (_likeCounts[property.id] ?? 0) > 0 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility, 
                                    size: 14, 
                                    color: (_viewCounts[property.id] ?? 0) > 0 ? Colors.teal : Colors.grey
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_viewCounts[property.id] ?? 0} vistas',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: (_viewCounts[property.id] ?? 0) > 0 ? Colors.teal : Colors.grey,
                                      fontWeight: (_viewCounts[property.id] ?? 0) > 0 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (appProvider.userProfile?.role != 'agent' || property.listingAgentId == appProvider.userProfile?.id) ...[
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PropertyEditorScreen(property: property),
                                ),
                              ).then((_) => _loadProperties()),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(l10n.get('delete')),
                                    content: Text(l10n.get('delete_confirm_short')),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text(l10n.get('cancel')),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text(l10n.get('delete')),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _service.deleteProperty(property.id);
                                  _loadProperties();
                                }
                              },
                            ),
                          ] else ...[
                            const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                          ],
                        ],
                      ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
      floatingActionButton: company.subscriptionStatus == 'suspended' 
        ? null 
        : FloatingActionButton(
        onPressed: limitReached 
          ? () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.get('limit_reached_msg') ?? 'Límite de inmuebles alcanzado. ¡Refiere a otro corredor para ganar +2 cupos!'),
                backgroundColor: Colors.orange,
              )
            )
          : () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PropertyEditorScreen()),
            ).then((_) => _loadProperties()),
        backgroundColor: limitReached ? Colors.grey : company.primaryColor,
        child: Icon(limitReached ? Icons.lock : Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final company = Provider.of<CompanyProvider>(context, listen: false).company;
    final isSelected = _selectedStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: company.primaryColor,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedStatusFilter = value;
            });
          }
        },
      ),
    );
  }
}

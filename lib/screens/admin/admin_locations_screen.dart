import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/location_data.dart';
import '../../services/app_themes.dart';
import '../../services/app_localizations.dart';
import '../../services/app_provider.dart';
import '../../providers/company_provider.dart';
import 'package:provider/provider.dart';

class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key});

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> with SingleTickerProviderStateMixin {
  // We keep a local mutable copy of the JSON structure
  late Map<String, Map<String, List<String>>> _editableData;
  String? _selectedCountry;
  String? _selectedState;
  bool _isSaving = false;
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _cloneData();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _cloneData() {
    // Deep clone the data from LocationData to allow safe editing
    _editableData = {};
    for (var c in LocationData.countries) {
      _editableData[c] = {};
      for (var s in LocationData.statesFor(c)) {
        _editableData[c]![s] = List<String>.from(LocationData.citiesFor(c, s));
      }
    }
  }

  Future<void> _saveToSupabase() async {
    final l10n = AppLocalizations.of(context);
    final isSuper = context.read<AppProvider>().isSuperAdmin;
    final companyProvider = context.read<CompanyProvider>();
    
    // Locations is a GLOBAL catalog shared across all agencies.
    // Always write to the global record (company_id = NULL).
    const String? targetCompanyId = null;

    debugPrint('[Locations] isSuperAdmin=$isSuper  isDemo=${companyProvider.isDemo}  targetCompanyId=$targetCompanyId');

    setState(() => _isSaving = true);
    try {
      final result = await Supabase.instance.client
          .from('app_settings')
          .upsert({
            'key': 'locations',
            'value': _editableData,
            'company_id': targetCompanyId,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'key')
          .select();

      debugPrint('[Locations] upsert result rows: ${result.length}');

      if (result.isEmpty) {
        throw Exception('Sin permiso para guardar ubicaciones globales. Contacta al Super Admin.');
      }

      LocationData.updateData(_editableData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('save_success'))),
        );
      }
    } catch (e) {
      debugPrint('[Locations] ERROR al guardar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.get('error_saving')}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addCountry() {
    final l10n = AppLocalizations.of(context);
    _promptInput(l10n.get('add_new_country'), (value) {
      if (!_editableData.containsKey(value)) {
        setState(() {
          _editableData[value] = {};
          _selectedCountry = value;
          _selectedState = null;
        });
        _saveToSupabase();
      }
    });
  }

  void _addState() {
    final l10n = AppLocalizations.of(context);
    if (_selectedCountry == null) return;
    _promptInput('${l10n.get('add_state_to')} $_selectedCountry', (value) {
      if (!_editableData[_selectedCountry]!.containsKey(value)) {
        setState(() {
          _editableData[_selectedCountry]![value] = [];
          _selectedState = value;
        });
        _saveToSupabase();
      }
    });
  }

  void _addCity() {
    final l10n = AppLocalizations.of(context);
    if (_selectedCountry == null || _selectedState == null) return;
    _promptInput('${l10n.get('add_city_to')} $_selectedState', (value) {
      if (!_editableData[_selectedCountry]![_selectedState]!.contains(value)) {
        setState(() {
          _editableData[_selectedCountry]![_selectedState]!.add(value);
          _editableData[_selectedCountry]![_selectedState]!.sort();
        });
        _saveToSupabase();
      }
    });
  }

  void _promptInput(String title, Function(String) onSubmit) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF001A0D) : Colors.white,
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: l10n.get('name_hint'),
            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.get('cancel'), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) {
                onSubmit(val);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppThemes.primaryGreen),
            child: Text(l10n.get('add'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndDelete(String field, String value, String confirmMsg, VoidCallback onConfirm) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('properties')
          .select('id')
          .eq(field, value);
      
      final count = (response as List).length;
      
      setState(() => _isSaving = false);

      if (count > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.get('location_has_props', [value, count])),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        _confirmDelete(confirmMsg, onConfirm);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDelete(String message, VoidCallback onConfirm) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF001A0D) : Colors.white,
        title: Text(l10n.get('confirm_delete'), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Text(message, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.get('cancel'), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.get('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isSuper = appProvider.isSuperAdmin;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countries = _editableData.keys.toList()..sort();
    
    List<String> states = [];
    if (_selectedCountry != null) {
      states = (_editableData[_selectedCountry]?.keys.toList() ?? [])..sort();
    }
    
    List<String> cities = [];
    if (_selectedCountry != null && _selectedState != null) {
      cities = List<String>.from(_editableData[_selectedCountry]![_selectedState] ?? [])..sort();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final minWidthPerColumn = 350.0;
    final totalMinWidth = minWidthPerColumn * 3;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.get('locations_manager')),
        backgroundColor: isDark ? const Color(0xFF001A0D) : AppThemes.primaryGreen,
        foregroundColor: Colors.white,
        bottom: isMobile
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3.0,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: l10n.get('country_field')),
                  Tab(text: l10n.get('state_field')),
                  Tab(text: l10n.get('city_field')),
                ],
              )
            : null,
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: AppThemes.primaryGreen, strokeWidth: 2)))
          else
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white), // Fixed color for visibility
              onPressed: _saveToSupabase,
              tooltip: l10n.get('save_changes'),
            ),
        ],
      ),
      body: isMobile
          ? TabBarView(
              controller: _tabController,
              children: [
                // COUNTRY COLUMN
                _buildColumn(
                  title: l10n.get('country_field'),
                  items: countries,
                  selectedItem: _selectedCountry,
                  onSelect: (val) {
                    setState(() {
                      _selectedCountry = val;
                      _selectedState = null;
                    });
                    _tabController.animateTo(1); // Auto transition to States
                  },
                  onAdd: isSuper ? _addCountry : null,
                  onDelete: isSuper ? (val) {
                    _checkAndDelete('country', val, l10n.get('sure_delete_country').replaceFirst('$val', val), () {
                      setState(() {
                        _editableData.remove(val);
                        if (_selectedCountry == val) {
                          _selectedCountry = null;
                          _selectedState = null;
                        }
                      });
                    });
                  } : null,
                ),
                // STATE COLUMN
                _selectedCountry == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                              const SizedBox(height: 16),
                              Text(
                                l10n.get('select_country'),
                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 16, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildColumn(
                        title: l10n.get('state_field'),
                        items: states,
                        selectedItem: _selectedState,
                        onSelect: (val) {
                          setState(() {
                            _selectedState = val;
                          });
                          _tabController.animateTo(2); // Auto transition to Cities
                        },
                        onAdd: _addState,
                        onDelete: isSuper ? (val) {
                          _checkAndDelete('state', val, l10n.get('sure_delete_state').replaceFirst('$val', val), () {
                             setState(() {
                              _editableData[_selectedCountry]!.remove(val);
                              if (_selectedState == val) {
                                _selectedState = null;
                              }
                            });
                          });
                        } : null,
                      ),
                // CITY COLUMN
                _selectedState == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_city, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                              const SizedBox(height: 16),
                              Text(
                                l10n.get('select_state'),
                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 16, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildColumn(
                        title: l10n.get('city_field'),
                        items: cities,
                        selectedItem: null,
                        onSelect: (val) {},
                        onAdd: _addCity,
                        onDelete: isSuper ? (val) {
                          _checkAndDelete('city', val, l10n.get('sure_delete_city').replaceFirst('$val', val), () {
                            setState(() {
                              _editableData[_selectedCountry]![_selectedState]!.remove(val);
                            });
                          });
                        } : null,
                      ),
              ],
            )
          : Scrollbar(
              thumbVisibility: true,
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: screenWidth > totalMinWidth ? screenWidth : totalMinWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // COLUMNA PAÍSES
                      Expanded(
                        child: _buildColumn(
                          title: l10n.get('country_field'),
                          items: countries,
                          selectedItem: _selectedCountry,
                          onSelect: (val) => setState(() {
                            _selectedCountry = val;
                            _selectedState = null;
                          }),
                          onAdd: isSuper ? _addCountry : null,
                          onDelete: isSuper ? (val) {
                            _checkAndDelete('country', val, l10n.get('sure_delete_country').replaceFirst('$val', val), () {
                              setState(() {
                                _editableData.remove(val);
                                if (_selectedCountry == val) {
                                  _selectedCountry = null;
                                  _selectedState = null;
                                }
                              });
                            });
                          } : null,
                        ),
                      ),
                      Container(width: 1, color: isDark ? Colors.white10 : Colors.black12),
                      
                      // COLUMNA ESTADOS
                      Expanded(
                        child: _selectedCountry == null
                            ? Center(child: Text(l10n.get('select_country'), style: TextStyle(color: isDark ? Colors.white24 : Colors.black26)))
                            : _buildColumn(
                                title: l10n.get('state_field'),
                                items: states,
                                selectedItem: _selectedState,
                                onSelect: (val) => setState(() => _selectedState = val),
                                onAdd: _addState,
                                onDelete: isSuper ? (val) {
                                  _checkAndDelete('state', val, l10n.get('sure_delete_state').replaceFirst('$val', val), () {
                                     setState(() {
                                      _editableData[_selectedCountry]!.remove(val);
                                      if (_selectedState == val) {
                                        _selectedState = null;
                                      }
                                    });
                                  });
                                } : null,
                              ),
                      ),
                      Container(width: 1, color: isDark ? Colors.white10 : Colors.black12),
                      
                      // COLUMNA CIUDADES
                      Expanded(
                        child: _selectedState == null
                            ? Center(child: Text(l10n.get('select_state'), style: TextStyle(color: isDark ? Colors.white24 : Colors.black26)))
                            : _buildColumn(
                                title: l10n.get('city_field'),
                                items: cities,
                                selectedItem: null,
                                onSelect: (val) {}, // nothing on select
                                onAdd: _addCity,
                                onDelete: isSuper ? (val) {
                                  _checkAndDelete('city', val, l10n.get('sure_delete_city').replaceFirst('$val', val), () {
                                    setState(() {
                                      _editableData[_selectedCountry]![_selectedState]!.remove(val);
                                    });
                                  });
                                } : null,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildColumn({
    required String title,
    required List<String> items,
    required String? selectedItem,
    required Function(String) onSelect,
    required VoidCallback? onAdd,
    required Function(String)? onDelete,
  }) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: (isDark ? const Color(0xFF001A0D) : AppThemes.primaryGreen).withValues(alpha: 0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: isDark ? Colors.white : AppThemes.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
              if (onAdd != null)
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppThemes.primaryGreen),
                  onPressed: onAdd,
                  tooltip: l10n.get('add'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (ctx, index) {
              final item = items[index];
              final isSelected = item == selectedItem;
              return ListTile(
                title: Text(item, style: TextStyle(color: isSelected ? AppThemes.primaryGreen : (isDark ? Colors.white70 : Colors.black87))),
                tileColor: isSelected ? (isDark ? Colors.white.withValues(alpha: 0.05) : AppThemes.primaryGreen.withValues(alpha: 0.05)) : null,
                onTap: () => onSelect(item),
                trailing: onDelete == null 
                  ? null 
                  : IconButton(
                    icon: Icon(Icons.delete_outline, color: isDark ? Colors.white24 : Colors.black26, size: 20),
                    onPressed: () => onDelete(item),
                  ),
              );
            },
          ),
        ),
      ],
    );
  }
}

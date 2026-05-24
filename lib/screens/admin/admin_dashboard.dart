import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin_drawer.dart';
import '../../services/app_localizations.dart';
import '../../services/app_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../services/app_themes.dart';
import '../../providers/company_provider.dart';
import '../../services/like_service.dart';
import '../../services/view_service.dart';
import '../../models/property.dart';
import '../../widgets/suspension_wrapper.dart';
import '../../widgets/subscription_banner.dart';
import '../../widgets/commission_chart.dart';
import '../commissions_list_screen.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _service = SupabaseService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  RealtimeChannel? _subscription;
  List<Map<String, dynamic>> _topLikedList = [];
  List<Map<String, dynamic>> _topViewedList = [];
  DateTime? _startDate;
  DateTime? _endDate;
  int _referralCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _subscription = Supabase.instance.client
        .channel('public:admin_dashboard')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'properties',
            callback: (payload) => _load())
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'owners',
            callback: (payload) => _load())
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'budget_requests',
            callback: (payload) => _load())
        .subscribe();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      final companyId = companyProvider.companyId;
      
      // Refrescar datos de la empresa para el banner de suscripción
      await companyProvider.refresh();
      
      final appProv = Provider.of<AppProvider>(context, listen: false);
      final agentId = appProv.userProfile?.role == 'agent' ? appProv.userProfile?.id : null;
      
      final stats = await _service.getDashboardStats(companyId, startDate: _startDate, endDate: _endDate, agentId: agentId);
      
      // Load top popular properties
      final topData = await LikeService.getTopLikedProperties(companyId, limit: 5);
      final propertyIds = topData.map((d) => d['id'] as String).toList();
      final counts = await LikeService.batchGetLikeCounts(propertyIds);
      
      final topMapped = topData.map((d) {
        final p = Property.fromJson(d);
        return {
          'name': p.title.length > 25 ? '${p.title.substring(0, 25)}...' : p.title,
          'count': counts[p.id] ?? 0,
        };
      }).toList();

      // Load top viewed properties
      final viewedData = await ViewService.getTopViewedProperties(companyId, limit: 5);
      final viewedIds = viewedData.map((d) => d['id'] as String).toList();
      final viewCounts = await ViewService.batchGetViewCounts(viewedIds);

      final topViewedMapped = viewedData.map((d) {
        final p = Property.fromJson(d);
        return {
          'name': p.title.length > 25 ? '${p.title.substring(0, 25)}...' : p.title,
          'count': viewCounts[p.id] ?? 0,
        };
      }).toList();

      final refCount = await _service.getReferralCount(companyId);

      if (mounted) {
        setState(() {
          _stats = stats;
          _topLikedList = topMapped;
          _topViewedList = topViewedMapped;
          _referralCount = refCount;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppThemes.primaryGreen,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _load();
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isSpanish = appProvider.locale.languageCode == 'es';
    final l10n = AppLocalizations.of(context);
    final isMobile = MediaQuery.of(context).size.width < 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? Colors.greenAccent : AppThemes.primaryGreen;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n.get('admin_panel')),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearDateRange,
              tooltip: l10n.get('clear_filter'),
            ),
          IconButton(
            icon: Icon(_startDate == null ? Icons.date_range : Icons.date_range_sharp, 
                 color: _startDate != null ? AppThemes.primaryGreen : null),
            onPressed: _selectDateRange,
            tooltip: l10n.get('filter_by_date'),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      drawer: const AdminDrawer(),
      body: SuspensionWrapper(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SubscriptionBanner(company: Provider.of<CompanyProvider>(context).company),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.get('summary_title'),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                        ),
                        if (!isMobile)
                          Text(
                            '${appProvider.userProfile?.role == 'agent' ? (isSpanish ? 'Mis Propiedades' : 'My Properties') : l10n.get('total_properties')}: ${_stats?['total_properties'] ?? 0}',
                            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // --- Inventory Distribution Sector ---
                    _sectionHeader(l10n.get('prop_type'), Icons.category),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildSummaryCard(
                          context, isMobile, Icons.check_circle, 
                          '${_stats?['status_stats']?['Disponible'] ?? 0}', 
                          appProvider.userProfile?.role == 'agent' ? (isSpanish ? 'Disponibles (Mías)' : 'Available (Mine)') : l10n.get('st_available'), 
                          AppThemes.primaryGreen,
                        ),
                        _buildSummaryCard(
                          context, isMobile, Icons.home, 
                          '${_stats?['res_count'] ?? 0}', 
                          appProvider.userProfile?.role == 'agent' ? (isSpanish ? 'Residencial (Mío)' : 'Residential (Mine)') : l10n.get('res_inventory'), 
                          const Color(0xFF4CAF50),
                          subtitle: '${l10n.get('avg_res_area')}: ${NumberFormat('#,###.##').format(_stats?['avg_res_area'] ?? 0)} m²',
                        ),
                        _buildSummaryCard(
                          context, isMobile, Icons.business, 
                          '${_stats?['comm_count'] ?? 0}', 
                          appProvider.userProfile?.role == 'agent' ? (isSpanish ? 'Comercial (Mío)' : 'Commercial (Mine)') : l10n.get('comm_inventory'), 
                          const Color(0xFF2196F3),
                          subtitle: '${l10n.get('avg_comm_area')}: ${NumberFormat('#,###.##').format(_stats?['avg_comm_area'] ?? 0)} m²',
                        ),
                        _buildSummaryCard(
                          context, isMobile, Icons.group_add, 
                          '$_referralCount', 
                          l10n.get('successful_referrals'), 
                          const Color(0xFF8BC34A),
                        ),
                        _buildSummaryCard(
                          context, isMobile, Icons.people, 
                          '${_stats?['owners_count'] ?? 0}', 
                          l10n.get('owners'), 
                          const Color(0xFFFF9800),
                        ),
                        _buildSummaryCard(
                          context, isMobile, Icons.email, 
                          '${_stats?['leads_count'] ?? 0}', 
                          appProvider.userProfile?.role == 'agent' ? (isSpanish ? 'Mis Leads' : 'My Leads') : l10n.get('leads_count'), 
                          const Color(0xFFE91E63),
                        ),
                        if (appProvider.userProfile?.role != 'agent')
                          _buildSummaryCard(
                            context, isMobile, Icons.support_agent, 
                            '${_stats?['agents_count'] ?? 0}', 
                            l10n.get('agents'), 
                            const Color(0xFF673AB7),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // --- Financial Summary Sector ---
                    _sectionHeader(l10n.get('commissions'), Icons.account_balance_wallet),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildSummaryCard(
                          context, isMobile, Icons.payments, 
                          '${Provider.of<CompanyProvider>(context, listen: false).currencySymbol}${NumberFormat('#,###.##').format(_stats?['commissions_total'] ?? 0)}', 
                          appProvider.userProfile?.role == 'agent' ? (isSpanish ? 'Mis Comisiones' : 'My Commissions') : l10n.get('total_collected'), 
                          Colors.teal,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommissionsListScreen())),
                        ),
                        _buildSummaryCard(
                          context, isMobile, Icons.account_balance, 
                          '${Provider.of<CompanyProvider>(context, listen: false).currencySymbol}${NumberFormat('#,###.##').format(_stats?['agency_retention_total'] ?? 0)}', 
                          appProvider.userProfile?.role == 'agent' ? (isSpanish ? 'Retención Agencia' : 'Agency Retention') : l10n.get('agency_retention'), 
                          Colors.indigo,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommissionsListScreen(initialStatus: 'collected'))),
                        ),
                        _buildSummaryCard(
                          context, isMobile, Icons.hourglass_bottom, 
                          '${Provider.of<CompanyProvider>(context, listen: false).currencySymbol}${NumberFormat('#,###.##').format(_stats?['pending_agent_payouts'] ?? 0)}', 
                          appProvider.userProfile?.role == 'agent' ? (isSpanish ? 'Por Cobrar' : 'Pending Payout') : l10n.get('pending_payouts'), 
                          Colors.deepOrange,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommissionsListScreen(initialStatus: 'pending'))),
                        ),
                      ],
                    ),

                    if (_stats?['commissions_by_month'] != null && (_stats!['commissions_by_month'] as Map).isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _sectionHeader(l10n.get('commissions_trend'), Icons.trending_up),
                      const SizedBox(height: 12),
                      Container(
                        height: 300,
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: CommissionChart(
                          data: _stats!['commissions_by_month'] as Map<String, Map<String, double>>,
                          isDark: isDark,
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    const SizedBox(height: 8),
                    const SizedBox(height: 40),
                    
                    // Main Statistics Charts
                    _sectionHeader(l10n.get('amenities_title'), Icons.star_border),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.start,
                      children: [
                        _buildStatSection(
                          context: context,
                          isMobile: isMobile,
                          title: l10n.get('availability'),
                          icon: Icons.check_circle_outline,
                          total: _stats?['total_properties'] ?? 1,
                          statsMap: _stats?['status_stats'] ?? {},
                          colorsMap: {
                            'Disponible': Colors.green,
                            'Reservado': Colors.orange,
                            'Vendido/Alquilado': Colors.red,
                          },
                        ),
                        _buildStatSection(
                          context: context,
                          isMobile: isMobile,
                          title: l10n.get('dist_by_op'),
                          icon: Icons.sell_outlined,
                          total: _stats?['total_properties'] ?? 1,
                          statsMap: _stats?['op_stats'] ?? {},
                          colorsMap: {
                            'Venta': Colors.indigo,
                            'Alquiler': Colors.deepOrange,
                          },
                        ),
                        _buildStatSection(
                          context: context,
                          isMobile: isMobile,
                          title: l10n.get('amenities_title'),
                          icon: Icons.auto_awesome_outlined,
                          total: _stats?['total_properties'] ?? 1,
                          statsMap: _stats?['amenity_stats'] ?? {},
                            colorsMap: {
                              'Piscina': Colors.blue,
                              'Terraza': Colors.orange,
                              'Balcón': Colors.teal,
                              'Garaje': Colors.grey,
                              'Seguridad': Colors.red,
                              'Frente al mar': Colors.cyan,
                              'Amoblado': Colors.purple,
                              'Parrillera': Colors.deepOrange,
                              'Planta Eléctrica': Colors.amber,
                              'Tanque de Agua': Colors.lightBlue,
                              'Cocina': Colors.brown,
                              'Sótano': Colors.blueGrey,
                            },
                        ),
                      ],
                    ),

                    // Listados en dos columnas en desktop, en móvil apilados
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final showColumns = width > 800; // umbral para poner lado a lado
                        
                        // Extract lists
                        final ownerList = (_stats?['owner_stats'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                        final cityList = (_stats?['city_stats'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                        
                        if (showColumns) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildTopList(
                                title: l10n.get('top_owners'), icon: Icons.person, items: ownerList, 
                                context: context, accentColor: accentColor, isDark: isDark, valueLabel: l10n.get('props')
                              )),
                              const SizedBox(width: 48),
                              Expanded(child: _buildTopList(
                                title: l10n.get('dist_by_city'), icon: Icons.location_city, items: cityList, 
                                context: context, accentColor: const Color(0xFFE91E63), isDark: isDark, valueLabel: l10n.get('props')
                              )),
                              const SizedBox(width: 48),
                              Expanded(child: _buildTopList(
                                title: l10n.get('popular_likes'), icon: Icons.thumb_up, items: _topLikedList, 
                                context: context, accentColor: Colors.blue, isDark: isDark, valueLabel: 'likes'
                              )),
                              const SizedBox(width: 48),
                              Expanded(child: _buildTopList(
                                title: l10n.get('popular_views'), icon: Icons.visibility, items: _topViewedList, 
                                context: context, accentColor: Colors.teal, isDark: isDark, valueLabel: 'vistas'
                              )),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopList(
                                title: l10n.get('top_owners'), icon: Icons.person, items: ownerList, 
                                context: context, accentColor: accentColor, isDark: isDark, valueLabel: l10n.get('props')
                              ),
                              const SizedBox(height: 48),
                              _buildTopList(
                                title: l10n.get('dist_by_city'), icon: Icons.location_city, items: cityList, 
                                context: context, accentColor: const Color(0xFFE91E63), isDark: isDark, valueLabel: l10n.get('props')
                              ),
                              const SizedBox(height: 48),
                              _buildTopList(
                                title: l10n.get('popular_likes'), icon: Icons.thumb_up, items: _topLikedList, 
                                context: context, accentColor: Colors.blue, isDark: isDark, valueLabel: 'likes'
                              ),
                              const SizedBox(height: 48),
                              _buildTopList(
                                title: l10n.get('popular_views'), icon: Icons.visibility, items: _topViewedList, 
                                context: context, accentColor: Colors.teal, isDark: isDark, valueLabel: 'vistas'
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildTopList({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required BuildContext context,
    required Color accentColor,
    required bool isDark,
    required String valueLabel,
  }) {
    final l10n = AppLocalizations.of(context);
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title, icon),
        const SizedBox(height: 16),
        ...items.map((item) => Card(
              elevation: 0,
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isDark ? accentColor.withValues(alpha: 0.2) : const Color(0xFF1A1A1A),
                  foregroundColor: isDark ? accentColor : Colors.white,
                  child: Icon(icon, size: 22),
                ),
                title: Text(item['name'] ?? l10n.get('unknown'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${item['count']} $valueLabel",
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: AppThemes.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: isDark ? Colors.white38 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, bool isMobile, IconData icon, String value, String label, Color color, {String? subtitle, VoidCallback? onTap}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: isMobile ? double.infinity : (subtitle != null ? 220 : 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 16),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatSection({
    required BuildContext context,
    required bool isMobile,
    required String title,
    required IconData icon,
    required int total,
    required Map<String, dynamic> statsMap,
    required Map<String, Color> colorsMap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: isMobile ? double.infinity : 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppThemes.primaryGreen),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF003366))),
            ],
          ),
          const SizedBox(height: 24),
          ...statsMap.entries.map((entry) {
            final label = AppLocalizations.of(context).get(entry.key);
            final count = entry.value as int;
            final color = colorsMap[entry.key] ?? Colors.grey;
            final pct = total > 0 ? (count / total) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87)),
                      Text('$count (${NumberFormat('#,###.##').format(pct * 100)}%)', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}


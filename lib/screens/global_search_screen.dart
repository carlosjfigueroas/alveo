import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property.dart';
import '../models/company.dart';
import '../models/property_filter.dart';
import '../services/supabase_service.dart';
import '../services/company_service.dart';
import '../services/app_provider.dart';
import '../services/app_localizations.dart';
import '../providers/company_provider.dart';
import '../services/app_themes.dart';
import '../widgets/property_card.dart';
import '../widgets/filter_panel.dart';
import '../widgets/main_drawer.dart';
import 'login_screen.dart';
import 'about_screen.dart';
import 'faq_screen.dart';
import 'admin/admin_dashboard.dart';
import 'admin/super_admin_dashboard.dart';
import '../services/visitor_service.dart';
import '../widgets/visitor_badge.dart';
import '../services/like_service.dart';
import '../services/view_service.dart';
import '../widgets/contact_dialog.dart';


/// Pantalla de búsqueda global — se activa cuando isGlobalMode = true.
/// Muestra inmuebles de TODAS las empresas activas con filtro por empresa.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _service = SupabaseService();
  List<Property> _allProperties = [];
  List<Company> _companies = [];
  Company? _selectedCompany; // null = todas
  bool _isLoading = true;
  PropertyFilter _activeFilter = PropertyFilter();
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  Map<String, int> _likeCounts = {};
  Map<String, int> _viewCounts = {};
  Set<String> _likedByMe = {};
  String? _visitorId;

  int _weeklyVisitors = 0;
  bool _isVisitorsLoading = true;

  List<Property> get _filtered {
    var list = _allProperties.where((p) {
      if (_selectedCompany != null && p.companyId != _selectedCompany!.id) return false;
      if (_searchQuery.isNotEmpty) {
        final normalize = (String? s) {
          if (s == null) return '';
          var str = s.trim().toLowerCase();
          str = str.replaceAll(RegExp(r'[áàäâ]'), 'a');
          str = str.replaceAll(RegExp(r'[éèëê]'), 'e');
          str = str.replaceAll(RegExp(r'[íìïî]'), 'i');
          str = str.replaceAll(RegExp(r'[óòöô]'), 'o');
          str = str.replaceAll(RegExp(r'[úùüû]'), 'u');
          str = str.replaceAll(RegExp(r'[ñ]'), 'n');
          return str;
        };

        final q = normalize(_searchQuery);
        if (!(normalize(p.title).contains(q) ||
            normalize(p.description).contains(q) ||
            normalize(p.address).contains(q))) return false;
      }
      return _activeFilter.isEmpty || _activeFilter.matches(p);
    }).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getAllPropertiesGlobal(),
        CompanyService.getAllCompanies(),
      ]);
      if (mounted) {
        setState(() {
          _allProperties = results[0] as List<Property>;
          _companies = results[1] as List<Company>;
        });

        // Load Likes and Views
        _visitorId ??= LikeService.getOrCreateVisitorId();
        final propertyIds = _allProperties.map((p) => p.id!).toList();
        
        final likesFuture = LikeService.batchGetLikeCounts(propertyIds);
        final viewsFuture = ViewService.batchGetViewCounts(propertyIds);
        final likedByMeFuture = LikeService.batchGetLikedByVisitor(_visitorId!, propertyIds);

        final statsResults = await Future.wait([likesFuture, viewsFuture, likedByMeFuture]);

        if (mounted) {
          setState(() {
            _likeCounts = statsResults[0] as Map<String, int>;
            _viewCounts = statsResults[1] as Map<String, int>;
            _likedByMe = statsResults[2] as Set<String>;
          });
        }

        // Register visit and get count
        if (_isVisitorsLoading) {
          final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
          final vId = LikeService.getOrCreateVisitorId();
          await VisitorService.registerVisit(visitorId: vId, companyId: companyId);
          final count = await VisitorService.getWeeklyCount(companyId);
          if (mounted) {
             setState(() {
               _weeklyVisitors = count;
               _isVisitorsLoading = false;
             });
          }
        }
      }
    } catch (e) {
      debugPrint('GlobalSearch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchCompanyDomain(Company company) async {
    final url = 'https://${company.domain}';
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<PropertyFilter>(
      context: context,
      builder: (_) => FilterPanel(initialFilter: _activeFilter),
    );
    if (result != null) setState(() => _activeFilter = result);
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const ContactFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final l10n = AppLocalizations(appProvider.locale);
    final companyProv = context.watch<CompanyProvider>();
    final company = companyProv.currentCompany;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isDesktop = !isMobile;
    final isSpanish = appProvider.locale.languageCode == 'es';
    final filtered = _filtered;

    return Scaffold(
      drawer: isMobile ? const MainDrawer() : null,
      body: CustomScrollView(
        slivers: [
          // ── Cabecera tipo SliverAppBar ──────────────────────────────────
          SliverAppBar(
            titleSpacing: isMobile ? 0 : 16,
            pinned: true,
            automaticallyImplyLeading: false, // Custom hamburger on Mobile
            leadingWidth: isMobile ? 36 : 56,
            leading: isMobile ? Builder(
              builder: (context) => IconButton(
                padding: const EdgeInsets.only(left: 4),
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ) : null,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo: Full on Desktop, Abbr on Mobile
                      isDesktop 
                          ? (company.logoUrl != null
                              ? Image.network(company.logoUrl!, height: 32, fit: BoxFit.contain)
                              : Image.asset('assets/images/logo_full.png', height: 32, fit: BoxFit.contain))
                          : (company.logoAbbrUrl != null
                              ? Image.network(company.logoAbbrUrl!, height: 26, fit: BoxFit.contain)
                              : Image.asset('assets/images/logo_abbr.png', height: 26, fit: BoxFit.contain)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          companyProv.companyLocalizedName(appProvider.locale.languageCode),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                VisitorBadge(count: _weeklyVisitors, isLoading: _isVisitorsLoading),
              ],
            ),
            centerTitle: true,
            actions: [
              if (isDesktop) ...[
                // Web Nav Links (Moved to right)
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                  child: Text(l10n.get('about'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen())),
                  child: Text(l10n.get('faq'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 8),
              ],
              // Social Icons (Monochromatic)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(onTap: () => _launchURL(company.instagramUrl ?? 'https://instagram.com'), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 3), child: FaIcon(FontAwesomeIcons.instagram, color: Colors.white, size: 18))),
                  InkWell(onTap: () => _launchURL(company.facebookUrl ?? 'https://facebook.com'), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 3), child: FaIcon(FontAwesomeIcons.facebook, color: Colors.white, size: 18))),
                  InkWell(onTap: () => _launchURL(company.telegramUrl ?? 'https://telegram.org'), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 3), child: FaIcon(FontAwesomeIcons.telegram, color: Colors.white, size: 18))),
                  if (company.contactEmail != null)
                    InkWell(onTap: () => _showContactDialog(), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.email, color: Colors.white, size: 20))),
                  InkWell(onTap: () => _launchURL('https://wa.me/${company.contactWhatsapp ?? ""}'), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 3), child: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 18))),
                  const SizedBox(width: 8),
                ],
              ),

              if (isDesktop) ...[
                const VerticalDivider(color: Colors.white24, indent: 12, endIndent: 12),
                // Theme Toggle
                IconButton(
                  tooltip: appProvider.themeMode == ThemeMode.light ? l10n.get('dark_mode') : l10n.get('light_mode'),
                  icon: Icon(appProvider.themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode),
                  onPressed: () => appProvider.toggleTheme(),
                ),
                // Language Toggle
                TextButton(
                  onPressed: () => appProvider.setLocale(isSpanish ? const Locale('en') : const Locale('es')),
                  child: Text(isSpanish ? 'EN' : 'ES', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const VerticalDivider(color: Colors.white24, indent: 12, endIndent: 12),
                if (appProvider.userProfile?.role == 'super_admin')
                  IconButton(
                    tooltip: 'Súper Panel',
                    icon: const Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperAdminDashboard())),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
                  onSelected: (val) async {
                    if (val == 'admin') Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
                    else if (val == 'super') Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperAdminDashboard()));
                    else if (val == 'theme') appProvider.toggleTheme();
                    else if (val == 'lang') appProvider.setLocale(isSpanish ? const Locale('en') : const Locale('es'));
                    else if (val == 'login') {
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: const SizedBox(width: 400, child: LoginScreen()),
                        ),
                      );
                    }
                    else if (val == 'logout') await appProvider.signOut();
                  },
                  itemBuilder: (ctx) => [
                    if (appProvider.userProfile == null) ...[
                      PopupMenuItem(value: 'login', child: ListTile(leading: const Icon(Icons.login), title: Text(l10n.get('login')))),
                    ] else ...[
                      PopupMenuItem(enabled: false, child: Text(appProvider.userProfile!.fullName ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold))),
                      const PopupMenuDivider(),
                      if (appProvider.isAdmin) PopupMenuItem(value: 'admin', child: ListTile(leading: const Icon(Icons.admin_panel_settings), title: Text(l10n.get('admin_panel')))),
                      if (appProvider.isSuperAdmin) PopupMenuItem(value: 'super', child: ListTile(leading: const Icon(Icons.auto_awesome, color: Colors.amber), title: const Text('Súper Panel', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)))),
                      const PopupMenuDivider(),
                      PopupMenuItem(value: 'lang', child: ListTile(leading: const Icon(Icons.language), title: Text(isSpanish ? 'English' : 'Español'))),
                      PopupMenuItem(value: 'theme', child: ListTile(leading: Icon(appProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode), title: Text(appProvider.themeMode == ThemeMode.dark ? l10n.get('light_mode') : l10n.get('dark_mode')))),
                      const PopupMenuDivider(),
                      PopupMenuItem(value: 'logout', child: ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: Text(l10n.get('logout')))),
                    ]
                  ],
                ),
              ],
              const SizedBox(width: 8),
            ],
          // Removed flexibleSpace to minimize green header height
          ),

          // ── Buscador y Selector de Inmobiliarias ──────────────────────────
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    children: [
                      // Barra de búsqueda
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: l10n.get('global_search_hint'),
                            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: AppThemes.primaryGreen),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    })
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Selector de empresa (Dropdown)
                      DropdownButtonFormField<Company?>(
                        value: _selectedCompany,
                        decoration: InputDecoration(
                          labelText: l10n.get('real_estate_companies'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: AppThemes.primaryGreen),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<Company?>(
                            value: null,
                            child: Row(
                              children: [
                                const Icon(Icons.public, size: 20, color: AppThemes.primaryGreen),
                                const SizedBox(width: 12),
                                Text(l10n.get('all_companies'), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          ..._companies.map((company) {
                            return DropdownMenuItem<Company?>(
                              value: company,
                              child: Row(
                                children: [
                                  company.logoUrl != null
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(company.logoUrl!),
                                          radius: 10)
                                      : CircleAvatar(
                                          backgroundColor: company.primaryColor ?? AppThemes.primaryGreen,
                                          radius: 10,
                                          child: Text(
                                            (company.abbr != null && company.abbr!.isNotEmpty)
                                                ? company.abbr!.substring(0, 1).toUpperCase()
                                                : '?',
                                            style: const TextStyle(fontSize: 10, color: Colors.white),
                                          )),
                                  Expanded(child: Text(company.name, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (Company? newValue) {
                          setState(() {
                            _selectedCompany = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Barra de acciones (filtros + contador) ──────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} ${l10n.get('results')}',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  if (!_activeFilter.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton.icon(
                        icon: const Icon(Icons.filter_alt_off, size: 16),
                        label: Text(l10n.get('reset')),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => setState(() => _activeFilter = PropertyFilter()),
                      ),
                    ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.tune, size: 16),
                    label: Text(l10n.get('filters')),
                    onPressed: _showFilterDialog,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l10n.get('refresh'),
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadAll,
                  ),
                ],
              ),
            ),
          ),

          // ── Lista de propiedades ────────────────────────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(l10n.get('no_results'),
                        style:
                            TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: MediaQuery.of(context).size.width > 800
                  ? SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 500,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final prop = filtered[i];
                          final propCompany = _companies.firstWhere(
                            (c) => c.id == prop.companyId,
                            orElse: () => Company.empty,
                          );
                          return _buildPropertyItem(prop, propCompany);
                        },
                        childCount: filtered.length,
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final prop = filtered[i];
                          final propCompany = _companies.firstWhere(
                            (c) => c.id == prop.companyId,
                            orElse: () => Company.empty,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildPropertyItem(prop, propCompany),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildPropertyItem(Property prop, Company propCompany) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedCompany == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _launchCompanyDomain(propCompany),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: propCompany.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: propCompany.primaryColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.business, size: 14, color: propCompany.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      propCompany.name,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: propCompany.primaryColor),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new, size: 12, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        PropertyCard(
          property: prop,
          initialLikeCount: _likeCounts[prop.id] ?? 0,
          initialViewCount: _viewCounts[prop.id] ?? 0,
          initialIsLiked: _likedByMe.contains(prop.id),
          visitorId: _visitorId ?? '',
          onLikeToggled: (count, liked) {
            setState(() {
              _likeCounts[prop.id!] = count;
              if (liked) _likedByMe.add(prop.id!); else _likedByMe.remove(prop.id!);
            });
          },
        ),
      ],
    );
  }
}

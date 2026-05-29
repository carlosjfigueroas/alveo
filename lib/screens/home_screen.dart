import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/app_provider.dart';
import '../services/company_service.dart';
import '../services/app_themes.dart';
import '../services/app_localizations.dart';
import '../providers/company_provider.dart';
import '../models/company.dart';
import '../models/property.dart';
import '../models/property_filter.dart';
import '../models/user_profile.dart';
import '../widgets/property_card.dart';
import '../widgets/filter_panel.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'admin/admin_dashboard.dart';
import 'admin/super_admin_dashboard.dart';
import '../services/like_service.dart';
import '../services/view_service.dart';
import '../widgets/photo_gallery_dialog.dart';
import '../widgets/main_drawer.dart';
import 'about_screen.dart';
import 'faq_screen.dart';
import 'global_search_screen.dart';
import 'register_screen.dart';
import '../services/visitor_service.dart';
import '../widgets/visitor_badge.dart';
import '../widgets/contact_dialog.dart';
import '../widgets/ai_chat_fab.dart';
import 'ai_chat_screen.dart';

enum PropertySortOption { newest, priceAsc, priceDesc, mostLiked }

class HomeScreen extends StatefulWidget {
  final String? initialPropertyRef;
  const HomeScreen({super.key, this.initialPropertyRef});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = SupabaseService();
  List<Property> _allProperties = [];
  List<String> _carouselImages = [];
  Map<int, String> _carouselActions = {};
  bool _isLoading = true;
  PropertyFilter _activeFilter = PropertyFilter();
  PropertySortOption _sortOption = PropertySortOption.newest;
  final String _cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, int> _likeCounts = {};
  Map<String, int> _viewCounts = {};
  Set<String> _likedByMe = {};
  String? _visitorId;
  List<Property> _topProperties = [];
  int _carouselIndex = 0;
  Timer? _carouselTimer;

  int _weeklyVisitors = 0;
  bool _isVisitorsLoading = true;
  String? _lastAgentId;
  String? _targetPropertyRef;

  List<Property> get _filteredProperties {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final agentContext = appProvider.agentContext;
    
    final list = _allProperties.where((p) {
      // 1. Si hay un contexto de agente activo, filtrar solo sus propiedades,
      // a menos que se esté buscando una propiedad específica por referencia en la URL.
      if (agentContext != null && _targetPropertyRef == null) {
        if (p.listingAgentId != agentContext.id) return false;
      }

      // 1.1 Si hay una referencia específica en la URL (ej: ref15)
      if (_targetPropertyRef != null) {
        final refStr = _targetPropertyRef!.toLowerCase().replaceAll('ref', '');
        final refNum = int.tryParse(refStr);
        if (refNum != null && p.refNumber != refNum) return false;
      }
      
      // 2. Filtros de búsqueda tradicionales
      if (!_activeFilter.isEmpty && !_activeFilter.matches(p)) return false;
      if (_activeFilter.minLikes != null) {
        if ((_likeCounts[p.id] ?? 0) < _activeFilter.minLikes!) return false;
      }
      return true;
    }).toList();
    
    if (_sortOption == PropertySortOption.priceAsc) {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortOption == PropertySortOption.priceDesc) {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortOption == PropertySortOption.mostLiked) {
      list.sort(
        (a, b) => (_likeCounts[b.id] ?? 0).compareTo(_likeCounts[a.id] ?? 0),
      );
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _targetPropertyRef = widget.initialPropertyRef;
    debugPrint('[HOME] initState - _targetPropertyRef: $_targetPropertyRef');
    _loadProperties();
    
    // Capturar parámetros de referido de la URL (Estrategias 1 y 2)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProv = Provider.of<AppProvider>(context, listen: false);
      try {
        final uri = Uri.base;
        final refEmail = uri.queryParameters['ref_email'];
        final refAlias = uri.queryParameters['ref'] ?? uri.queryParameters['alias'] ?? uri.queryParameters['vendedor'];
        
        if (refEmail != null && refEmail.isNotEmpty) {
          appProv.setReferralContext(referrerEmail: refEmail);
        } else if (refAlias != null && refAlias.isNotEmpty) {
          // Si viene por query param, lo validamos también
          _validateSalesperson(refAlias, appProv);
        }
      } catch (_) {}

      final companyId = Provider.of<CompanyProvider>(
        context,
        listen: false,
      ).companyId;
      appProv.fetchSiteContent(companyId);
    });

    _subscription = Supabase.instance.client
        .channel('public:properties_home')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'properties',
          callback: (p) => _loadProperties(),
        )
        .subscribe();
  }

  Future<void> _validateSalesperson(String alias, AppProvider prov) async {
    final s = await CompanyService.getSalespersonByAlias(alias);
    if (s != null && mounted) {
      prov.setReferralContext(
        salespersonAlias: s['alias'],
        salespersonName: s['full_name'],
      );
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPropertyRef != oldWidget.initialPropertyRef) {
      setState(() {
        _targetPropertyRef = widget.initialPropertyRef;
      });
      _loadProperties();
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _carouselTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final companyId = Provider.of<CompanyProvider>(
        context,
        listen: false,
      ).companyId;
      final response = await _service.getPublicProperties(companyId);
      final carouselFiles = await _service.listCarouselImages(companyId);

      // Load Likes
      _visitorId ??= LikeService.getOrCreateVisitorId();
      final propertyIds = response.map((p) => p.id!).toList();
      final counts = await LikeService.batchGetLikeCounts(propertyIds);
      final viewCounts = await ViewService.batchGetViewCounts(propertyIds);
      final liked = await LikeService.batchGetLikedByVisitor(
        _visitorId!,
        propertyIds,
      );

      // Load Top 10 Popular Properties for Carousel
      final topData = await LikeService.getTopLikedProperties(companyId);
      var topProperties = topData
          .map((json) => Property.fromJson(json))
          .toList();

      // Si estamos en modo agente, filtramos también el carrusel popular
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      if (appProvider.agentContext != null) {
        topProperties = topProperties.where((p) => p.listingAgentId == appProvider.agentContext!.id).toList();
      }

      // Load Visitor Count
      if (_isVisitorsLoading) {
        await VisitorService.registerVisit(
          visitorId: _visitorId!,
          companyId: companyId,
        );
        final count = await VisitorService.getWeeklyCount(companyId);
        if (mounted) {
          setState(() {
            _weeklyVisitors = count;
            _isVisitorsLoading = false;
          });
        }
      }

      final carouselActions = await _service.getCarouselActions(companyId);

      setState(() {
        _allProperties = response;
        _carouselImages = carouselFiles;
        _carouselActions = carouselActions;
        _likeCounts = counts;
        _viewCounts = viewCounts;
        _likedByMe = liked;
        _topProperties = topProperties;
      });
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication))
      throw Exception('Error $url');
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: const SizedBox(width: 400, child: LoginScreen()),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const ContactFormDialog());
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    final result = await showDialog<PropertyFilter>(
      context: context,
      builder: (_) => FilterPanel(initialFilter: _activeFilter),
    );
    if (result != null) setState(() => _activeFilter = result);
  }

  void _startFadeTimer(int itemCount) {
    _carouselTimer?.cancel();
    if (itemCount <= 1) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _carouselIndex = (_carouselIndex + 1) % itemCount;
        });
      }
    });
  }

  Widget _buildPopularItem(
    Company company,
    Property p,
    bool isMobile,
    bool isSpanish, {
    Key? key,
  }) {
    final imageUrl = p.imageUrls.isNotEmpty ? p.imageUrls.first : '';
    final isNew = DateTime.now().difference(p.createdAt).inDays < 7;

    return GestureDetector(
      key: key,
      onTap: () => _showPropertyDetails(p),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),

                // Gradient Overlay for Legibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),

                // Top Left Badges
                Positioned(
                  top: 20,
                  left: 20,
                  child: Row(
                    children: [
                      if (isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            (isSpanish ? 'NUEVO' : 'NEW').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Property Info Overlay Card
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppThemes.primaryGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (isSpanish ? 'MÁS POPULAR' : 'MOST POPULAR')
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 22 : 36,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p.city ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${company.currencySymbol}${NumberFormat("#,##0", isSpanish ? "es_ES" : "en_US").format(p.price)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ), // MouseRegion
    );
  }

  void _showPropertyDetails(Property property) {
    showDialog(
      context: context,
      builder: (context) =>
          PhotoGalleryDialog(property: property, initialIndex: 0),
    );
  }

  Widget _buildCarousel(Company company) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final strategy = company.carouselStrategy;
    final isSpanish =
        Provider.of<AppProvider>(context, listen: false).locale.languageCode ==
        'es';
    final isFade = company.carouselAnimation == 'fade';

    if (strategy == 'popular') {
      if (_topProperties.isEmpty) return const SizedBox.shrink();

      if (isFade) {
        if (_carouselTimer == null || !_carouselTimer!.isActive) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _startFadeTimer(_topProperties.length),
          );
        }

        return Container(
          height: isMobile ? 200 : 350,
          width: double.infinity,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildPopularItem(
              company,
              _topProperties[_carouselIndex % _topProperties.length],
              isMobile,
              isSpanish,
              key: ValueKey(_carouselIndex),
            ),
          ),
        );
      }

      return CarouselSlider(
        options: CarouselOptions(
          height: isMobile ? 200 : 350,
          viewportFraction: 1.0,
          enlargeCenterPage: false,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 5),
          onPageChanged: (index, _) => setState(() => _carouselIndex = index),
        ),
        items: _topProperties
            .map((p) => _buildPopularItem(company, p, isMobile, isSpanish))
            .toList(),
      );
    } else {
      // Manual Strategy
      if (_carouselImages.isEmpty) return const SizedBox.shrink();

      if (isFade) {
        // Start timer if not running
        if (_carouselTimer == null || !_carouselTimer!.isActive) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _startFadeTimer(_carouselImages.length),
          );
        }

        return Container(
          height: isMobile ? 200 : 350,
          width: double.infinity,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildManualItem(
              company,
              _carouselImages[_carouselIndex % _carouselImages.length],
              isMobile,
              key: ValueKey(_carouselIndex),
            ),
          ),
        );
      }

      return CarouselSlider(
        options: CarouselOptions(
          height: isMobile ? 200 : 350,
          viewportFraction: 1.0,
          enlargeCenterPage: false,
          autoPlay: true,
          onPageChanged: (index, _) => setState(() => _carouselIndex = index),
        ),
        items: _carouselImages
            .map((imgName) => _buildManualItem(company, imgName, isMobile))
            .toList(),
      );
    }
  }

  Widget _buildManualItem(
    Company company,
    String imgName,
    bool isMobile, {
    Key? key,
  }) {
    // Check if it's a direct logo upload or a carousel image
    final String storagePath;
    if (imgName.contains('logo')) {
      storagePath = 'logos/$imgName';
    } else {
      storagePath = 'carousel/${company.id}/$imgName';
    }
    final imageUrl = _service.getPublicUrl('property-images', storagePath);

    // Detectar el slot a partir del nombre del archivo (ej: carrusel_img_03.jpg → slot 3)
    int? slot;
    final match = RegExp(r'carrusel_img_(\d+)').firstMatch(imgName);
    if (match != null) slot = int.tryParse(match.group(1)!);
    final action = slot != null ? _carouselActions[slot] : null;

    // Detectar si hay una propiedad vinculada por referencia (con seguridad ante listas vacías)
    Property? linkedProperty;
    if (action != null && action.isNotEmpty && !action.startsWith('http')) {
      final ref = int.tryParse(action.replaceAll(RegExp(r'\D'), ''));
      if (ref != null && _allProperties.isNotEmpty) {
        try {
          linkedProperty = _allProperties.firstWhere((p) => p.refNumber == ref);
        } catch (_) {
          linkedProperty = null;
        }
      }
    }

    final isSpanish =
        Provider.of<AppProvider>(context, listen: false).locale.languageCode ==
        'es';

    Widget content = Stack(
      fit: StackFit.expand,
      children: [
        // 1. La imagen manual de fondo
        Image.network(
          '$imageUrl?t=$_cacheBuster',
          fit: BoxFit.contain, // Revertido a contain para evitar el efecto zoom
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
        ),

        // 2. Si hay propiedad vinculada, añadir el degradado y la info
        if (linkedProperty != null) ...[
          // Degradado para legibilidad (más suave y empieza más abajo)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center, // Empieza en el medio hacia abajo
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45), // Más claro que antes
                ],
              ),
            ),
          ),

          // Información del Inmueble (Estilo Modo Popular)
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linkedProperty.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 22 : 36,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      linkedProperty.city ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                    ),
                    if (linkedProperty.locationLabel.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        linkedProperty.locationLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );

    // Si hay acción configurada, envolver en GestureDetector
    if (action != null && action.isNotEmpty) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () async {
            if (action.startsWith('http://') || action.startsWith('https://')) {
              final uri = Uri.parse(action);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else if (linkedProperty != null) {
              showDialog(
                context: context,
                builder: (_) => PhotoGalleryDialog(property: linkedProperty!),
              );
            }
          },
          child: content,
        ),
      );
    }

    return Container(
      key: key,
      color: Colors.black.withValues(alpha: 0.03),
      width: double.infinity,
      height: double.infinity,
      child: content,
    );
  }

  Widget _buildAgentBanner(UserProfile agent, Company company, bool isSpanish, bool isMobile) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: company.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: company.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: agent.profilePhotoUrl != null ? NetworkImage(agent.profilePhotoUrl!) : null,
                  child: agent.profilePhotoUrl == null ? const Icon(Icons.person, size: 35) : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSpanish ? 'Te atiende:' : 'Your agent:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: company.primaryColor,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        agent.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (agent.bio != null && agent.bio!.isNotEmpty)
                        Text(
                          agent.bio!,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (isMobile) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showContactDialog(context),
                          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                          label: Text(isSpanish ? 'Contactar' : 'Contact'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: company.primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showContactDialog(context),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                    label: Text(isSpanish ? 'Contactar' : 'Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: company.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSpanish ? 'Ver todo el inventario' : 'View all inventory',
                  style: TextStyle(
                    fontSize: 10, 
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: isSpanish ? 'Mostrar todo el inventario de la empresa' : 'Show full company inventory',
                  onPressed: () => context.read<AppProvider>().setAgentContext(null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final companyProv = context.watch<CompanyProvider>();
    debugPrint('[HOME] build - _targetPropertyRef: $_targetPropertyRef, widget.initialPropertyRef: ${widget.initialPropertyRef}');

    // Si el contexto de agente cambia, recargamos propiedades para asegurar 
    // que el carrusel y filtros estén sincronizados
    if (_lastAgentId != appProvider.agentContext?.id) {
      final oldAgentId = _lastAgentId;
      _lastAgentId = appProvider.agentContext?.id;
      // Solo limpiamos el ref si el banner del agente se cerró manualmente (pasó de tener ID a null)
      // Evitamos limpiar si es la carga inicial o si ya estábamos en modo neutral.
      if (oldAgentId != null && _lastAgentId == null) _targetPropertyRef = null;
      Future.microtask(() => _loadProperties());
    }

    final l10n = AppLocalizations(appProvider.locale);
    final isSpanish = appProvider.locale.languageCode == 'es';
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isDesktop = !isMobile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencySymbol = companyProv.currencySymbol;
    // Si hay un ref específico en la URL, forzamos HomeScreen incluso para Super Admins 
    // para que se aplique el filtro correctamente.
    if (companyProv.isGlobalMode && appProvider.isSuperAdmin && _targetPropertyRef == null)
      return const GlobalSearchScreen();

    return Column(
      children: [
        // ── DYNAMIC AFFILIATE BANNER ABOVE APPBAR ──────────────────
        if (companyProv.currentCompany.showOrganicAffiliate)
          Material(
            color: appProvider.referredBySalesperson != null ? Colors.purple.shade700 : Colors.blue.shade800,
            child: InkWell(
              onTap: () {
                final Map<String, dynamic> args = {};

                if (appProvider.referredBySalesperson != null) {
                  args['salespersonAlias'] = appProvider.referredBySalesperson;
                } else if (appProvider.referrerEmail != null) {
                  args['ref_email'] = appProvider.referrerEmail;
                } else {
                  args['isOrganic'] = true;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: RouteSettings(name: '/register', arguments: args),
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Text(
                  appProvider.referredBySalesperson != null
                    ? (isSpanish 
                        ? 'Invitado por ${appProvider.salespersonName}. Únete a Alveo y obtén tu propio portal. Registrate.'
                        : 'Invited by ${appProvider.salespersonName}. Join Alveo and get your own portal. Register.')
                    : (appProvider.referrerEmail != null
                        ? (isSpanish
                            ? 'Invitado por ${appProvider.referrerEmail}. Únete a Alveo. Registrate.'
                            : 'Invited by ${appProvider.referrerEmail}. Join Alveo. Register.')
                        : (isSpanish
                            ? '¿Eres una Agencia Inmobiliaria? Únete a Alveo y obtén tu propio portal. Registrate.'
                            : 'Are you a Real Estate Agency? Join Alveo and get your own portal. Register.')),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: Scaffold(
            drawer: isMobile ? const MainDrawer() : null,
            floatingActionButton: companyProv.currentCompany.hasAiAgent
                ? AiChatFab(
                    onPressed: () => AiChatScreen.show(context),
                  )
                : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              centerTitle: true,
              leadingWidth: isMobile ? 36 : 56,
              leading: isMobile
                  ? Builder(
                      builder: (c) => IconButton(
                        padding: const EdgeInsets.only(left: 4),
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(c).openDrawer(),
                      ),
                    )
                  : null,
              title: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isDesktop
                        ? (companyProv.currentCompany.logoUrl != null
                              ? Image.network(
                                  companyProv.currentCompany.logoUrl!,
                                  height: 32,
                                  fit: BoxFit.contain,
                                )
                              : Image.asset(
                                  'assets/images/logo_full.png',
                                  height: 32,
                                  fit: BoxFit.contain,
                                ))
                        : (companyProv.currentCompany.logoAbbrUrl != null
                              ? Image.network(
                                  companyProv.currentCompany.logoAbbrUrl!,
                                  height: 26,
                                  fit: BoxFit.contain,
                                )
                              : Image.asset(
                                  'assets/images/logo_abbr.png',
                                  height: 26,
                                  fit: BoxFit.contain,
                                )),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        companyProv.companyLocalizedName(
                          appProvider.locale.languageCode,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 14 : 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (isDesktop) ...[
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    ),
                    child: Text(
                      l10n.get('about'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FaqScreen()),
                    ),
                    child: Text(
                      l10n.get('faq'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((companyProv.instagramUrl ?? '').isNotEmpty)
                      InkWell(
                        onTap: () => _launchURL(companyProv.instagramUrl!),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: FaIcon(
                            FontAwesomeIcons.instagram,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    if ((companyProv.facebookUrl ?? '').isNotEmpty)
                      InkWell(
                        onTap: () => _launchURL(companyProv.facebookUrl!),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: FaIcon(
                            FontAwesomeIcons.facebook,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    if ((companyProv.telegramUrl ?? '').isNotEmpty)
                      InkWell(
                        onTap: () => _launchURL(companyProv.telegramUrl!),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: FaIcon(
                            FontAwesomeIcons.telegram,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    if ((companyProv.linkedinUrl ?? '').isNotEmpty)
                      InkWell(
                        onTap: () => _launchURL(companyProv.linkedinUrl!),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: FaIcon(
                            FontAwesomeIcons.linkedin,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    if ((companyProv.contactEmail ?? '').isNotEmpty)
                      InkWell(
                        onTap: () => _showContactDialog(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.email,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    if (((companyProv.contactWhatsapp ?? '')).isNotEmpty)
                      InkWell(
                        onTap: () => _launchURL('https://wa.me/${companyProv.contactWhatsapp!}'),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: FaIcon(
                            FontAwesomeIcons.whatsapp,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                if (isDesktop) ...[
                  const VerticalDivider(
                    color: Colors.white24,
                    indent: 12,
                    endIndent: 12,
                  ),
                  if (appProvider.userProfile?.role == 'super_admin')
                    IconButton(
                      tooltip: 'Súper Panel',
                      icon: const Icon(
                        Icons.auto_awesome,
                        color: Colors.amber,
                        size: 28,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SuperAdminDashboard(),
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.account_circle,
                      color: Colors.white,
                      size: 28,
                    ),
                    onSelected: (val) async {
                      if (val == 'admin')
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboard(),
                          ),
                        );
                      else if (val == 'super')
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SuperAdminDashboard(),
                          ),
                        );
                      else if (val == 'theme')
                        appProvider.toggleTheme();
                      else if (val == 'lang')
                        appProvider.setLocale(
                          isSpanish ? const Locale('en') : const Locale('es'),
                        );
                      else if (val == 'login')
                        _showLoginDialog(context);
                      else if (val == 'logout')
                        await appProvider.signOut();
                    },
                    itemBuilder: (ctx) => [
                      if (appProvider.userProfile == null) ...[
                        PopupMenuItem(
                          value: 'login',
                          child: ListTile(
                            leading: const Icon(Icons.login),
                            title: Text(l10n.get('login')),
                          ),
                        ),
                        const PopupMenuDivider(),
                      ] else ...[
                        PopupMenuItem(
                          enabled: false,
                          child: Text(
                            appProvider.userProfile!.fullName ?? 'Usuario',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const PopupMenuDivider(),
                        if (appProvider.isAdmin)
                          PopupMenuItem(
                            value: 'admin',
                            child: ListTile(
                              leading: const Icon(Icons.admin_panel_settings),
                              title: Text(l10n.get('admin_panel')),
                            ),
                          ),
                        if (appProvider.userProfile?.role == 'super_admin')
                          PopupMenuItem(
                            value: 'super',
                            child: ListTile(
                              leading: const Icon(
                                Icons.auto_awesome,
                                color: Colors.amber,
                              ),
                              title: const Text(
                                'Súper Panel',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        const PopupMenuDivider(),
                      ],
                      PopupMenuItem(
                        value: 'lang',
                        child: ListTile(
                          leading: const Icon(Icons.language),
                          title: Text(isSpanish ? 'English' : 'Español'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'theme',
                        child: ListTile(
                          leading: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                          ),
                          title: Text(
                            isDark
                                ? l10n.get('light_mode')
                                : l10n.get('dark_mode'),
                          ),
                        ),
                      ),
                      if (appProvider.userProfile != null) ...[
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'logout',
                          child: ListTile(
                            leading: const Icon(
                              Icons.logout,
                              color: Colors.red,
                            ),
                            title: Text(l10n.get('logout')),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(width: 8),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _loadProperties,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (companyProv.currentCompany.showCarousel)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 1200 : double.infinity,
                            ),
                            child: _buildCarousel(companyProv.currentCompany),
                          ),
                        ),
                      ),
                    if (appProvider.agentContext != null)
                      _buildAgentBanner(appProvider.agentContext!, companyProv.currentCompany, isSpanish, isMobile),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Widget de visitas a la izquierda
                          VisitorBadge(
                            count: _weeklyVisitors,
                            isLoading: _isVisitorsLoading,
                          ),
                          // Orden y Filtros agrupados a la derecha
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<PropertySortOption>(
                                      value: _sortOption,
                                      isDense: true,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 18,
                                      ),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      onChanged: (v) =>
                                          setState(() => _sortOption = v!),
                                      items: [
                                        DropdownMenuItem(
                                          value: PropertySortOption.newest,
                                          child: Text(l10n.get('newest')),
                                        ),
                                        DropdownMenuItem(
                                          value: PropertySortOption.priceAsc,
                                          child: Text(l10n.get('price_asc')),
                                        ),
                                        DropdownMenuItem(
                                          value: PropertySortOption.priceDesc,
                                          child: Text(l10n.get('price_desc')),
                                        ),
                                        DropdownMenuItem(
                                          value: PropertySortOption.mostLiked,
                                          child: Text(l10n.get('most_popular')),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Badge(
                                label: Text(
                                  '${_filteredProperties.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: AppThemes.terracottaRed,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppThemes.primaryGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  onPressed: () => _showFilterDialog(context),
                                  icon: const Icon(Icons.tune, size: 16),
                                  label: Text(
                                    l10n.get('filters'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredProperties.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(l10n.get('no_results')),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: isMobile
                                ? ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _filteredProperties.length,
                                    itemBuilder: (context, index) {
                                      final p = _filteredProperties[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 24,
                                        ),
                                        child: PropertyCard(
                                          property: p,
                                          initialLikeCount:
                                              _likeCounts[p.id] ?? 0,
                                          initialViewCount:
                                              _viewCounts[p.id] ?? 0,
                                          initialIsLiked: _likedByMe.contains(
                                            p.id,
                                          ),
                                          visitorId: _visitorId ?? '',
                                          onLikeToggled: (count, liked) {
                                            _likeCounts[p.id!] = count;
                                            if (liked)
                                              _likedByMe.add(p.id!);
                                            else
                                              _likedByMe.remove(p.id!);
                                          },
                                        ),
                                      );
                                    },
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 500,
                                          childAspectRatio: 0.75,
                                          crossAxisSpacing: 24,
                                          mainAxisSpacing: 24,
                                        ),
                                    itemCount: _filteredProperties.length,
                                    itemBuilder: (context, index) {
                                      final p = _filteredProperties[index];
                                      return PropertyCard(
                                        property: p,
                                        initialLikeCount:
                                            _likeCounts[p.id] ?? 0,
                                        initialViewCount:
                                            _viewCounts[p.id] ?? 0,
                                        initialIsLiked: _likedByMe.contains(
                                          p.id,
                                        ),
                                        visitorId: _visitorId ?? '',
                                        onLikeToggled: (count, liked) {
                                          _likeCounts[p.id!] = count;
                                          if (liked)
                                            _likedByMe.add(p.id!);
                                          else
                                            _likedByMe.remove(p.id!);
                                        },
                                      );
                                    },
                                  ),
                          ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

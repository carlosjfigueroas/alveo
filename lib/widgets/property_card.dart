import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import '../models/property.dart';
import '../services/app_themes.dart';
import '../services/app_localizations.dart';
import '../services/app_provider.dart';
import 'package:provider/provider.dart';
import '../screens/budget_screen.dart';
import '../services/pdf_service.dart';
import '../providers/company_provider.dart';
import 'package:intl/intl.dart';
import '../services/like_service.dart';
import 'photo_gallery_dialog.dart';
import 'property_map_dialog.dart';
import '../services/view_service.dart';

class PropertyCard extends StatefulWidget {
  final Property property;
  final int initialLikeCount;
  final int initialViewCount;
  final bool initialIsLiked;
  final String visitorId;
  final Function(int, bool)? onLikeToggled;

  const PropertyCard({
    super.key,
    required this.property,
    this.initialLikeCount = 0,
    this.initialViewCount = 0,
    this.initialIsLiked = false,
    this.visitorId = '',
    this.onLikeToggled,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  int _currentImageIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();
  
  late int _likesCount;
  late int _viewsCount;
  late bool _isLiked;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.initialLikeCount;
    _viewsCount = widget.initialViewCount;
    _isLiked = widget.initialIsLiked;
  }

  @override
  void didUpdateWidget(PropertyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLikeCount != widget.initialLikeCount || 
        oldWidget.initialViewCount != widget.initialViewCount ||
        oldWidget.initialIsLiked != widget.initialIsLiked) {
      _likesCount = widget.initialLikeCount;
      _viewsCount = widget.initialViewCount;
      _isLiked = widget.initialIsLiked;
    }
  }

  void _toggleLike(String companyId) async {
    if (_isToggling || widget.visitorId.isEmpty) return;
    
    // Optimistic update
    setState(() {
      _isToggling = true;
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      final newState = await LikeService.toggleLike(
        visitorId: widget.visitorId,
        propertyId: widget.property.id!,
        companyId: companyId,
      );
      
      if (mounted) {
        if (newState) {
          final isSpanish = AppLocalizations.of(context).locale.languageCode == 'es';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isSpanish ? '¡Gracias!' : 'Thanks!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        setState(() {
          _isLiked = newState;
          widget.onLikeToggled?.call(_likesCount, _isLiked);
          _isToggling = false;
        });
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? 1 : -1;
          _isToggling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final l10n = AppLocalizations(appProvider.locale);
    final isSpanish = appProvider.locale.languageCode == 'es';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final captionColor = isDark ? Colors.white70 : Colors.black54;
    final mainTextColor = isDark ? Colors.white : Colors.black87;
    final companyProv = Provider.of<CompanyProvider>(context, listen: false);

    // Only use real images from the property object. If none, show a single placeholder.
    List<String> displayImages = List.from(widget.property.imageUrls);
    if (displayImages.isEmpty) {
      displayImages = [
        'https://via.placeholder.com/800x600?text=Group+Adm+Real+Estate'
      ];
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), // Clean edges
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isBounded = constraints.hasBoundedHeight;
          
          Widget imageWidget = LayoutBuilder(
            builder: (context, imageConstraints) {
              return Stack(
                children: [
                  CarouselSlider(
                    items: displayImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final url = entry.value;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => PhotoGalleryDialog(
                                property: widget.property,
                                initialIndex: index,
                              ),
                            );
                            // Record view (session-deduplicated)
                            ViewService.recordView(
                              propertyId: widget.property.id!,
                              companyId: companyProv.companyId,
                              visitorId: widget.visitorId,
                            );
                          },
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 50),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    carouselController: _controller,
                    options: CarouselOptions(
                      // If in a GridView (bounded), fill available space. Else fixed height.
                      height: imageConstraints.hasBoundedHeight ? imageConstraints.maxHeight : 250,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: displayImages.length > 1,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                    ),
                  ),
                  // Navigation Arrows
                  if (displayImages.length > 1) ...[
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.7),
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, size: 18, color: Colors.black),
                            onPressed: () => _controller.previousPage(),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.7),
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right, size: 18, color: Colors.black),
                            onPressed: () => _controller.nextPage(),
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Dot Indicator
                  if (displayImages.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: displayImages.asMap().entries.map((entry) {
                          return GestureDetector(
                            onTap: () => _controller.animateToPage(entry.key),
                            child: Container(
                              width: 30.0,
                              height: 3.0,
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: Colors.white.withValues(alpha: 
                                  _currentImageIndex == entry.key ? 1.0 : 0.4,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.property.status == 'Vendido'
                            ? const Color(0xFFE53935).withOpacity(0.9)
                            : widget.property.status == 'Alquilado'
                                ? const Color(0xFF1E88E5).withOpacity(0.9)
                                : widget.property.status == 'Reservado'
                                    ? const Color(0xFFFB8C00).withOpacity(0.9)
                                    : const Color(0xFF43A047).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        (l10n.get(widget.property.status) ?? widget.property.status).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carousel Image Section
              if (isBounded) Expanded(child: imageWidget) else imageWidget,
              // Property Details Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.get('ref')} ${(widget.property.refNumber ?? 0).toString().padLeft(3, '0')}',
                      style: TextStyle(color: mainTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    // View and Like Section
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // View Counter
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_outlined, size: 18, color: captionColor),
                              const SizedBox(width: 6),
                              Text(
                                '$_viewsCount',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: captionColor,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSpanish ? 'Vistas' : 'Views',
                                style: TextStyle(color: captionColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Like Button
                        InkWell(
                          onTap: appProvider.isAdmin ? null : () => _toggleLike(companyProv.companyId),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isLiked ? AppThemes.primaryGreen.withValues(alpha: 0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                  size: 18,
                                  color: _isLiked ? AppThemes.primaryGreen : captionColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_likesCount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isLiked ? AppThemes.primaryGreen : captionColor,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.property.address.isNotEmpty ? widget.property.address : l10n.get('loc_not_specified'),
                  style: TextStyle(color: captionColor, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.property.locationLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.property.locationLabel,
                      style: TextStyle(color: captionColor.withValues(alpha: 0.8), fontSize: 12, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  widget.property.title.isNotEmpty ? widget.property.title : l10n.get('property'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: mainTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.property.operationType.toLowerCase() == 'alquiler' 
                    ? l10n.get('rent') 
                    : l10n.get('sale'),
                  style: TextStyle(color: captionColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                if (widget.property.details?.interiorLocation != null && widget.property.details!.interiorLocation!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      widget.property.details?.interiorLocation ?? '',
                      style: TextStyle(color: AppThemes.primaryGreen, fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Text(
                  widget.property.price == 0 
                    ? l10n.get('price_on_request')
                    : '${companyProv.currencySymbol}${NumberFormat("#,##0", appProvider.locale.languageCode == 'es' ? 'es_ES' : 'en_US').format(widget.property.price)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppThemes.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _infoIcon(Icons.square_foot, '${widget.property.details?.areaM2 ?? 0} ${companyProv.areaUnit}', captionColor, l10n.get('area_field')),
                    if ((widget.property.details?.bedrooms ?? 0) > 0)
                      _infoIcon(Icons.king_bed_outlined, '${widget.property.details!.bedrooms}', captionColor, l10n.get('bedrooms_field')),
                    if ((widget.property.details?.bathrooms ?? 0) > 0)
                      _infoIcon(Icons.bathtub_outlined, '${widget.property.details!.bathrooms}', captionColor, l10n.get('bathrooms_field')),
                    if ((widget.property.details?.parkingSpaces ?? 0) > 0)
                      _infoIcon(Icons.directions_car_outlined, '${widget.property.details!.parkingSpaces}', captionColor, l10n.get('parking_field')),
                    
                    // Comodidades
                    if (widget.property.details?.hasPool == true)
                      _infoIcon(Icons.pool, '', captionColor, l10n.get('pool_field')),
                    if (widget.property.details?.hasTerrace == true)
                      _infoIcon(Icons.deck, '', captionColor, l10n.get('terrace_field')),
                    if (widget.property.details?.hasBalcony == true)
                      _infoIcon(Icons.balcony, '', captionColor, l10n.get('balcony_field')),
                    if (widget.property.details?.hasSecurity == true)
                      _infoIcon(Icons.security, '', captionColor, l10n.get('security_field')),
                    if (widget.property.details?.isWaterfront == true)
                      _infoIcon(Icons.waves, '', captionColor, l10n.get('waterfront_field')),
                    if (widget.property.details?.isFurnished == true)
                      _infoIcon(Icons.chair, '', captionColor, l10n.get('furnished_field')),
                    if (widget.property.details?.hasGarden == true)
                      _infoIcon(Icons.park, '', captionColor, l10n.get('garden_field')),
                    if (widget.property.details?.hasPowerGenerator == true)
                      _infoIcon(Icons.bolt, '', captionColor, l10n.get('power_generator_field')),
                    if (widget.property.details?.hasWaterTank == true)
                      _infoIcon(Icons.water_drop, '', captionColor, l10n.get('water_tank_field')),
                    if (widget.property.details?.hasGrill == true)
                      _infoIcon(Icons.outdoor_grill, '', captionColor, l10n.get('grill_field')),
                    if (widget.property.isResidential && widget.property.isAlquiler) ...[
                      if (widget.property.details?.petsAllowed == true)
                        _infoIcon(Icons.pets, '', captionColor, l10n.get('pets_allowed_field')),
                      if (widget.property.details?.childrenAllowed == true)
                        _infoIcon(Icons.child_care, '', captionColor, l10n.get('children_allowed_field')),
                    ],
                  ],
                ),
                // const SizedBox(height: 16),
                // Likes Section moved to top next to Ref


                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Map button (only if coords available)
                    if (widget.property.hasCoordinates) ...[
                      SizedBox(
                        height: 40,
                        width: 50,
                        child: Tooltip(
                          message: l10n.get('view_on_map'),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE8F5E9),
                              foregroundColor: AppThemes.primaryGreen,
                              padding: EdgeInsets.zero,
                              elevation: 0,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(color: AppThemes.primaryGreen),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => PropertyMapDialog(property: widget.property),
                              );
                            },
                            child: const Icon(Icons.location_on_outlined, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Share Button
                    SizedBox(
                      height: 40,
                      width: 50,
                      child: Tooltip(
                        message: isSpanish ? 'Compartir' : 'Share',
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: companyProv.currentCompany.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            elevation: 0,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            final ref = (widget.property.refNumber ?? 0).toString().padLeft(3, '0');
                            final domain = Uri.base.origin;
                            final url = '$domain/ref$ref';
                            Clipboard.setData(ClipboardData(text: url));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.get('copy_link_success') ?? (isSpanish ? '¡Enlace copiado!' : 'Link copied!')),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          child: const Icon(Icons.share, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // PDF Button (Original PDF Colors: Red/White)
                    SizedBox(
                      height: 40,
                      width: 50,
                      child: Tooltip(
                        message: 'PDF',
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935), // PDF Red
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            elevation: 0,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            final company = Provider.of<CompanyProvider>(context, listen: false).company;
                            PdfService.generatePropertyPdf(
                              widget.property,
                              lang: appProvider.locale.languageCode,
                              company: company,
                            );
                          },
                          child: const Icon(Icons.picture_as_pdf_outlined, size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Me Interesa button (Centered and less wide)
                    SizedBox(
                      height: 40,
                      width: 140, // Ancho reducido
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (widget.property.status == 'Vendido' || widget.property.status == 'Alquilado')
                            ? (isDark ? Colors.white12 : Colors.grey[300])
                            : AppThemes.terracottaRed,
                          foregroundColor: (widget.property.status == 'Vendido' || widget.property.status == 'Alquilado')
                            ? (isDark ? Colors.white38 : Colors.black38)
                            : Colors.white,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: (widget.property.status == 'Vendido' || widget.property.status == 'Alquilado')
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  clipBehavior: Clip.antiAlias,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
                                    child: BudgetScreen(selectedPropertyId: widget.property.id),
                                  ),
                                ),
                              );
                            },
                        child: Text(
                          (widget.property.status == 'Vendido' || widget.property.status == 'Alquilado')
                            ? (isSpanish ? 'No Disponible' : 'Not Available')
                            : l10n.get('me_interesa'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoIcon(IconData icon, String text, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          if (text.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(text, style: TextStyle(color: color, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

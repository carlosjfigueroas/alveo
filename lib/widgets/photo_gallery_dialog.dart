import 'package:flutter/material.dart';
import '../models/property.dart';
import '../services/app_themes.dart';
import '../services/app_localizations.dart';

class PhotoGalleryDialog extends StatefulWidget {
  final Property property;
  final int initialIndex;

  const PhotoGalleryDialog({
    super.key,
    required this.property,
    this.initialIndex = 0,
  });

  @override
  State<PhotoGalleryDialog> createState() => _PhotoGalleryDialogState();
}

class _PhotoGalleryDialogState extends State<PhotoGalleryDialog> {
  late int _currentIndex;
  Offset? _mousePosition; // Global within the dialog's stack
  Offset? _imageRelativePos; // Position within the actual image pixels
  bool _showMagnifier = false;
  final double _magnifierSize = 250.0;
  final double _zoomFactor = 2.0;
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _nextImage() {
    if (_currentIndex < widget.property.imageUrls.length - 1) {
      setState(() {
        _currentIndex++;
        _showMagnifier = false; // Reset on change
      });
    }
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showMagnifier = false; // Reset on change
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.property.imageUrls.isNotEmpty 
        ? widget.property.imageUrls 
        : ['https://via.placeholder.com/800x600?text=No+Images'];
    
    final currentUrl = images[_currentIndex];

    final size = MediaQuery.of(context).size;
    final isDesktopGallery = size.width > 800;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final textColor = isDesktopGallery ? Colors.white : Theme.of(context).colorScheme.onSurface;

    if (isDesktopGallery) {
      return Dialog.fullscreen(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: _buildContent(context, true),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: size.width * 0.9,
        height: size.height * 0.9,
        decoration: BoxDecoration(
          color: backgroundColor.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: _buildContent(context, false),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isFull) {
    final images = widget.property.imageUrls.isNotEmpty 
        ? widget.property.imageUrls 
        : ['https://via.placeholder.com/800x600?text=No+Images'];
    
    final currentUrl = images[_currentIndex];
    final l10n = AppLocalizations.of(context);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final galleryBg = Colors.black;
    final isMobileMode = MediaQuery.of(context).size.width < 900;

    return Column(
      children: [
        // Header with Huge Close Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.property.title,
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppThemes.terracottaRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: galleryBg,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobileMode = constraints.maxWidth < 900;
                
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Base Image Layer with Mouse Detection for Zoom
                    InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 5.0,
                      panEnabled: isMobileMode, 
                      scaleEnabled: isMobileMode,
                      child: MouseRegion(
                        hitTestBehavior: HitTestBehavior.opaque,
                        onEnter: (_) => setState(() => _showMagnifier = !isMobileMode),
                        onExit: (_) => setState(() => _showMagnifier = false),
                        onHover: (event) {
                          if (isMobileMode) return;
                          final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
                          if (renderBox != null) {
                            final localPos = renderBox.globalToLocal(event.position);
                            final size = renderBox.size;
                            if (localPos.dx >= 0 && localPos.dx <= size.width && 
                                localPos.dy >= 0 && localPos.dy <= size.height) {
                              setState(() {
                                _showMagnifier = true;
                                _mousePosition = event.localPosition;
                                _imageRelativePos = localPos;
                              });
                            } else {
                              setState(() => _showMagnifier = false);
                            }
                          }
                        },
                        child: Center(
                          child: Image.network(
                            currentUrl,
                            key: _imageKey,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(color: AppThemes.primaryGreen));
                            },
                          ),
                        ),
                      ),
                    ),

                    // Magnifier Overlay (Desktop only)
                    if (!isMobileMode && _showMagnifier && _mousePosition != null && _imageRelativePos != null)
                      Positioned(
                        left: _mousePosition!.dx - (_magnifierSize / 2),
                        top: _mousePosition!.dy - (_magnifierSize / 2),
                        child: IgnorePointer(
                          child: Container(
                            width: _magnifierSize,
                            height: _magnifierSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5),
                              ],
                            ),
                            child: ClipOval(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
                                  final Size imageSize = renderBox?.size ?? Size.zero;
                                  
                                  return Stack(
                                    children: [
                                      Positioned(
                                        left: -(_imageRelativePos!.dx * _zoomFactor - _magnifierSize / 2),
                                        top: -(_imageRelativePos!.dy * _zoomFactor - _magnifierSize / 2),
                                        child: SizedBox(
                                          width: imageSize.width * _zoomFactor, 
                                          height: imageSize.height * _zoomFactor, 
                                          child: Image.network(
                                            currentUrl,
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Navigation Arrows
                    if (images.length > 1) ...[
                      Positioned(
                        left: 10,
                        child: _navButton(Icons.chevron_left, _currentIndex > 0 ? _previousImage : null),
                      ),
                      Positioned(
                        right: 10,
                        child: _navButton(Icons.chevron_right, _currentIndex < images.length - 1 ? _nextImage : null),
                      ),
                    ],

                    // Transparent Information Overlay (Floating Layer)
                    Positioned(
                      top: 30,
                      left: 30,
                      right: 30,
                      child: IgnorePointer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 24, color: AppThemes.primaryGreen),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    widget.property.address,
                                    style: TextStyle(
                                      color: Colors.white, 
                                      fontSize: isMobileMode ? 18 : 26, 
                                      fontWeight: FontWeight.bold, 
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 10, offset: const Offset(2, 2)),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.property.locationLabel.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 34, top: 6),
                                child: Text(
                                  widget.property.locationLabel,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95), 
                                    fontSize: isMobileMode ? 14 : 20, 
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 8, offset: const Offset(1, 1)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Photo Counter
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          '${_currentIndex + 1} / ${images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        
        // Minimized Bottom Bar (Thumbnails & Amenities)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nano Thumbnails Strip
              if (images.length > 1) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    height: 35, // Tira muy pequeña
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _currentIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected ? AppThemes.primaryGreen : Colors.grey.withValues(alpha: 0.2),
                                width: isSelected ? 2 : 1,
                              ),
                              image: DecorationImage(
                                image: NetworkImage(images[index]),
                                fit: BoxFit.cover,
                                colorFilter: isSelected ? null : ColorFilter.mode(Colors.black.withValues(alpha: 0.2), BlendMode.darken),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              
              // Amenities
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildAmenitiesWrap(context, l10n),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesWrap(BuildContext context, AppLocalizations l10n) {
    final details = widget.property.details;
    if (details == null) return const SizedBox.shrink();

    final captionColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _infoIcon(Icons.square_foot, '${details.areaM2 ?? 0} m²', captionColor, l10n.get('area_field')),
        if ((details.bedrooms ?? 0) > 0)
          _infoIcon(Icons.king_bed_outlined, '${details.bedrooms}', captionColor, l10n.get('bedrooms_field')),
        if ((details.bathrooms ?? 0) > 0)
          _infoIcon(Icons.bathtub_outlined, '${details.bathrooms}', captionColor, l10n.get('bathrooms_field')),
        if ((details.parkingSpaces ?? 0) > 0)
          _infoIcon(Icons.directions_car_outlined, '${details.parkingSpaces}', captionColor, l10n.get('parking_field')),
        
        if (details.hasPool == true) _infoIcon(Icons.pool, '', captionColor, l10n.get('pool_field')),
        if (details.hasTerrace == true) _infoIcon(Icons.deck, '', captionColor, l10n.get('terrace_field')),
        if (details.hasBalcony == true) _infoIcon(Icons.balcony, '', captionColor, l10n.get('balcony_field')),
        if (details.hasSecurity == true) _infoIcon(Icons.security, '', captionColor, l10n.get('security_field')),
        if (details.isWaterfront == true) _infoIcon(Icons.waves, '', captionColor, l10n.get('waterfront_field')),
        if (details.isFurnished == true) _infoIcon(Icons.chair, '', captionColor, l10n.get('furnished_field')),
        if (details.hasGarden == true) _infoIcon(Icons.park, '', captionColor, l10n.get('garden_field')),
        if (details.hasPowerGenerator == true) _infoIcon(Icons.bolt, '', captionColor, l10n.get('power_generator_field')),
        if (details.hasWaterTank == true) _infoIcon(Icons.water_drop, '', captionColor, l10n.get('water_tank_field')),
        if (details.hasGrill == true) _infoIcon(Icons.outdoor_grill, '', captionColor, l10n.get('grill_field')),
      ],
    );
  }

  Widget _infoIcon(IconData icon, String label, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback? onPressed) {
    return CircleAvatar(
      backgroundColor: (onPressed != null ? Colors.white : Colors.white24).withValues(alpha: 0.7),
      radius: 24,
      child: IconButton(
        icon: Icon(icon, size: 28, color: Colors.black),
        onPressed: onPressed,
      ),
    );
  }
}

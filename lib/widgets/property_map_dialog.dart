import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/property.dart';
import '../services/app_localizations.dart';
import '../services/app_themes.dart';
import '../services/app_provider.dart';
import '../providers/company_provider.dart';

class PropertyMapDialog extends StatefulWidget {
  final Property property;

  const PropertyMapDialog({super.key, required this.property});

  @override
  State<PropertyMapDialog> createState() => _PropertyMapDialogState();
}

class _PropertyMapDialogState extends State<PropertyMapDialog> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  bool _selectedMarkerExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    // Geolocation is intentionally disabled in shared Flutter code to avoid
    // web-only APIs (dart:html). Keep map fully functional without user dot.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final companyProv = Provider.of<CompanyProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final propertyCenter = LatLng(widget.property.latitude!, widget.property.longitude!);
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final cardBg = isDark ? const Color(0xFF2A2A3E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final captionColor = isDark ? Colors.white60 : Colors.black54;

    final priceText = widget.property.price == 0
        ? l10n.get('price_on_request')
        : '${companyProv.currencySymbol}${NumberFormat("#,##0", appProvider.locale.languageCode == 'es' ? 'es_ES' : 'en_US').format(widget.property.price)}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.05,
        vertical: size.height * 0.05,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: size.width * 0.90,
          height: size.height * 0.90,
          child: Stack(
            children: [
              // ── The Map ────────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: propertyCenter,
                  initialZoom: 15,
                  onTap: (_, __) {
                    if (_selectedMarkerExpanded) {
                      setState(() => _selectedMarkerExpanded = false);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.alveo.app',
                  ),
                  // Property marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: propertyCenter,
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMarkerExpanded = !_selectedMarkerExpanded),
                          child: const Icon(Icons.location_pin, color: AppThemes.terracottaRed, size: 44),
                        ),
                      ),
                      // User location (blue dot)
                      if (_userLocation != null)
                        Marker(
                          point: _userLocation!,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [TextSourceAttribution('OpenStreetMap contributors')],
                  ),
                ],
              ),

              // ── Property Mini Popup (on marker tap) ────────────────────
              if (_selectedMarkerExpanded)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 280,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail
                          if (widget.property.imageUrls.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(
                                widget.property.imageUrls.first,
                                height: 130,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 80,
                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                  child: const Icon(Icons.home_outlined, size: 40),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  priceText,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppThemes.primaryGreen),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.property.title,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.property.address.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      widget.property.address,
                                      style: TextStyle(fontSize: 12, color: captionColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Zoom Controls ─────────────────────────────────────────
              Positioned(
                bottom: 40,
                right: 12,
                child: Column(
                  children: [
                    _zoomButton(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1), isDark),
                    const SizedBox(height: 4),
                    _zoomButton(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1), isDark),
                  ],
                ),
              ),

              // ── My Location button ────────────────────────────────────
              if (_userLocation != null)
                Positioned(
                  bottom: 40,
                  left: 12,
                  child: Tooltip(
                    message: l10n.get('my_location'),
                    child: FloatingActionButton.small(
                      heroTag: 'map_my_loc',
                      backgroundColor: Colors.blue,
                      onPressed: () => _mapController.move(_userLocation!, 15),
                      child: const Icon(Icons.my_location, color: Colors.white, size: 18),
                    ),
                  ),
                ),

              // ── Close Button (top right, big red) ─────────────────────
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),

              // ── Property name badge (top left) ────────────────────────
              Positioned(
                top: 12,
                left: 12,
                right: 70,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: bgColor.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.home_outlined, size: 16, color: AppThemes.primaryGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.property.title,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }
}

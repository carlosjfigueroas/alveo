import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/geocoding_service.dart';
import '../services/app_localizations.dart';
import '../services/app_themes.dart';

class LocationPickerDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerDialog({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  LatLng? _selectedPoint;
  LatLng _center = const LatLng(10.4806, -66.9036); // Default: Caracas
  bool _isGeocoding = false;
  bool _isLocating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedPoint = LatLng(widget.initialLat!, widget.initialLng!);
      _center = _selectedPoint!;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _geocodeAddress() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() { _isGeocoding = true; _errorMessage = null; });
    final result = await GeocodingService.searchAddress(query);
    if (mounted) {
      setState(() { _isGeocoding = false; });
      if (result != null) {
        setState(() { _selectedPoint = result; _center = result; });
        _mapController.move(result, 15);
      } else {
        final l10n = AppLocalizations.of(context);
        setState(() { _errorMessage = l10n.get('geocoding_failed'); });
      }
    }
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _isLocating = false;
      _errorMessage = AppLocalizations.of(context).get('geocoding_failed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.black38;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.05,
        vertical: size.height * 0.05,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: size.width * 0.90,
          height: size.height * 0.90,
          color: bgColor,
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: AppThemes.primaryGreen,
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      l10n.get('assign_location'),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ── Search Bar ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                color: surfaceColor,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: l10n.get('search_location'),
                          hintStyle: TextStyle(color: hintColor),
                          prefixIcon: Icon(Icons.search, color: hintColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF3A3A4E) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _geocodeAddress(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Geocode button
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _isGeocoding ? null : _geocodeAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemes.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isGeocoding
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(l10n.get('search'), style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // My location button
                    Tooltip(
                      message: l10n.get('my_location'),
                      child: SizedBox(
                        height: 40,
                        width: 40,
                        child: ElevatedButton(
                          onPressed: _isLocating ? null : _useMyLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isLocating
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.my_location, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Error message ─────────────────────────────────────────
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: Colors.red.withValues(alpha: 0.12),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),

              // ── Hint ─────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: isDark ? const Color(0xFF252535) : const Color(0xFFE8F5E9),
                child: Row(
                  children: [
                    Icon(Icons.touch_app_outlined, size: 16, color: AppThemes.primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      l10n.get('map_tap_hint'),
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  ],
                ),
              ),

              // ── Map ───────────────────────────────────────────────────
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: _selectedPoint != null ? 15 : 12,
                    onTap: (tapPosition, point) {
                      setState(() => _selectedPoint = point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.alveo.app',
                    ),
                    if (_selectedPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint!,
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                // Visual offset feedback; actual position updates on next tap
                              },
                              child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                            ),
                          ),
                        ],
                      ),
                    const RichAttributionWidget(
                      attributions: [TextSourceAttribution('OpenStreetMap contributors')],
                    ),
                  ],
                ),
              ),

              // ── Coordinates display ──────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: surfaceColor,
                child: Row(
                  children: [
                    Icon(Icons.pin_drop_outlined, size: 18, color: _selectedPoint != null ? AppThemes.primaryGreen : hintColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedPoint != null
                            ? 'Lat: ${_selectedPoint!.latitude.toStringAsFixed(6)}  |  Lng: ${_selectedPoint!.longitude.toStringAsFixed(6)}'
                            : l10n.get('no_location'),
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedPoint != null ? textColor : hintColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Action Buttons ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: bgColor,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: Text(l10n.get('cancel'), style: const TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _selectedPoint == null ? null : () => Navigator.pop(context, _selectedPoint),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(l10n.get('confirm_location')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemes.primaryGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

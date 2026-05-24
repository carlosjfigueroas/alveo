import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/property.dart';
import '../models/company.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PdfService {
  /// Convierte un Color de Flutter en PdfColor
  static PdfColor _toPdfColor(int colorValue) {
    final r = ((colorValue >> 16) & 0xFF) / 255.0;
    final g = ((colorValue >> 8) & 0xFF) / 255.0;
    final b = (colorValue & 0xFF) / 255.0;
    return PdfColor(r, g, b);
  }

  static Future<void> generatePropertyPdf(
    Property property, {
    String lang = 'es',
    Company? company,
  }) async {
    final pdf = pw.Document();
    final activeCompany = company ?? Company.empty;

    // ─── Colores de la empresa activa ──────────────────────────────────────
    final primaryPdf = _toPdfColor(activeCompany.primaryColor.toARGB32());
    final secondaryPdf = _toPdfColor(activeCompany.secondaryColor.toARGB32());

    final isEs = lang == 'es';
    final companyDisplayName = activeCompany.localizedName(lang);

    // ─── Textos localizados ────────────────────────────────────────────────
    final labels = {
      'title':         isEs ? 'Propuesta Inmobiliaria' : 'Real Estate Proposal',
      'price_request': isEs ? 'Precio a Consultar'     : 'Price on Request',
      'location':      isEs ? 'Ubicación'              : 'Location',
      'specific':      isEs ? 'Específica'             : 'Specific',
      'area':          isEs ? 'Área'                   : 'Area',
      'bathrooms':     isEs ? 'Baños'                  : 'Bathrooms',
      'bedrooms':      isEs ? 'Habitaciones'           : 'Bedrooms',
      'parking':       isEs ? 'Estacionamiento'        : 'Parking',
      'year':          isEs ? 'Año'                    : 'Year',
      'plot':          isEs ? 'Parcela'                : 'Plot',
      'amenities':     isEs ? 'Comodidades' : 'Features',
      // Footer — usa datos reales de la empresa
      'footer_text':   '$companyDisplayName — ${isEs ? 'Expertos en Gestión Inmobiliaria' : 'Property Management Experts'}',
      'contact':       _buildContactLine(activeCompany),
    };

    final translations = isEs ? {
      'Venta': 'Venta', 'Alquiler': 'Alquiler', 'Casa': 'Casa',
      'Apartamento': 'Apartamento', 'Local': 'Local Comercial',
      'Oficina': 'Oficina', 'Almacén': 'Almacén', 'Terreno': 'Terreno',
      'Hotel': 'Hotel', 'Posada': 'Posada', 'Galpon': 'Galpón',
      'Tienda': 'Tienda', 'Patio Industrial': 'Patio Industrial', 'Centro Comercial': 'Centro Comercial',
    } : {
      'Venta': 'Sale', 'Alquiler': 'Rent', 'Casa': 'House',
      'Apartamento': 'Apartment', 'Local': 'Commercial Local',
      'Oficina': 'Office', 'Almacén': 'Warehouse', 'Terreno': 'Land',
      'Hotel': 'Hotel', 'Posada': 'Inn', 'Galpon': 'Warehouse / Shed',
      'Tienda': 'Shop', 'Patio Industrial': 'Patio Industrial', 'Centro Comercial': 'Shopping Center',
    };

    final amenityLabels = isEs ? {
      'pool': 'Piscina', 'garden': 'Jardín', 'security': 'Seguridad',
      'air_con': 'Aire Acondicionado', 'storage': 'Almacén Extra',
      'terrace': 'Terraza', 'balcony': 'Balcón', 'patio': 'Patio',
      'garage': 'Garaje', 'elevator': 'Ascensor', 'waterfront': 'Primera Línea',
      'sea_view': 'Vistas al Mar', 'furnished': 'Amoblado',
      'kitchen': 'Cocina', 'basement': 'Sótano',
      'power': 'Planta Eléctrica', 'water': 'Tanque de Agua',
      'grill': 'Parrillera', 'pets_allowed': 'Permite Mascotas', 'children_allowed': 'Permite Niños',
    } : {
      'pool': 'Pool', 'garden': 'Garden', 'security': 'Security',
      'air_con': 'Air Conditioning', 'storage': 'Extra Storage',
      'terrace': 'Terrace', 'balcony': 'Balcony', 'patio': 'Patio',
      'garage': 'Garage', 'elevator': 'Elevator', 'waterfront': 'Waterfront',
      'sea_view': 'Sea View', 'furnished': 'Furnished',
      'kitchen': 'Fitted Kitchen', 'basement': 'Basement',
      'power': 'Power Generator', 'water': 'Water Tank',
      'grill': 'Grill', 'pets_allowed': 'Pets Allowed', 'children_allowed': 'Children Allowed',
    };

    final typeTrans = translations[property.type] ?? property.type;
    final opTrans   = translations[property.operationType] ?? property.operationType;

    // ─── Logo de la empresa (red → local fallback) ────────────────────────
    pw.MemoryImage logoImage;
    if (activeCompany.logoUrl != null && activeCompany.logoUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(activeCompany.logoUrl!));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        } else {
          logoImage = await _localLogoFallback();
        }
      } catch (_) {
        logoImage = await _localLogoFallback();
      }
    } else {
      logoImage = await _localLogoFallback();
    }

    // ─── Imagen principal del inmueble (red) ──────────────────────────────
    pw.MemoryImage? mainImage;
    if (property.imageUrls.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(property.imageUrls[0]));
        if (response.statusCode == 200) {
          mainImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }

    // ─── Construcción del PDF ─────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Cabecera con branding dinámico ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    height: 70,
                    child: pw.Image(logoImage),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(companyDisplayName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryPdf,
                          )),
                      if (activeCompany.contactEmail != null)
                        pw.Text(activeCompany.contactEmail!, style: const pw.TextStyle(fontSize: 9)),
                      if (activeCompany.contactPhone != null)
                        pw.Text(activeCompany.contactPhone!, style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 10),
                      pw.Text(labels['title']!,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: secondaryPdf,
                          )),
                      pw.Text(
                        'Ref: ${(property.refNumber ?? 0).toString().padLeft(3, '0')}',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: primaryPdf, thickness: 1.5),
              pw.SizedBox(height: 16),

              // ── Título y precio ──
              pw.Text(property.title,
                  style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800)),
              pw.Text('$typeTrans ${isEs ? 'en' : 'for'} $opTrans',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              pw.SizedBox(height: 5),
              pw.Text(
                property.price == 0
                    ? labels['price_request']!
                    : '${activeCompany.currencyCode} ${activeCompany.currencySymbol}${NumberFormat("#,##0", isEs ? 'es_ES' : 'en_US').format(property.price)}',
                style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryPdf),
              ),
              pw.SizedBox(height: 14),

              // ── Imagen principal ──
              if (mainImage != null)
                pw.Center(
                  child: pw.Container(
                    height: 230,
                    width: double.infinity,
                    child: pw.Image(mainImage, fit: pw.BoxFit.cover),
                  ),
                ),
              pw.SizedBox(height: 14),

              // ── Ubicación y descripción ──
              pw.Text('${labels['location']!}: ${property.address}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              if (property.locationLabel.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(property.locationLabel,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ),
              if (property.details?.interiorLocation != null &&
                  property.details!.interiorLocation!.isNotEmpty)
                pw.Text('${labels['specific']!}: ${property.details!.interiorLocation}'),
              pw.SizedBox(height: 8),
              pw.Text(property.description ?? ''),
              pw.SizedBox(height: 14),

              // ── Detalles técnicos ──
              pw.Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _detailBox(labels['area']!,
                      '${property.details?.areaM2 ?? 0} ${activeCompany.areaUnit}', primaryPdf),
                  if ((property.details?.bathrooms ?? 0) > 0)
                    _detailBox(labels['bathrooms']!,
                        '${property.details?.bathrooms}', primaryPdf),
                  if ((property.details?.bedrooms ?? 0) > 0)
                    _detailBox(labels['bedrooms']!,
                        '${property.details!.bedrooms}', primaryPdf),
                  if ((property.details?.parkingSpaces ?? 0) > 0)
                    _detailBox(labels['parking']!,
                        '${property.details?.parkingSpaces}', primaryPdf),
                  if (property.details?.yearBuilt != null)
                    _detailBox(labels['year']!,
                        '${property.details!.yearBuilt}', primaryPdf),
                  if ((property.details?.plotAreaM2 ?? 0) > 0)
                    _detailBox(labels['plot']!,
                        '${property.details!.plotAreaM2} ${activeCompany.areaUnit}', primaryPdf),
                ],
              ),
              pw.SizedBox(height: 18),

              // ── Amenidades ──
              pw.Text(labels['amenities']!,
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryPdf)),
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 20,
                runSpacing: 5,
                children: [
                  if (property.details?.hasPool == true)         _amenityItem(amenityLabels['pool']!, primaryPdf),
                  if (property.details?.hasGarden == true)       _amenityItem(amenityLabels['garden']!, primaryPdf),
                  if (property.details?.hasSecurity == true)     _amenityItem(amenityLabels['security']!, primaryPdf),
                  if (property.details?.hasAirCon == true)       _amenityItem(amenityLabels['air_con']!, primaryPdf),
                  if (property.details?.hasExtraStorage == true) _amenityItem(amenityLabels['storage']!, primaryPdf),
                  if (property.details?.hasTerrace == true)      _amenityItem(amenityLabels['terrace']!, primaryPdf),
                  if (property.details?.hasBalcony == true)      _amenityItem(amenityLabels['balcony']!, primaryPdf),
                  if (property.details?.hasPatio == true)        _amenityItem(amenityLabels['patio']!, primaryPdf),
                  if (property.details?.hasGarage == true)       _amenityItem(amenityLabels['garage']!, primaryPdf),
                  if (property.details?.hasElevator == true)     _amenityItem(amenityLabels['elevator']!, primaryPdf),
                  if (property.details?.isWaterfront == true)    _amenityItem(amenityLabels['waterfront']!, primaryPdf),
                  if (property.details?.hasSeaView == true)      _amenityItem(amenityLabels['sea_view']!, primaryPdf),
                  if (property.details?.isFurnished == true)     _amenityItem(amenityLabels['furnished']!, primaryPdf),
                  if (property.details?.hasFittedKitchen == true) _amenityItem(amenityLabels['kitchen']!, primaryPdf),
                  if (property.details?.hasBasement == true)     _amenityItem(amenityLabels['basement']!, primaryPdf),
                  if (property.details?.hasPowerGenerator == true) _amenityItem(amenityLabels['power']!, primaryPdf),
                  if (property.details?.hasWaterTank == true)    _amenityItem(amenityLabels['water']!, primaryPdf),
                  if (property.details?.hasGrill == true)        _amenityItem(amenityLabels['grill']!, primaryPdf),
                  if (property.isResidential && property.isAlquiler) ...[
                    if (property.details?.petsAllowed == true)     _amenityItem(amenityLabels['pets_allowed']!, primaryPdf),
                    if (property.details?.childrenAllowed == true)  _amenityItem(amenityLabels['children_allowed']!, primaryPdf),
                  ],
                ],
              ),

              pw.Spacer(),

              // ── Pie de página con branding de Alveo ──
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(companyDisplayName,
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black)),
                      pw.Text(labels['contact']!,
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Propuesta_${property.refNumber}_${activeCompany.abbr}.pdf',
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static Future<pw.MemoryImage> _localLogoFallback() async {
    final data = await rootBundle.load('assets/images/logo_full.png');
    return pw.MemoryImage(data.buffer.asUint8List());
  }

  static String _buildContactLine(Company company) {
    final parts = <String>[];
    if (company.domain.isNotEmpty) parts.add('Web: ${company.domain}');
    if (company.contactEmail?.isNotEmpty ?? false) parts.add('Email: ${company.contactEmail}');
    if (company.contactPhone?.isNotEmpty ?? false) parts.add('Tel: ${company.contactPhone}');
    if (parts.isEmpty) return company.domain;
    return parts.join('  |  ');
  }

  static pw.Widget _detailBox(String label, String value, PdfColor accent) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      width: 72,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: accent),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 8, color: accent)),
          pw.Text(value,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _amenityItem(String label, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 6,
          height: 6,
          decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
        ),
        pw.SizedBox(width: 5),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }
}

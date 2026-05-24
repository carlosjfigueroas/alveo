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

  /// Versión aclarada de un PdfColor (para fondos de chips)
  static PdfColor _lightTint(PdfColor c, {double opacity = 0.12}) {
    return PdfColor(
      1.0 - (1.0 - c.red) * opacity,
      1.0 - (1.0 - c.green) * opacity,
      1.0 - (1.0 - c.blue) * opacity,
    );
  }

  static Future<void> generatePropertyPdf(
    Property property, {
    String lang = 'es',
    Company? company,
  }) async {
    final pdf = pw.Document();
    final activeCompany = company ?? Company.empty;

    // ─── Paleta de colores ─────────────────────────────────────────────────
    final primaryPdf   = _toPdfColor(activeCompany.primaryColor.toARGB32());
    final secondaryPdf = _toPdfColor(activeCompany.secondaryColor.toARGB32());
    final lightPrimary = _lightTint(primaryPdf, opacity: 0.10);
    const darkText     = PdfColors.blueGrey900;
    const mutedText    = PdfColors.blueGrey400;
    const cardBg       = PdfColor(0.97, 0.97, 0.97);

    final isEs = lang == 'es';
    final companyDisplayName = activeCompany.localizedName(lang);

    // ─── Labels localizados ────────────────────────────────────────────────
    final l = {
      'sheet_title':    isEs ? 'Ficha del Inmueble'         : 'Property Sheet',
      'price_request':  isEs ? 'Precio a Consultar'         : 'Price on Request',
      'location':       isEs ? 'Ubicación'                  : 'Location',
      'specific':       isEs ? 'Específica'                 : 'Specific',
      'area':           isEs ? 'Área'                       : 'Area',
      'bathrooms':      isEs ? 'Baños'                      : 'Bathrooms',
      'bedrooms':       isEs ? 'Habitaciones'               : 'Bedrooms',
      'parking':        isEs ? 'Estacionamiento'            : 'Parking',
      'year':           isEs ? 'Año'                        : 'Year',
      'plot':           isEs ? 'Parcela'                    : 'Plot',
      'amenities':      isEs ? 'Comodidades'                : 'Features',
      'delivery':       isEs ? 'Estado de entrega'          : 'Delivery Status',
      'level':          isEs ? 'Nivel'                      : 'Level',
      'for_sale':       isEs ? 'en Venta'                   : 'for Sale',
      'for_rent':       isEs ? 'en Alquiler'                : 'for Rent',
      'ref':            'Ref.',
      'footer_text':    '$companyDisplayName — ${isEs ? 'Expertos en Gestión Inmobiliaria' : 'Property Management Experts'}',
      'contact':        _buildContactLine(activeCompany),
    };

    // ─── Traducciones de tipo / operación ─────────────────────────────────
    final typeTrans = isEs ? {
      'Venta': 'Venta', 'Alquiler': 'Alquiler', 'Casa': 'Casa',
      'Apartamento': 'Apartamento', 'Local': 'Local Comercial',
      'Oficina': 'Oficina', 'Almacén': 'Almacén', 'Terreno': 'Terreno',
      'Hotel': 'Hotel', 'Posada': 'Posada', 'Galpon': 'Galpón',
      'Tienda': 'Tienda', 'Patio Industrial': 'Patio Industrial',
      'Centro Comercial': 'Centro Comercial', 'Loft': 'Townhouse',
      'Estudio': 'Estudio', 'Otro': 'Otro',
    } : {
      'Venta': 'Sale', 'Alquiler': 'Rent', 'Casa': 'House',
      'Apartamento': 'Apartment', 'Local': 'Commercial Space',
      'Oficina': 'Office', 'Almacén': 'Warehouse', 'Terreno': 'Land',
      'Hotel': 'Hotel', 'Posada': 'Inn', 'Galpon': 'Shed',
      'Tienda': 'Shop', 'Patio Industrial': 'Industrial Yard',
      'Centro Comercial': 'Shopping Center', 'Loft': 'Townhouse',
      'Estudio': 'Studio', 'Otro': 'Other',
    };

    // ─── Traducciones de valores comerciales ───────────────────────────────
    final deliveryTrans = isEs ? {
      'obra_gris':        'Obra gris',
      'semi_acabado':     'Semi acabado',
      'listo_para_ocupar':'Listo para ocupar',
    } : {
      'obra_gris':        'Shell & Core',
      'semi_acabado':     'Semi-finished',
      'listo_para_ocupar':'Ready to Occupy',
    };

    final floorTrans = isEs ? {
      'planta_baja':          'Planta baja',
      'mezzanina':            'Mezzanina',
      'primer_piso':          'Primer piso',
      'segundo_piso':         'Segundo piso',
      'tercer_piso':          'Tercer piso',
      'cuarto_piso':          'Cuarto piso',
      'incluido_en_direccion':'Especificado en dirección',
    } : {
      'planta_baja':          'Ground Floor',
      'mezzanina':            'Mezzanine',
      'primer_piso':          '1st Floor',
      'segundo_piso':         '2nd Floor',
      'tercer_piso':          '3rd Floor',
      'cuarto_piso':          '4th Floor',
      'incluido_en_direccion':'Specified in Address',
    };

    // ─── Labels de comodidades ─────────────────────────────────────────────
    final amenityLabels = isEs ? {
      'pool':             'Piscina',
      'garden':           'Jardín',
      'security':         'Seguridad',
      'air_con':          'Aire Acondicionado',
      'storage':          'Almacén Extra',
      'terrace':          'Terraza',
      'balcony':          'Balcón',
      'patio':            'Patio',
      'garage':           'Garaje',
      'elevator':         'Ascensor',
      'waterfront':       'Primera Línea de Mar',
      'sea_view':         'Vista al Mar',
      'furnished':        'Amoblado',
      'kitchen':          'Cocina Empotrada',
      'basement':         'Sótano',
      'power':            'Planta Eléctrica',
      'water':            'Tanque de Agua',
      'grill':            'Parrillera',
      'pets_allowed':     'Permite Mascotas',
      'children_allowed': 'Permite Niños',
      'electricity':      'Electricidad',
      'water_conn':       'Puntos de Agua',
      'restroom':         'Acceso a Baños',
      'ac_conn':          'Conexión para A/A',
      'internal_storage': 'Área interna Almacén/Oficina',
    } : {
      'pool':             'Pool',
      'garden':           'Garden',
      'security':         'Security',
      'air_con':          'Air Conditioning',
      'storage':          'Extra Storage',
      'terrace':          'Terrace',
      'balcony':          'Balcony',
      'patio':            'Patio',
      'garage':           'Garage',
      'elevator':         'Elevator',
      'waterfront':       'Waterfront',
      'sea_view':         'Sea View',
      'furnished':        'Furnished',
      'kitchen':          'Fitted Kitchen',
      'basement':         'Basement',
      'power':            'Power Generator',
      'water':            'Water Tank',
      'grill':            'Grill / BBQ',
      'pets_allowed':     'Pets Allowed',
      'children_allowed': 'Children Allowed',
      'electricity':      'Electricity',
      'water_conn':       'Water Points',
      'restroom':         'Restroom Access',
      'ac_conn':          'A/C Connection',
      'internal_storage': 'Internal Storage/Office Area',
    };

    final propType = typeTrans[property.type] ?? property.type;
    final opLabel  = property.operationType == 'Venta' ? l['for_sale']! : l['for_rent']!;

    // ─── Imágenes ──────────────────────────────────────────────────────────
    pw.MemoryImage logoImage;
    if (activeCompany.logoUrl != null && activeCompany.logoUrl!.isNotEmpty) {
      try {
        final r = await http.get(Uri.parse(activeCompany.logoUrl!));
        logoImage = r.statusCode == 200
            ? pw.MemoryImage(r.bodyBytes)
            : await _localLogoFallback();
      } catch (_) {
        logoImage = await _localLogoFallback();
      }
    } else {
      logoImage = await _localLogoFallback();
    }

    pw.MemoryImage? mainImage;
    pw.MemoryImage? secondImage;
    if (property.imageUrls.isNotEmpty) {
      try {
        final r = await http.get(Uri.parse(property.imageUrls[0]));
        if (r.statusCode == 200) mainImage = pw.MemoryImage(r.bodyBytes);
      } catch (_) {}
    }
    if (property.imageUrls.length > 1) {
      try {
        final r = await http.get(Uri.parse(property.imageUrls[1]));
        if (r.statusCode == 200) secondImage = pw.MemoryImage(r.bodyBytes);
      } catch (_) {}
    }

    // ─── Construir listas de comodidades ───────────────────────────────────
    final List<String> amenities = [];
    final d = property.details;
    if (d != null) {
      if (d.hasPool == true)            amenities.add(amenityLabels['pool']!);
      if (d.hasGarden == true)          amenities.add(amenityLabels['garden']!);
      if (d.hasSecurity == true)        amenities.add(amenityLabels['security']!);
      if (d.hasAirCon == true)          amenities.add(amenityLabels['air_con']!);
      if (d.hasExtraStorage == true)    amenities.add(amenityLabels['storage']!);
      if (d.hasTerrace == true)         amenities.add(amenityLabels['terrace']!);
      if (d.hasBalcony == true)         amenities.add(amenityLabels['balcony']!);
      if (d.hasPatio == true)           amenities.add(amenityLabels['patio']!);
      if (d.hasGarage == true)          amenities.add(amenityLabels['garage']!);
      if (d.hasElevator == true)        amenities.add(amenityLabels['elevator']!);
      if (d.isWaterfront == true)       amenities.add(amenityLabels['waterfront']!);
      if (d.hasSeaView == true)         amenities.add(amenityLabels['sea_view']!);
      if (d.isFurnished == true)        amenities.add(amenityLabels['furnished']!);
      if (d.hasFittedKitchen == true)   amenities.add(amenityLabels['kitchen']!);
      if (d.hasBasement == true)        amenities.add(amenityLabels['basement']!);
      if (d.hasPowerGenerator == true)  amenities.add(amenityLabels['power']!);
      if (d.hasWaterTank == true)       amenities.add(amenityLabels['water']!);
      if (d.hasGrill == true)           amenities.add(amenityLabels['grill']!);
      if (d.petsAllowed == true)        amenities.add(amenityLabels['pets_allowed']!);
      if (d.childrenAllowed == true)    amenities.add(amenityLabels['children_allowed']!);
      // Nuevos campos comerciales — siempre
      if (d.hasElectricity == true)         amenities.add(amenityLabels['electricity']!);
      if (d.hasWaterConnections == true)    amenities.add(amenityLabels['water_conn']!);
      if (d.hasRestroomAccess == true)      amenities.add(amenityLabels['restroom']!);
      if (d.hasAcConnection == true)        amenities.add(amenityLabels['ac_conn']!);
      if (d.hasStorageOfficeArea == true)   amenities.add(amenityLabels['internal_storage']!);
    }

    // ─── Construcción del PDF ─────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              // ══════════════════════════════════════════════════════════════
              // HEADER
              // ══════════════════════════════════════════════════════════════
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Logo
                  pw.Container(
                    height: 52,
                    padding: const pw.EdgeInsets.only(right: 12),
                    child: pw.Image(logoImage),
                  ),
                  pw.Container(width: 1, height: 52, color: primaryPdf),
                  pw.SizedBox(width: 12),
                  // Company info
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          companyDisplayName,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        if (activeCompany.contactEmail != null && activeCompany.contactEmail!.isNotEmpty)
                          pw.Text(activeCompany.contactEmail!,
                              style: pw.TextStyle(fontSize: 8, color: mutedText)),
                        if (activeCompany.contactPhone != null && activeCompany.contactPhone!.isNotEmpty)
                          pw.Text(activeCompany.contactPhone!,
                              style: pw.TextStyle(fontSize: 8, color: mutedText)),
                        if (activeCompany.domain.isNotEmpty)
                          pw.Text(activeCompany.domain,
                              style: pw.TextStyle(fontSize: 8, color: mutedText)),
                      ],
                    ),
                  ),
                  // Sheet title + Ref badge
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        l['sheet_title']!,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryPdf,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: primaryPdf,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          '${l['ref']!} ${(property.refNumber ?? 0).toString().padLeft(3, '0')}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(height: 2, color: primaryPdf),
              pw.SizedBox(height: 10),

              // ══════════════════════════════════════════════════════════════
              // TITLE + TYPE BADGE + PRICE
              // ══════════════════════════════════════════════════════════════
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          property.title,
                          style: pw.TextStyle(
                            fontSize: 17,
                            fontWeight: pw.FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: lightPrimary,
                                border: pw.Border.all(color: primaryPdf, width: 0.5),
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                              ),
                              child: pw.Text(
                                propType,
                                style: pw.TextStyle(fontSize: 8, color: primaryPdf, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.SizedBox(width: 6),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: lightPrimary,
                                border: pw.Border.all(color: secondaryPdf, width: 0.5),
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                              ),
                              child: pw.Text(
                                opLabel,
                                style: pw.TextStyle(fontSize: 8, color: secondaryPdf, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  // Price block
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: primaryPdf,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          property.price == 0
                              ? l['price_request']!
                              : '${activeCompany.currencyCode} ${activeCompany.currencySymbol}${NumberFormat('#,##0', isEs ? 'es_ES' : 'en_US').format(property.price)}',
                          style: pw.TextStyle(
                            fontSize: 17,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        if (property.price > 0 && (property.details?.areaM2 ?? 0) > 0)
                          pw.Text(
                            '${activeCompany.currencySymbol}${NumberFormat('#,##0', isEs ? 'es_ES' : 'en_US').format(property.price / property.details!.areaM2)} / ${activeCompany.areaUnit}',
                            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey300),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ══════════════════════════════════════════════════════════════
              // PHOTOS (max 2, side by side)
              // ══════════════════════════════════════════════════════════════
              if (mainImage != null)
                pw.Container(
                  height: 165,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.ClipRRect(
                          horizontalRadius: 5,
                          verticalRadius: 5,
                          child: pw.Image(mainImage, fit: pw.BoxFit.cover, height: 165),
                        ),
                      ),
                      if (secondImage != null) ...[
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.ClipRRect(
                            horizontalRadius: 5,
                            verticalRadius: 5,
                            child: pw.Image(secondImage, fit: pw.BoxFit.cover, height: 165),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              pw.SizedBox(height: 10),

              // ══════════════════════════════════════════════════════════════
              // LOCATION
              // ══════════════════════════════════════════════════════════════
               pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  border: pw.Border(left: pw.BorderSide(color: primaryPdf, width: 3)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${l['location']!}:  ',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryPdf,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                property.address,
                                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkText),
                              ),
                              if (property.locationLabel.isNotEmpty)
                                pw.Text(
                                  property.locationLabel,
                                  style: pw.TextStyle(fontSize: 9, color: mutedText, fontStyle: pw.FontStyle.italic),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // ══════════════════════════════════════════════════════════════
              // DESCRIPTION
              // ══════════════════════════════════════════════════════════════
              if (property.description != null && property.description!.isNotEmpty) ...[
                _sectionTitle(isEs ? 'Descripción' : 'Description', primaryPdf, secondaryPdf),
                pw.Text(
                  property.description!,
                  style: pw.TextStyle(fontSize: 9, color: darkText, lineSpacing: 1.4),
                  maxLines: 4,
                  overflow: pw.TextOverflow.clip,
                ),
                pw.SizedBox(height: 8),
              ],

              // ══════════════════════════════════════════════════════════════
              // TECHNICAL SPECS (detail boxes)
              // ══════════════════════════════════════════════════════════════
              pw.Row(
                children: [
                  if ((d?.areaM2 ?? 0) > 0)
                    _detailBox(l['area']!, '${d!.areaM2} ${activeCompany.areaUnit}', primaryPdf, lightPrimary),
                  if ((d?.bathrooms ?? 0) > 0)
                    _detailBox(l['bathrooms']!, '${d!.bathrooms}', primaryPdf, lightPrimary),
                  if ((d?.bedrooms ?? 0) > 0)
                    _detailBox(l['bedrooms']!, '${d!.bedrooms}', primaryPdf, lightPrimary),
                  if ((d?.parkingSpaces ?? 0) > 0)
                    _detailBox(l['parking']!, '${d!.parkingSpaces}', primaryPdf, lightPrimary),
                  if (d?.yearBuilt != null)
                    _detailBox(l['year']!, '${d!.yearBuilt}', primaryPdf, lightPrimary),
                  if ((d?.plotAreaM2 ?? 0) > 0)
                    _detailBox(l['plot']!, '${d!.plotAreaM2} ${activeCompany.areaUnit}', primaryPdf, lightPrimary),
                  // Estado de entrega
                  if (d?.deliveryStatus != null && d!.deliveryStatus!.isNotEmpty)
                    _detailBox(l['delivery']!, deliveryTrans[d.deliveryStatus] ?? d.deliveryStatus!, primaryPdf, lightPrimary),
                  // Nivel
                  if (d?.floorLevel != null && d!.floorLevel!.isNotEmpty && d.floorLevel != 'incluido_en_direccion')
                    _detailBox(l['level']!, floorTrans[d.floorLevel] ?? d.floorLevel!, primaryPdf, lightPrimary),
                ],
              ),
              pw.SizedBox(height: 10),

              // ══════════════════════════════════════════════════════════════
              // AMENITIES / FEATURES
              // ══════════════════════════════════════════════════════════════
              if (amenities.isNotEmpty) ...[
                _sectionTitle(l['amenities']!, primaryPdf, secondaryPdf),
                pw.SizedBox(height: 6),
                pw.Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: amenities.map((a) => _amenityChip(a, primaryPdf, lightPrimary)).toList(),
                ),
                pw.SizedBox(height: 6),
              ],

              pw.Spacer(),

              // ══════════════════════════════════════════════════════════════
              // FOOTER
              // ══════════════════════════════════════════════════════════════
              pw.Container(height: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyDisplayName,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      pw.Text(
                        l['contact']!,
                        style: pw.TextStyle(fontSize: 7, color: mutedText),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: lightPrimary,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      border: pw.Border.all(color: primaryPdf, width: 0.5),
                    ),
                    child: pw.Text(
                      '${l['ref']!} ${(property.refNumber ?? 0).toString().padLeft(3, '0')} · $propType $opLabel',
                      style: pw.TextStyle(fontSize: 7, color: primaryPdf),
                    ),
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
      name: 'Ficha_${property.refNumber}_${activeCompany.abbr}.pdf',
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

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

  static pw.Widget _sectionTitle(String title, PdfColor primary, PdfColor secondary) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.Container(width: 3, height: 14, color: primary),
          pw.SizedBox(width: 6),
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: primary,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Container(height: 0.5, color: PdfColors.grey300)),
        ],
      ),
    );
  }

  static pw.Widget _detailBox(String label, String value, PdfColor accent, PdfColor bg) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(right: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: pw.BoxDecoration(
        color: bg,
        border: pw.Border.all(color: accent, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: accent)),
          pw.Text(label,
              style: pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey400)),
        ],
      ),
    );
  }

  static pw.Widget _amenityChip(String label, PdfColor accent, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: bg,
        border: pw.Border.all(color: accent, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            decoration: pw.BoxDecoration(color: accent, shape: pw.BoxShape.circle),
          ),
          pw.SizedBox(width: 5),
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: accent)),
        ],
      ),
    );
  }
}

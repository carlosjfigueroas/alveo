import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Static hierarchical location data: Country → State → [Cities]
class LocationData {
  /// Returns a list of all available countries.
  static List<String> get countries {
    return List<String>.from(_data.keys)..sort();
  }
  /// Returns the list of states for a given country. Empty list if not found.
  static List<String> statesFor(String country) {
    return List<String>.from(_data[country]?.keys.toList() ?? [])..sort();
  }

  /// Returns the list of cities for a given country + state. Empty list if not found.
  static List<String> citiesFor(String country, String state) {
    return List<String>.from(_data[country]?[state] ?? [])..sort();
  }

  static late Map<String, dynamic> _data;
  
  /// Initializes location data using a two-step fallback strategy:
  /// 1. If [companyId] is provided, looks for a company-specific record first.
  /// 2. If no specific record exists (or companyId is null), falls back to
  ///    the shared global record (company_id IS NULL).
  /// This avoids data duplication across agencies operating in the same country.
  static Future<void> init({String? companyId}) async {
    try {
      Map<String, dynamic>? response;

      // Step 1: Try to load a company-specific configuration
      if (companyId != null) {
        response = await Supabase.instance.client
            .from('app_settings')
            .select('value')
            .eq('key', 'locations')
            .eq('company_id', companyId)
            .maybeSingle();
      }

      // Step 2: Fallback to the global record (company_id IS NULL)
      if (response == null) {
        response = await Supabase.instance.client
            .from('app_settings')
            .select('value')
            .eq('key', 'locations')
            .isFilter('company_id', null)
            .maybeSingle();
      }

      if (response != null && response['value'] != null) {
        // Parse the JSON correctly
        final Map<String, dynamic> raw = response['value'];
        final Map<String, Map<String, List<String>>> parsed = {};
        
        raw.forEach((country, statesData) {
          final Map<String, List<String>> statesMap = {};
          if (statesData is Map) {
            statesData.forEach((state, citiesList) {
              if (citiesList is List) {
                statesMap[state.toString()] = citiesList.map((e) => e.toString()).toList();
              }
            });
          }
          parsed[country.toString()] = statesMap;
        });
        
        _data = parsed;
      } else {
        _data = _defaultData;
      }
    } catch (e) {
      debugPrint('Error loading locations from DB: $e');
      _data = _defaultData; // Fallback to safe static data
    }
  }

  // Method to update data at runtime
  static void updateData(Map<String, Map<String, List<String>>> newData) {
    _data = newData;
  }

  static const Map<String, Map<String, List<String>>> _defaultData = {
    'Venezuela': {
      'Amazonas': ['Puerto Ayacucho', 'Maroa'],
      'Anzoátegui': ['Barcelona', 'Puerto La Cruz', 'El Tigre', 'Anaco', 'Cantaura', 'Lechería'],
      'Apure': ['San Fernando de Apure', 'Guasdualito'],
      'Aragua': ['Maracay', 'La Victoria', 'Cagua', 'Turmero', 'Villa de Cura'],
      'Barinas': ['Barinas', 'Barinitas', 'Ciudad Bolivia'],
      'Bolívar': ['Ciudad Bolívar', 'Puerto Ordaz', 'San Félix', 'Upata'],
      'Carabobo': ['Valencia', 'Puerto Cabello', 'Güigüe', 'Mariara'],
      'Cojedes': ['San Carlos', 'Tinaquillo'],
      'Delta Amacuro': ['Tucupita', 'Pedernales'],
      'Distrito Capital': ['Caracas'],
      'Falcón': ['Coro', 'La Vela de Coro', 'Punto Fijo', 'Chichiriviche'],
      'Guárico': ['San Juan de los Morros', 'Valle de la Pascua', 'Calabozo'],
      'Lara': ['Barquisimeto', 'Carora', 'El Tocuyo', 'Cabudare', 'Quíbor'],
      'Mérida': ['Mérida', 'El Vigía', 'Tovar', 'Ejido'],
      'Miranda': ['Los Teques', 'Guarenas', 'Guatire', 'Charallave', 'Ocumare del Tuy', 'Santa Teresa del Tuy', 'Cúa', 'Caucagua'],
      'Monagas': ['Maturín', 'Punta de Mata', 'Caripito'],
      'Nueva Esparta': ['La Asunción', 'Porlamar', 'Pampatar', 'Juangriego'],
      'Portuguesa': ['Guanare', 'Acarigua', 'Araure', 'Biscucuy'],
      'Sucre': ['Cumaná', 'Carúpano', 'Cariaco'],
      'Táchira': ['San Cristóbal', 'La Fría', 'Rubio', 'Táriba', 'San Antonio del Táchira'],
      'Trujillo': ['Trujillo', 'Valera', 'Boconó'],
      'Vargas': ['La Guaira', 'Maiquetía', 'Catia La Mar'],
      'Yaracuy': ['San Felipe', 'Chivacoa', 'Yaritagua'],
      'Zulia': ['Maracaibo', 'Cabimas', 'Ciudad Ojeda', 'San Francisco', 'Lagunillas'],
    },
    'Colombia': {
      'Antioquia': ['Medellín', 'Bello', 'Itagüí', 'Envigado', 'Rionegro', 'Apartadó'],
      'Atlántico': ['Barranquilla', 'Soledad', 'Malambo'],
      'Bogotá D.C.': ['Bogotá'],
      'Bolívar': ['Cartagena', 'Magangué', 'El Carmen de Bolívar'],
      'Boyacá': ['Tunja', 'Duitama', 'Sogamoso'],
      'Caldas': ['Manizales', 'Villamaría', 'La Dorada'],
      'Cauca': ['Popayán', 'Santander de Quilichao'],
      'Cesar': ['Valledupar', 'Aguachica'],
      'Córdoba': ['Montería', 'Lorica', 'Cereté'],
      'Cundinamarca': ['Soacha', 'Fusagasugá', 'Zipaquirá', 'Facatativá', 'Chía'],
      'Huila': ['Neiva', 'Pitalito', 'Garzón'],
      'Magdalena': ['Santa Marta', 'Ciénaga'],
      'Meta': ['Villavicencio', 'Acacías', 'Granada'],
      'Nariño': ['Pasto', 'Ipiales', 'Tumaco'],
      'Norte de Santander': ['Cúcuta', 'Ocaña', 'Pamplona'],
      'Quindío': ['Armenia', 'Calarcá'],
      'Risaralda': ['Pereira', 'Dosquebradas', 'Santa Rosa de Cabal'],
      'Santander': ['Bucaramanga', 'Floridablanca', 'Girón', 'Piedecuesta', 'Barrancabermeja'],
      'Sucre': ['Sincelejo', 'Corozal'],
      'Tolima': ['Ibagué', 'Espinal', 'Melgar'],
      'Valle del Cauca': ['Cali', 'Buenaventura', 'Palmira', 'Tuluá', 'Cartago', 'Buga'],
    },
    'Bolivia': {
      'Beni': ['Trinidad', 'Riberalta', 'Guayaramerín'],
      'Chuquisaca': ['Sucre', 'Camiri'],
      'Cochabamba': ['Cochabamba', 'Quillacollo', 'Sacaba', 'Tiquipaya'],
      'La Paz': ['La Paz', 'El Alto', 'Viacha', 'Achacachi'],
      'Oruro': ['Oruro', 'Llallagua'],
      'Pando': ['Cobija'],
      'Potosí': ['Potosí', 'Villazón', 'Uyuni'],
      'Santa Cruz': ['Santa Cruz de la Sierra', 'Warnes', 'Montero', 'La Guardia', 'Cotoca'],
      'Tarija': ['Tarija', 'Yacuiba', 'Bermejo'],
    },
    'USA': {
      'Alabama': ['Birmingham', 'Montgomery', 'Huntsville', 'Mobile'],
      'Alaska': ['Anchorage', 'Fairbanks', 'Juneau'],
      'Arizona': ['Phoenix', 'Tucson', 'Mesa', 'Chandler', 'Scottsdale'],
      'California': ['Los Angeles', 'San Francisco', 'San Diego', 'San Jose', 'Sacramento', 'Fresno', 'Oakland'],
      'Colorado': ['Denver', 'Colorado Springs', 'Aurora', 'Fort Collins'],
      'Florida': ['Miami', 'Orlando', 'Tampa', 'Jacksonville', 'Tallahassee', 'Fort Lauderdale', 'Boca Raton', 'Doral', 'Hialeah'],
      'Georgia': ['Atlanta', 'Augusta', 'Columbus', 'Savannah'],
      'Illinois': ['Chicago', 'Aurora', 'Naperville', 'Joliet'],
      'Massachusetts': ['Boston', 'Worcester', 'Springfield', 'Cambridge'],
      'Nevada': ['Las Vegas', 'Henderson', 'Reno'],
      'New Jersey': ['Newark', 'Jersey City', 'Paterson', 'Elizabeth'],
      'New Mexico': ['Albuquerque', 'Santa Fe', 'Las Cruces'],
      'New York': ['New York City', 'Buffalo', 'Rochester', 'Yonkers', 'Syracuse'],
      'North Carolina': ['Charlotte', 'Raleigh', 'Greensboro', 'Durham'],
      'Ohio': ['Columbus', 'Cleveland', 'Cincinnati', 'Toledo'],
      'Pennsylvania': ['Philadelphia', 'Pittsburgh', 'Allentown'],
      'Texas': ['Houston', 'San Antonio', 'Dallas', 'Austin', 'Fort Worth', 'El Paso', 'Arlington'],
      'Virginia': ['Virginia Beach', 'Norfolk', 'Richmond', 'Alexandria'],
      'Washington': ['Seattle', 'Spokane', 'Tacoma', 'Bellevue'],
    },
  };
}

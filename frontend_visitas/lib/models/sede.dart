import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/institucion.dart';

class Sede {
  final int id;
  final String nombreSede;
  final Municipio? municipio;
  final Institucion? institucion;

  Sede({
    required this.id, 
    required this.nombreSede,
    this.municipio,
    this.institucion,
  });

  factory Sede.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Procesando JSON sede: $json');
      final id = json['id'];
      final nombreSede = json['nombre']; // Cambiado de 'nombre_sede' a 'nombre'
      
      print('🔍 ID: $id (tipo: ${id.runtimeType})');
      print('🔍 NombreSede: $nombreSede (tipo: ${nombreSede.runtimeType})');
      
      return Sede(
        id: id is int ? id : (id is String ? int.tryParse(id) ?? 0 : 0),
        nombreSede: nombreSede is String ? nombreSede : (nombreSede?.toString() ?? ''),
        municipio: json['municipio'] != null ? Municipio.fromJson(json['municipio']) : null,
        institucion: json['institucion'] != null ? Institucion.fromJson(json['institucion']) : null,
      );
    } catch (e) {
      print('❌ Error procesando sede: $e');
      return Sede(id: 0, nombreSede: 'Error');
    }
  }

  // Getter para compatibilidad con el código existente
  String get nombre => nombreSede;

  @override
  String toString() => nombreSede;
}

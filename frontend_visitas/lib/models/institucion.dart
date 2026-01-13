class Institucion {
  final int id;
  final String nombre;

  Institucion({required this.id, required this.nombre});

  factory Institucion.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Procesando JSON institución: $json');
      final id = json['id'];
      final nombre = json['nombre'];
      
      print('🔍 ID: $id (tipo: ${id.runtimeType})');
      print('🔍 Nombre: $nombre (tipo: ${nombre.runtimeType})');
      
      return Institucion(
        id: id is int ? id : (id is String ? int.tryParse(id) ?? 0 : 0),
        nombre: nombre is String ? nombre : (nombre?.toString() ?? ''),
      );
    } catch (e) {
      print('❌ Error procesando institución: $e');
      return Institucion(id: 0, nombre: 'Error');
    }
  }

  @override
  String toString() => nombre;
}

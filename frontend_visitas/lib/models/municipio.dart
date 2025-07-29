// lib/models/municipio.dart

class Municipio {
  final int id;
  final String nombre;

  Municipio({required this.id, required this.nombre});

  factory Municipio.fromJson(Map<String, dynamic> json) {
    return Municipio(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}
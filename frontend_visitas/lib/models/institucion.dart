class Institucion {
  final int id;
  final String nombre;

  Institucion({
    required this.id,
    required this.nombre,
  });

  factory Institucion.fromJson(Map<String, dynamic> json) {
    return Institucion(
      id: json['id'],
      nombre: json['nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}

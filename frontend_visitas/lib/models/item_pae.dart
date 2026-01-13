class ItemPAE {
  final int id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final int orden;
  final bool activo;

  ItemPAE({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.orden,
    required this.activo,
  });

  factory ItemPAE.fromJson(Map<String, dynamic> json) {
    return ItemPAE(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      categoria: json['categoria'],
      orden: json['orden'],
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'orden': orden,
      'activo': activo,
    };
  }
} 
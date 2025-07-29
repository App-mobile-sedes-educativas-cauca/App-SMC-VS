class Sede {
  final int id;
  final String nombreSede;

  Sede({required this.id, required this.nombreSede});

  factory Sede.fromJson(Map<String, dynamic> json) {
    return Sede(
      id: json['id'],
      nombreSede: json['nombre_sede'],
    );
  }

  @override
  String toString() => nombreSede;
}

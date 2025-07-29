// lib/models/visita.dart

import 'package:frontend_visitas/models/sede.dart';
import 'package:frontend_visitas/models/usuario.dart';

class Visita {
  final int id;
  final DateTime fechaCreacion;
  final String estado;
  final String? observaciones;
  final String tipoAsunto; // <--- CAMPO AÑADIDO
  final Sede sede;
  final Usuario usuario;

  Visita({
    required this.id,
    required this.fechaCreacion,
    required this.estado,
    required this.tipoAsunto, // <--- CAMPO AÑADIDO
    this.observaciones,
    required this.sede,
    required this.usuario,
  });

  factory Visita.fromJson(Map<String, dynamic> json) {
    // Asegúrate de que los nombres de los campos coincidan con el JSON de tu API
    return Visita(
      id: json['id'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      estado: json['estado'],
      tipoAsunto: json['tipo_asunto'] ?? 'Sin asunto', // <--- CAMPO AÑADIDO
      observaciones: json['observaciones'],
      sede: Sede.fromJson(json['sede']),
      usuario: Usuario.fromJson(json['usuario']),
    );
  }
}
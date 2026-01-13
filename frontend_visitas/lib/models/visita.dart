// lib/models/visita.dart

import 'package:frontend_visitas/models/sede.dart';
import 'package:frontend_visitas/models/usuario.dart';

class Visita {
  final int id;
  final DateTime? fechaCreacion;
  final String? estado;
  final String? observaciones;
  final String? tipoAsunto;
  final Sede? sede;
  final Usuario? usuario;
  final double? lat;
  final double? lon;
  final String? fotoEvidencia;
  final String? pdfEvidencia;
  final String? fotoFirma;

  Visita({
    required this.id,
    this.fechaCreacion,
    this.estado,
    this.tipoAsunto,
    this.observaciones,
    this.sede,
    this.usuario,
    this.lat,
    this.lon,
    this.fotoEvidencia,
    this.pdfEvidencia,
    this.fotoFirma,
  });

  factory Visita.fromJson(Map<String, dynamic> json) {
    return Visita(
      id: json['id'],
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion']) 
          : null,
      estado: json['estado'],
      tipoAsunto: json['tipo_asunto'],
      observaciones: json['observaciones'],
      sede: json['sede'] != null ? Sede.fromJson(json['sede']) : null,
      usuario: json['usuario'] != null ? Usuario.fromJson(json['usuario']) : null,
      lat: json['lat']?.toDouble(),
      lon: json['lon']?.toDouble(),
      fotoEvidencia: json['foto_evidencia'],
      pdfEvidencia: json['pdf_evidencia'],
      fotoFirma: json['foto_firma'],
    );
  }
}
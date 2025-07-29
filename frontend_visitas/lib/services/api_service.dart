// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

// Importa todos tus modelos y el config
import 'package:frontend_visitas/config.dart';
import 'package:frontend_visitas/models/visita.dart';
import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/sede.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();

  // --- MÉTODOS AUXILIARES ---
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<int?> getUsuarioId() async {
    final token = await getToken();
    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      print('🎯 Decoded Token: $decodedToken'); // Debug del token
      return decodedToken['id'];
    }
    return null;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // --- AUTENTICACIÓN ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'correo': email, 'contrasena': password}),
    );

    print('🔐 RESPUESTA LOGIN STATUS: ${response.statusCode}');
    print('🔐 RESPUESTA LOGIN BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (!data.containsKey('access_token') || data['access_token'] == null) {
        throw Exception('❌ No se recibió access_token del backend');
      }

      await _storage.write(key: 'jwt_token', value: data['access_token']);
      print('✅ TOKEN GUARDADO: ${data['access_token']}');

      return data;
    } else {
      throw Exception('Error al iniciar sesión: ${response.body}');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  // --- OBTENER DATOS (VISITAS, SEDES, MUNICIPIOS) ---
  Future<List<Visita>> getMisVisitas() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/visitas/mis-visitas'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Visita.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar las visitas. Código: ${response.statusCode}');
    }
  }

  Future<List<Visita>> getMisVisitasPendientes() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/visitas/mis-visitas?estado=pendiente'), 
      headers: headers
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Visita.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar visitas pendientes');
    }
  }

  Future<List<Municipio>> getMunicipios() async {
  final headers = await _getHeaders();
  print('🔗 Solicitando municipios a: $baseUrl/municipios');
  print('🔑 Headers: $headers');
  
  final response = await http.get(
    Uri.parse('$baseUrl/municipios'), 
    headers: headers
  );

  print('📌 Respuesta de municipios - Status: ${response.statusCode}');
  print('📌 Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Municipio.fromJson(json)).toList();
      } catch (e) {
        throw Exception('Error al procesar municipios: $e');
      }
    } else {
      throw Exception('Error al cargar municipios. Código: ${response.statusCode}');
    }
  }

  FFuture<List<Sede>> getSedesPorMunicipio(int municipioId) async {
  final headers = await _getHeaders();
  final response = await http.get(
    Uri.parse('$baseUrl/api/sedes_por_municipio/$municipioId'),
    headers: headers,
  );

  print('📌 Sedes por municipio ($municipioId) - Status: ${response.statusCode}');
  print('📌 Body: ${response.body}');

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Sede.fromJson(json)).toList();
  } else {
    throw Exception('Error al cargar sedes. Código: ${response.statusCode}');
  }

  Future<List<Institucion>> getInstituciones() async {
  final headers = await _getHeaders();
  print('🔗 Solicitando instituciones a: $baseUrl/api/instituciones');
  print('🔑 Headers: $headers');

  final response = await http.get(
    Uri.parse('$baseUrl/api/instituciones'),
    headers: headers,
  );

  print('📌 Respuesta de instituciones - Status: ${response.statusCode}');
  print('📌 Body: ${response.body}');

  if (response.statusCode == 200) {
    try {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Institucion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al procesar instituciones: $e');
    }
  } else {
    throw Exception('Error al cargar instituciones. Código: ${response.statusCode}');
  }
}

}

  // --- CREAR VISITAS ---
  Future<bool> crearVisita({
    required int sedeId,
    required String tipoAsunto,
    required String observaciones,
    required double lat,
    required double lon,
    required String prioridad,
    required String hora,
    File? fotoEvidencia,
    File? video,
    File? audio,
    File? pdf,
    File? firma,
  }) async {
    final token = await getToken();
    final usuarioId = await getUsuarioId();
    if (usuarioId == null) throw Exception('No se pudo obtener el ID del usuario.');

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/visitas'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields.addAll({
      'sede_id': sedeId.toString(),
      'usuario_id': usuarioId.toString(),
      'tipo_asunto': tipoAsunto,
      'observaciones': observaciones,
      'lat': lat.toString(),
      'lon': lon.toString(),
      'prioridad': prioridad,
      'hora': hora,
    });

    if (fotoEvidencia != null) {
      request.files.add(await http.MultipartFile.fromPath('foto_evidencia', fotoEvidencia.path));
    }
    if (firma != null) {
      request.files.add(await http.MultipartFile.fromPath('foto_firma', firma.path));
    }

    final response = await request.send();
    if (response.statusCode == 201) {
      return true;
    } else {
      final respStr = await response.stream.bytesToString();
      throw Exception('Error al crear visita: $respStr');
    }
  }

  Future<List<Visita>> getMisVisitasPorEstado(String estado) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/visitas/mis-visitas?estado=$estado'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Visita.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar visitas por estado. Código: ${response.statusCode}');
    }
  }
}
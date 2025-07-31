import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

// Importa tus modelos y configuración
import 'package:frontend_visitas/config.dart';
import 'package:frontend_visitas/models/visita.dart';
import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/sede.dart';
import 'package:frontend_visitas/models/institucion.dart';

import 'package:frontend_visitas/models/evaluacion_item.dart';
import 'package:frontend_visitas/models/item_pae.dart';
import 'package:frontend_visitas/models/checklist_categoria.dart';
import 'package:frontend_visitas/models/checklist_item.dart';
import 'package:frontend_visitas/models/visita_respuesta.dart';

class ApiService {
  // --- MÉTODOS AUXILIARES ---
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<int?> getUsuarioId() async {
    final token = await getToken();
    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      return decodedToken['id'];
    }
    return null;
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && !JwtDecoder.isExpired(token);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    if (token == null) {
      // En lugar de lanzar una excepción, devolvemos headers sin token
      // para que la aplicación pueda manejar la respuesta del servidor
      return {
        'Content-Type': 'application/json; charset=UTF-8',
      };
    }
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

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['access_token']);
      return data;
    } else {
      throw Exception('Error al iniciar sesión: ${response.body}');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('rol');
  }

  // --- OBTENER DATOS ---
  Future<List<Visita>> getMisVisitas() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/api/visitas/mis-visitas'), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Visita.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar visitas');
    }
  }

  Future<List<Visita>> getMisVisitasPorEstado(String estado) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/api/visitas/mis-visitas?estado=$estado'), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Visita.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar visitas por estado');
    }
  }

  Future<List<Municipio>> getMunicipios() async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/api/municipios';
      print('🔗 Solicitando municipios a: $url');
      print('🔑 Headers: $headers');
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      print('📌 Respuesta de municipios - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📊 Datos parseados: $data');
        
        final municipios = data.map((json) {
          print('🏛️ Procesando municipio: $json');
          return Municipio.fromJson(json);
        }).toList();
        
        print('✅ Municipios procesados: ${municipios.length}');
        return municipios;
      } else {
        throw Exception('Error al cargar municipios. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getMunicipios: $e');
      throw Exception('Error al cargar municipios: $e');
    }
  }

  Future<List<Institucion>> getInstituciones() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/api/instituciones'), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Institucion.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar instituciones');
    }
  }

  Future<List<Institucion>> getInstitucionesPorMunicipio(int municipioId) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/api/instituciones_por_municipio/$municipioId';
      print('🔗 Solicitando instituciones a: $url');
      print('🔑 Headers: $headers');
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      print('📌 Respuesta de instituciones - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📊 Datos parseados: $data');
        
        final instituciones = data.map((json) {
          print('🏛️ Procesando institución: $json');
          return Institucion.fromJson(json);
        }).toList();
        
        print('✅ Instituciones procesadas: ${instituciones.length}');
        return instituciones;
      } else {
        throw Exception('Error al obtener instituciones por municipio. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getInstitucionesPorMunicipio: $e');
      throw Exception('Error al obtener instituciones por municipio: $e');
    }
  }

  /// Obtiene las sedes filtradas por el ID de un municipio.
  Future<List<Sede>> getSedesPorMunicipio(int municipioId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/sedes_por_municipio/$municipioId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Sede.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar sedes por municipio. Código: ${response.statusCode}');
    }
  }

  /// Obtiene las sedes filtradas por el ID de una institución.
  Future<List<Sede>> getSedesPorInstitucion(int institucionId) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/api/sedes_por_institucion/$institucionId';
      print('🔗 Solicitando sedes a: $url');
      print('🔑 Headers: $headers');
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      print('📌 Respuesta de sedes - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📊 Datos parseados: $data');
        
        final sedes = data.map((json) {
          print('🏫 Procesando sede: $json');
          return Sede.fromJson(json);
        }).toList();
        
        print('✅ Sedes procesadas: ${sedes.length}');
        return sedes;
      } else {
        throw Exception('Error al cargar sedes por institución. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getSedesPorInstitucion: $e');
      throw Exception('Error al cargar sedes por institución: $e');
    }
  }

  // --- CREAR VISITA ---
  Future<bool> crearVisita({
    required int sedeId,
    required String tipoAsunto,
    required String observaciones,
    required double lat,
    required double lon,
    required String prioridad,
    required String hora,
    File? fotoEvidencia,
    File? firma,
  }) async {
    final token = await getToken();
    final usuarioId = await getUsuarioId();
    if (usuarioId == null) throw Exception('No se pudo obtener el ID del usuario');

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/visitas'));
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
    return response.statusCode == 201;
  }

  // --- CREAR CRONOGRAMA PAE ---
  Future<bool> crearCronogramaPAE({
    required DateTime fechaVisita,
    required String contrato,
    required String operador,
    required int municipioId,
    required int institucionId,
    required int sedeId,
    required int profesionalId,
    required String casoAtencionPrioritaria,
  }) async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        "fecha_visita": fechaVisita.toIso8601String(),
        "contrato": contrato,
        "operador": operador,
        "municipio_id": municipioId,
        "institucion_id": institucionId,
        "sede_id": sedeId,
        "profesional_id": profesionalId,
        "caso_atencion_prioritaria": casoAtencionPrioritaria,
      });

      final url = '$baseUrl/api/cronogramas_pae';
      print('🔗 Enviando cronograma a: $url');
      print('🔑 Headers: $headers');
      print('📦 Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      return response.statusCode == 201;
    } catch (e) {
      print('❌ Error en crearCronogramaPAE: $e');
      throw Exception('Error al crear cronograma PAE: $e');
    }
  }



  // --- OBTENER CHECKLIST COMPLETO ---
  Future<List<ChecklistCategoria>> getChecklist() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/checklist'),
        headers: headers,
      );

      print('🔗 Obteniendo checklist desde: $baseUrl/api/checklist');
      print('📌 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChecklistCategoria.fromJson(json)).toList();
      } else {
        // Si el endpoint no existe, usamos datos mock temporales
        print('⚠️ Endpoint /api/checklist no disponible. Usando datos mock...');
        return _getMockChecklist();
      }
    } catch (e) {
      print('❌ Error en getChecklist: $e');
      print('🔄 Usando datos mock como fallback...');
      return _getMockChecklist();
    }
  }

  /// Datos mock temporales para el checklist PAE 2025
  List<ChecklistCategoria> _getMockChecklist() {
    print('🔄 Generando datos mock del checklist PAE 2025...');
    return [
      ChecklistCategoria(
        id: 1,
        nombre: "Personal y Recursos Humanos",
        descripcion: "Evaluación del personal y recursos humanos del PAE",
        items: [
          ChecklistItem(
            id: 1,
            nombre: "Número de manipuladoras de alimentos",
            descripcion: "Verificar que el número de manipuladoras sea suficiente según la cobertura",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 1,
          ),
          ChecklistItem(
            id: 2,
            nombre: "Personal capacitado en manipulación de alimentos",
            descripcion: "Verificar que el personal tenga certificaciones vigentes",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 2,
          ),
          ChecklistItem(
            id: 3,
            nombre: "Personal con elementos de protección",
            descripcion: "Verificar uso de guantes, gorros, delantales, etc.",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 3,
          ),
        ],
      ),
      ChecklistCategoria(
        id: 2,
        nombre: "Infraestructura y Equipamiento",
        descripcion: "Evaluación de la infraestructura y equipamiento",
        items: [
          ChecklistItem(
            id: 4,
            nombre: "Comedor escolar funcional",
            descripcion: "Verificar que el comedor esté en buen estado y funcional",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 1,
          ),
          ChecklistItem(
            id: 5,
            nombre: "Cocina equipada adecuadamente",
            descripcion: "Verificar equipos de cocina en buen estado",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 2,
          ),
          ChecklistItem(
            id: 6,
            nombre: "Capacidad del comedor",
            descripcion: "Evaluar si el comedor puede atender a todos los estudiantes",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 3,
          ),
        ],
      ),
      ChecklistCategoria(
        id: 3,
        nombre: "Gestión y Administración",
        descripcion: "Evaluación de la gestión y administración del programa",
        items: [
          ChecklistItem(
            id: 7,
            nombre: "Registros de asistencia actualizados",
            descripcion: "Verificar que se mantengan registros de asistencia diaria",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 1,
          ),
          ChecklistItem(
            id: 8,
            nombre: "Cumplimiento del horario establecido",
            descripcion: "Verificar que se respete el horario de distribución",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 2,
          ),
          ChecklistItem(
            id: 9,
            nombre: "Documentación del programa",
            descripcion: "Verificar que exista documentación del programa PAE",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 3,
          ),
        ],
      ),
      ChecklistCategoria(
        id: 4,
        nombre: "Calidad y Nutrición",
        descripcion: "Evaluación de la calidad nutricional",
        items: [
          ChecklistItem(
            id: 10,
            nombre: "Cumplimiento de estándares nutricionales",
            descripcion: "Verificar que los alimentos cumplan estándares nutricionales",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 1,
          ),
          ChecklistItem(
            id: 11,
            nombre: "Respeto de porciones establecidas",
            descripcion: "Verificar que se distribuyan las porciones correctas",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 2,
          ),
          ChecklistItem(
            id: 12,
            nombre: "Estado de los alimentos",
            descripcion: "Verificar la frescura y calidad de los alimentos",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 3,
          ),
        ],
      ),
      ChecklistCategoria(
        id: 5,
        nombre: "Higiene y Sanitización",
        descripcion: "Evaluación de la higiene y sanitización",
        items: [
          ChecklistItem(
            id: 13,
            nombre: "Limpieza del comedor",
            descripcion: "Verificar que el comedor se mantenga limpio",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 1,
          ),
          ChecklistItem(
            id: 14,
            nombre: "Sanitización de utensilios",
            descripcion: "Verificar que los utensilios se saniticen correctamente",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 2,
          ),
          ChecklistItem(
            id: 15,
            nombre: "Disposición de residuos",
            descripcion: "Verificar que los residuos se dispongan adecuadamente",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 3,
          ),
        ],
      ),
      ChecklistCategoria(
        id: 6,
        nombre: "Cobertura y Logística",
        descripcion: "Evaluación de la cobertura y logística",
        items: [
          ChecklistItem(
            id: 16,
            nombre: "Cobertura del programa",
            descripcion: "Verificar que se atienda a todos los estudiantes elegibles",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 1,
          ),
          ChecklistItem(
            id: 17,
            nombre: "Almacenamiento de alimentos",
            descripcion: "Verificar condiciones adecuadas de almacenamiento",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 2,
          ),
          ChecklistItem(
            id: 18,
            nombre: "Transporte de alimentos",
            descripcion: "Verificar que el transporte sea adecuado y seguro",
            tipo: "opciones",
            opciones: ["✅ Cumple", "✔️ Cumple Parcialmente", "❌ No Cumple", "N/A", "N/O"],
            requerido: true,
            orden: 3,
          ),
        ],
      ),
    ];
  }

  // --- OBTENER ÍTEMS PAE 2025 ---
  Future<List<ItemPAE>> getItemsPAE() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/items-pae'),
        headers: headers,
      );

      print('🔗 Obteniendo ítems PAE desde: $baseUrl/api/items-pae');
      print('📌 Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ItemPAE.fromJson(json)).toList();
      } else {
        // Si el endpoint no existe, usamos datos mock temporales
        print('⚠️ Endpoint /api/items-pae no disponible. Usando datos mock...');
        return _getMockItemsPAE();
      }
    } catch (e) {
      print('❌ Error en getItemsPAE: $e');
      print('🔄 Usando datos mock como fallback...');
      return _getMockItemsPAE();
    }
  }

  /// Datos mock temporales para los ítems PAE 2025
  List<ItemPAE> _getMockItemsPAE() {
    print('🔄 Generando datos mock de ítems PAE 2025...');
    return [
      ItemPAE(
        id: 1,
        nombre: "Número de manipuladoras de alimentos",
        descripcion: "Verificar que el número de manipuladoras sea suficiente según la cobertura",
        categoria: "Personal y Recursos Humanos",
        orden: 1,
        activo: true,
      ),
      ItemPAE(
        id: 2,
        nombre: "Personal capacitado en manipulación de alimentos",
        descripcion: "Verificar que el personal tenga certificaciones vigentes",
        categoria: "Personal y Recursos Humanos",
        orden: 2,
        activo: true,
      ),
      ItemPAE(
        id: 3,
        nombre: "Personal con elementos de protección",
        descripcion: "Verificar uso de guantes, gorros, delantales, etc.",
        categoria: "Personal y Recursos Humanos",
        orden: 3,
        activo: true,
      ),
      ItemPAE(
        id: 4,
        nombre: "Comedor escolar funcional",
        descripcion: "Verificar que el comedor esté en buen estado y funcional",
        categoria: "Infraestructura y Equipamiento",
        orden: 1,
        activo: true,
      ),
      ItemPAE(
        id: 5,
        nombre: "Cocina equipada adecuadamente",
        descripcion: "Verificar equipos de cocina en buen estado",
        categoria: "Infraestructura y Equipamiento",
        orden: 2,
        activo: true,
      ),
      ItemPAE(
        id: 6,
        nombre: "Capacidad del comedor",
        descripcion: "Evaluar si el comedor puede atender a todos los estudiantes",
        categoria: "Infraestructura y Equipamiento",
        orden: 3,
        activo: true,
      ),
      ItemPAE(
        id: 7,
        nombre: "Registros de asistencia actualizados",
        descripcion: "Verificar que se mantengan registros de asistencia diaria",
        categoria: "Gestión y Administración",
        orden: 1,
        activo: true,
      ),
      ItemPAE(
        id: 8,
        nombre: "Cumplimiento del horario establecido",
        descripcion: "Verificar que se respete el horario de distribución",
        categoria: "Gestión y Administración",
        orden: 2,
        activo: true,
      ),
      ItemPAE(
        id: 9,
        nombre: "Documentación del programa",
        descripcion: "Verificar que exista documentación del programa PAE",
        categoria: "Gestión y Administración",
        orden: 3,
        activo: true,
      ),
      ItemPAE(
        id: 10,
        nombre: "Cumplimiento de estándares nutricionales",
        descripcion: "Verificar que los alimentos cumplan estándares nutricionales",
        categoria: "Calidad y Nutrición",
        orden: 1,
        activo: true,
      ),
      ItemPAE(
        id: 11,
        nombre: "Respeto de porciones establecidas",
        descripcion: "Verificar que se distribuyan las porciones correctas",
        categoria: "Calidad y Nutrición",
        orden: 2,
        activo: true,
      ),
      ItemPAE(
        id: 12,
        nombre: "Estado de los alimentos",
        descripcion: "Verificar la frescura y calidad de los alimentos",
        categoria: "Calidad y Nutrición",
        orden: 3,
        activo: true,
      ),
      ItemPAE(
        id: 13,
        nombre: "Limpieza del comedor",
        descripcion: "Verificar que el comedor se mantenga limpio",
        categoria: "Higiene y Sanitización",
        orden: 1,
        activo: true,
      ),
      ItemPAE(
        id: 14,
        nombre: "Sanitización de utensilios",
        descripcion: "Verificar que los utensilios se saniticen correctamente",
        categoria: "Higiene y Sanitización",
        orden: 2,
        activo: true,
      ),
      ItemPAE(
        id: 15,
        nombre: "Disposición de residuos",
        descripcion: "Verificar que los residuos se dispongan adecuadamente",
        categoria: "Higiene y Sanitización",
        orden: 3,
        activo: true,
      ),
      ItemPAE(
        id: 16,
        nombre: "Cobertura del programa",
        descripcion: "Verificar que se atienda a todos los estudiantes elegibles",
        categoria: "Cobertura y Logística",
        orden: 1,
        activo: true,
      ),
      ItemPAE(
        id: 17,
        nombre: "Almacenamiento de alimentos",
        descripcion: "Verificar condiciones adecuadas de almacenamiento",
        categoria: "Cobertura y Logística",
        orden: 2,
        activo: true,
      ),
      ItemPAE(
        id: 18,
        nombre: "Transporte de alimentos",
        descripcion: "Verificar que el transporte sea adecuado y seguro",
        categoria: "Cobertura y Logística",
        orden: 3,
        activo: true,
      ),
    ];
  }

  // --- GUARDAR VISITA CON CHECKLIST ---
  Future<bool> guardarVisitaConChecklist({
    required DateTime fechaVisita,
    required String contrato,
    required String operador,
    required int municipioId,
    required int institucionId,
    required int sedeId,
    required int profesionalId,
    required List<VisitaRespuesta> respuestas,
  }) async {
    try {
      final headers = await _getHeaders();
      final data = {
        'fecha_visita': fechaVisita.toIso8601String(),
        'contrato': contrato,
        'operador': operador,
        'municipio_id': municipioId,
        'institucion_id': institucionId,
        'sede_id': sedeId,
        'profesional_id': profesionalId,
        'respuestas': respuestas.map((r) => r.toJson()).toList(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/visitas'),
        headers: headers,
        body: jsonEncode(data),
      );

      print('🔗 Guardando visita con checklist en: $baseUrl/api/visitas');
      print('📌 Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Visita con checklist guardada exitosamente');
        return true;
      } else {
        print('❌ Error al guardar visita con checklist: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error en guardarVisitaConChecklist: $e');
      return false;
    }
  }

  // --- GUARDAR VISITA CON EVALUACIONES PAE ---
  Future<bool> guardarVisitaConEvaluacionesPAE({
    required DateTime fechaVisita,
    required String contrato,
    required String operador,
    required int municipioId,
    required int institucionId,
    required int sedeId,
    required int profesionalId,
    required List<EvaluacionItem> evaluaciones,
  }) async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        "fecha_visita": fechaVisita.toIso8601String(),
        "contrato": contrato,
        "operador": operador,
        "municipio_id": municipioId,
        "institucion_id": institucionId,
        "sede_id": sedeId,
        "profesional_id": profesionalId,
        "evaluaciones": evaluaciones.map((e) => e.toJson()).toList(),
      });

      final url = '$baseUrl/api/visitas-pae';
      print('🔗 Enviando visita PAE a: $url');
      print('🔑 Headers: $headers');
      print('📦 Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('📌 Respuesta del servidor - Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      return response.statusCode == 201;
    } catch (e) {
      print('❌ Error en guardarVisitaConEvaluacionesPAE: $e');
      throw Exception('Error al guardar visita PAE: $e');
    }
  }

  // --- OBTENER EVALUACIONES DE UNA VISITA ---
  Future<List<EvaluacionItem>> getEvaluacionesVisita(int visitaId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/visitas/$visitaId/evaluaciones'),
        headers: headers,
      );

      print('🔗 Obteniendo evaluaciones de visita $visitaId');
      print('📌 Status: ${response.statusCode}');
      print('📌 Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => EvaluacionItem.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener evaluaciones de la visita');
      }
    } catch (e) {
      print('❌ Error en getEvaluacionesVisita: $e');
      throw Exception('Error al obtener evaluaciones de la visita: $e');
    }
  }

  // --- DASHBOARD DEL VISITADOR ---
  Future<Map<String, dynamic>> getEstadisticasVisitador() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/dashboard/estadisticas'),
        headers: headers,
      );

      print('🔗 Obteniendo estadísticas desde: $baseUrl/api/dashboard/estadisticas');
      print('📌 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al cargar estadísticas. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getEstadisticasVisitador: $e');
      throw Exception('Error al cargar estadísticas: $e');
    }
  }

  // --- PERFIL DE USUARIO ---
  Future<Map<String, dynamic>> getPerfilUsuario() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/perfil'),
        headers: headers,
      );

      print('🔗 Obteniendo perfil desde: $baseUrl/api/perfil');
      print('📌 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al cargar perfil. Código: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getPerfilUsuario: $e');
      throw Exception('Error al cargar perfil: $e');
    }
  }
}

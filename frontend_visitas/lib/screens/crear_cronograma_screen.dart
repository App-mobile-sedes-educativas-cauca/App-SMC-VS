import 'package:flutter/material.dart';
import 'dart:convert'; // Necesario para jsonEncode

// --- Dependencias que debes tener en pubspec.yaml ---
import 'package:connectivity_plus/connectivity_plus.dart';

// --- Archivos de tu proyecto ---
import 'package:frontend_visitas/models/municipio.dart';
import 'package:frontend_visitas/models/institucion.dart';
import 'package:frontend_visitas/models/sede.dart';
import 'package:frontend_visitas/models/visita.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/local/db_helper.dart';


class CrearCronogramaScreen extends StatefulWidget {
  final dynamic? visitaExistente; // Visita completa PAE existente para editar
  
  const CrearCronogramaScreen({
    super.key,
    this.visitaExistente,
  });

  @override
  State<CrearCronogramaScreen> createState() => _CrearCronogramaScreenState();
}

class _CrearCronogramaScreenState extends State<CrearCronogramaScreen> {
  int _currentStep = 0;

  // Claves y Controladores
  final _formKey = GlobalKey<FormState>();

  // --- Estado del Formulario ---
  DateTime? _fechaVisita;
  String _contrato = '';
  String _operador = '';
  int? _municipioId;
  int? _institucionId;
  int? _sedeId;
  int? _profesionalId; // ID del usuario logueado
  String? _casoAtencionPrioritaria; // Campo separado para CASO DE ATENCIÓN PRIORITARIA

  // --- Variables para el Checklist ---
  List<dynamic>? _checklist;
  Map<int, String> _respuestasChecklist = {};



  @override
  void initState() {
    super.initState();
    // Verificamos autenticación y obtenemos el ID del usuario
    _verificarAutenticacion();
    // Cargamos el checklist
    _cargarChecklist();
    // Si hay una visita existente, cargamos sus datos
    if (widget.visitaExistente != null) {
      _cargarDatosVisitaExistente();
    }
  }

  /// Carga los datos de una visita existente
  void _cargarDatosVisitaExistente() {
    final visita = widget.visitaExistente!;
    setState(() {
      _fechaVisita = DateTime.parse(visita['fecha_visita']);
      _contrato = visita['contrato'] ?? '';
      _operador = visita['operador'] ?? '';
      _municipioId = visita['municipio_id'];
      _institucionId = visita['institucion_id'];
      _sedeId = visita['sede_id'];
      _profesionalId = visita['profesional_id'];
      _casoAtencionPrioritaria = visita['caso_atencion_prioritaria'];
      
      // Cargar respuestas del checklist si existen
      if (visita['respuestas_checklist'] != null) {
        final respuestas = visita['respuestas_checklist'] as List;
        for (var respuesta in respuestas) {
          _respuestasChecklist[respuesta['item_id']] = respuesta['respuesta'];
        }
      }
    });
  }

  void _verificarAutenticacion() async {
    final apiService = ApiService();
    final isAuth = await apiService.isAuthenticated();
    
    if (!isAuth) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión expirada. Por favor, inicie sesión nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
    }
    
    // Si está autenticado, obtenemos el ID del usuario
    _setProfesionalId();
  }

  /// Obtiene y establece el ID del profesional/usuario logueado.
  void _setProfesionalId() async {
    // Simulación, reemplaza con tu lógica real para obtener el ID del usuario
    final id = await ApiService().getUsuarioId();
    if (mounted) {
      setState(() {
        _profesionalId = id;
      });
    }
  }

  /// Carga el checklist desde el servidor.
  void _cargarChecklist() async {
    try {
      final checklist = await ApiService().getChecklist();
      if (mounted) {
        setState(() {
          _checklist = checklist;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar checklist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronograma PAE 2025'),
        centerTitle: true,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        steps: _buildSteps(),
        controlsBuilder: (context, details) {
           return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep == _buildSteps().length - 1 ? 'GUARDAR VISITA' : 'SIGUIENTE'),
                ),
                if (_currentStep != 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('ANTERIOR'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Métodos del Stepper ---

  /// Construye la lista de pasos para el Stepper.
  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Datos del Cronograma'),
        content: _buildStep1(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Ubicación'),
        content: _buildStep2(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Caso de Atención Prioritaria'),
        content: _buildStep3(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Checklist PAE'),
        content: _buildStep4(),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Finalizar'),
        content: const Center(child: Text('Revise los datos. Presione "GUARDAR VISITA" para finalizar.')),
        isActive: _currentStep >= 4,
      ),
    ];
  }

  /// Avanza al siguiente paso o envía el formulario.
  void _nextStep() {
    // Valida el formulario del primer paso antes de continuar
    if (_currentStep == 0 && !_formKey.currentState!.validate()) return;
    
    // Si no es el último paso, avanza. Si es el último, llama a guardar.
    if (_currentStep < _buildSteps().length - 1) {
      setState(() => _currentStep += 1);
    } else {
      _submitFormulario();
    }
  }

  /// Retrocede al paso anterior.
  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }



  // --- Widgets para cada Step ---

  /// Contenido del Step 1: Datos Generales.
  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Contrato', border: OutlineInputBorder()),
            onChanged: (value) => _contrato = value,
            validator: (value) => value!.isEmpty ? 'El contrato es requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Operador', border: OutlineInputBorder()),
            onChanged: (value) => _operador = value,
            validator: (value) => value!.isEmpty ? 'El operador es requerido' : null,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(_fechaVisita == null
                ? 'Seleccionar fecha de visita'
                : 'Fecha: ${_fechaVisita!.toLocal().toString().split(' ')[0]}'),
            onPressed: _pickFechaVisita,
          ),
        ],
      ),
    );
  }

  /// Contenido del Step 2: Ubicación.
  Widget _buildStep2() {
    return Column(
      children: [
        FutureBuilder<List<Municipio>>(
          future: ApiService().getMunicipios(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text('Error al cargar municipios: ${snapshot.error}'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() {}), // Refrescar
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay municipios disponibles'));
            }
            return DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Municipio', border: OutlineInputBorder()),
              value: _municipioId,
              items: snapshot.data!.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nombre))).toList(),
              onChanged: (value) => setState(() {
                _municipioId = value; _institucionId = null; _sedeId = null;
              }),
            );
          },
        ),
        const SizedBox(height: 12),
        if (_municipioId != null)
          FutureBuilder<List<Institucion>>(
            future: ApiService().getInstitucionesPorMunicipio(_municipioId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 32),
                      const SizedBox(height: 4),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No hay instituciones en este municipio'));
              }
              return DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Institución Educativa', border: OutlineInputBorder()),
                value: _institucionId,
                items: snapshot.data!.map((i) => DropdownMenuItem(value: i.id, child: Text(i.nombre))).toList(),
                onChanged: (value) => setState(() => _institucionId = value),
              );
            },
          ),
        const SizedBox(height: 12),
        if (_institucionId != null)
          FutureBuilder<List<Sede>>(
            future: ApiService().getSedesPorInstitucion(_institucionId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 32),
                      const SizedBox(height: 4),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No hay sedes en esta institución'));
              }
              return DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Sede Educativa', border: OutlineInputBorder()),
                value: _sedeId,
                items: snapshot.data!.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nombreSede))).toList(),
                onChanged: (value) => setState(() => _sedeId = value),
              );
            },
          ),
      ],
    );
  }

    /// Contenido del Step 3: Caso de Atención Prioritaria.
  Widget _buildStep3() {
    return Column(
      children: [
        const Text(
          'CASO DE ATENCIÓN PRIORITARIA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Seleccione una opción',
            border: OutlineInputBorder(),
            hintText: 'Seleccione el caso de atención prioritaria',
          ),
          value: _casoAtencionPrioritaria,
          items: const [
            DropdownMenuItem(value: "SI", child: Text("SI")),
            DropdownMenuItem(value: "NO", child: Text("NO")),
            DropdownMenuItem(value: "NO HUBO SERVICIO", child: Text("NO HUBO SERVICIO")),
            DropdownMenuItem(value: "ACTA RAPIDA", child: Text("ACTA RAPIDA")),
          ],
          onChanged: (value) {
            setState(() {
              _casoAtencionPrioritaria = value;
            });
          },
        ),
      ],
    );
  }

  /// Contenido del Step 4: Checklist PAE.
  Widget _buildStep4() {
    if (_checklist == null) {
      return const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando checklist...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHECKLIST PAE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          ..._checklist!.map((categoria) => _buildCategoriaChecklist(categoria)),
        ],
      ),
    );
  }

  /// Construye una categoría del checklist.
  Widget _buildCategoriaChecklist(dynamic categoria) {
    // Verificar que la categoría y sus propiedades no sean null
    if (categoria == null) return const SizedBox.shrink();
    
    final nombre = categoria['nombre'] ?? categoria.nombre ?? 'Sin nombre';
    final items = categoria['items'] ?? categoria.items ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          nombre.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: (items as List).map((item) => _buildItemChecklist(item)).toList(),
      ),
    );
  }

  /// Construye un item del checklist.
  Widget _buildItemChecklist(dynamic item) {
    // Verificar que el item y sus propiedades no sean null
    if (item == null) return const SizedBox.shrink();
    
    final pregunta = item['pregunta_texto'] ?? item.pregunta_texto ?? 'Sin pregunta';
    final id = item['id'] ?? item.id ?? 0;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pregunta.toString(),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Respuesta',
              border: OutlineInputBorder(),
            ),
            value: _respuestasChecklist[id],
            items: const [
              DropdownMenuItem(value: "Cumple", child: Text("✅ Cumple")),
              DropdownMenuItem(value: "Cumple Parcialmente", child: Text("✔️ Cumple Parcialmente")),
              DropdownMenuItem(value: "No Cumple", child: Text("❌ No Cumple")),
              DropdownMenuItem(value: "N/A", child: Text("N/A")),
              DropdownMenuItem(value: "N/O", child: Text("N/O")),
            ],
            onChanged: (value) {
              setState(() {
                _respuestasChecklist[id] = value ?? '';
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Debe seleccionar una respuesta';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// Abre el selector de fecha.
  void _pickFechaVisita() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaVisita ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null && mounted) {
      setState(() => _fechaVisita = picked);
    }
  }

  /// Muestra un mensaje de error en un SnackBar.
  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  /// Valida que todos los campos necesarios estén completos.
  bool _validarCampos() {
    if (_fechaVisita == null) {
      _mostrarError('Debes seleccionar una fecha de visita.');
      return false;
    }
    if (_municipioId == null || _institucionId == null || _sedeId == null) {
      _mostrarError('Debes seleccionar la ubicación completa (Municipio, Institución y Sede).');
      return false;
    }
    if (_casoAtencionPrioritaria == null) {
      _mostrarError('Debes seleccionar el caso de atención prioritaria.');
      return false;
    }
    if (_profesionalId == null) {
      _mostrarError('No se pudo identificar al usuario. Intenta reiniciar sesión.');
      return false;
    }
    
    // Validar que el checklist esté cargado
    if (_checklist == null) {
      _mostrarError('El checklist aún se está cargando. Por favor, espera un momento.');
      return false;
    }
    
    // Validar que al menos un item del checklist tenga respuesta
    if (_respuestasChecklist.isEmpty) {
      _mostrarError('Debes completar al menos un item del checklist.');
      return false;
    }
    
    return true;
  }

  // =======================================================================
  // ✅ FASE 2: LÓGICA DE GUARDADO (ONLINE/OFFLINE)
  // =======================================================================
  void _submitFormulario() async {
    // Primero, validar que los campos principales estén llenos.
    if (!_formKey.currentState!.validate() || !_validarCampos()) {
      return;
    }

    // Preparamos el paquete de datos para enviar o guardar.
    final data = {
      "fecha_visita": _fechaVisita!.toIso8601String(),
      "contrato": _contrato,
      "operador": _operador,
      "sede_id": _sedeId,
      "usuario_id": _profesionalId,
      "caso_atencion_prioritaria": _casoAtencionPrioritaria,
    };

    // Verificamos el estado de la conectividad.
    final connectivityResult = await Connectivity().checkConnectivity();

    // Si NO hay conexión a internet (WiFi o Datos Móviles)
    if (connectivityResult == ConnectivityResult.none) {
      print("🔌 Sin conexión. Guardando localmente...");
      await LocalDB.guardarVisitaLocal(jsonEncode(data));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Visita guardada localmente. Se sincronizará después.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Si HAY conexión, intentamos enviar al servidor.
      try {
        print("☁️ Conexión detectada. Enviando al servidor...");
        print("📋 Respuestas del checklist a enviar: $_respuestasChecklist");
        await ApiService().crearVisitaCompletaPAE(
          fechaVisita: _fechaVisita!,
          contrato: _contrato,
          operador: _operador,
          municipioId: _municipioId!,
          institucionId: _institucionId!,
          sedeId: _sedeId!,
          profesionalId: _profesionalId!,
          casoAtencionPrioritaria: _casoAtencionPrioritaria!,
          respuestasChecklist: _respuestasChecklist,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚀 Visita enviada al servidor con éxito.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Si el envío al servidor falla (error de red, servidor caído, etc.)
        print("⚠️ Error al enviar al servidor. Guardando localmente como respaldo...");
        await LocalDB.guardarVisitaLocal(jsonEncode(data));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al enviar. Se guardó localmente para intentarlo después.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }

    // Al finalizar, sin importar el resultado, cerramos la pantalla del formulario.
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
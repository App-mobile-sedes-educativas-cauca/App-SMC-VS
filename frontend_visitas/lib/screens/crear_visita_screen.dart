import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/municipio.dart';
import '../models/sede.dart';

class CrearVisitaScreen extends StatefulWidget {
  const CrearVisitaScreen({super.key});

  @override
  State<CrearVisitaScreen> createState() => _CrearVisitaScreenState();
}

class _CrearVisitaScreenState extends State<CrearVisitaScreen> {
  final ApiService _apiService = ApiService();

  List<Municipio> _municipios = [];
  List<Sede> _sedes = [];
  int? _municipioSeleccionado;
  int? _sedeSeleccionada;
  String? _tipoAsunto;
  String? _observaciones;
  String? _prioridad;
  TimeOfDay? _horaSeleccionada;

  File? _foto;
  File? _video;
  File? _audio;
  File? _pdf;
  File? _firma;

  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarMunicipios();
  }

  Future<void> _cargarMunicipios() async {
    try {
      final municipios = await _apiService.getMunicipios();
      setState(() => _municipios = municipios);
    } catch (e) {
      _mostrarError('Error al cargar municipios: $e');
    }
  }

  Future<void> _cargarSedesPorMunicipio(int municipioId) async {
    try {
      final sedes = await _apiService.getSedesPorMunicipio(municipioId);
      setState(() => _sedes = sedes);
    } catch (e) {
      _mostrarError('Error al cargar sedes: $e');
    }
  }

  Future<void> _seleccionarArchivo(ImageSource source, Function(File) onFilePicked) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) onFilePicked(File(pickedFile.path));
  }

  Future<void> _seleccionarHora() async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (hora != null) setState(() => _horaSeleccionada = hora);
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  Future<void> _enviarFormulario() async {
    if (_sedeSeleccionada == null || _tipoAsunto == null || _prioridad == null) {
      _mostrarError("Completa todos los campos obligatorios");
      return;
    }

    setState(() => _cargando = true);

    try {
      final enviado = await _apiService.crearVisita(
        sedeId: _sedeSeleccionada!,
        tipoAsunto: _tipoAsunto!,
        observaciones: _observaciones ?? '',
        lat: 2.45, // Suplente temporal
        lon: -76.6, // Suplente temporal
        hora: _horaSeleccionada?.format(context) ?? '',
        prioridad: _prioridad!,
        fotoEvidencia: _foto,
        video: _video,
        audio: _audio,
        pdf: _pdf,
        firma: _firma,
      );

      if (enviado) {
        Navigator.pop(context);
      } else {
        _mostrarError("No se pudo enviar la visita.");
      }
    } catch (e) {
      _mostrarError("Error al enviar: $e");
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Iniciar nueva visita")),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                DropdownButtonFormField<int>(
                  value: _municipioSeleccionado,
                  items: _municipios.map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(m.nombre),
                  )).toList(),
                  onChanged: (id) {
                    setState(() {
                      _municipioSeleccionado = id;
                      _sedeSeleccionada = null;
                      _sedes.clear();
                    });
                    if (id != null) _cargarSedesPorMunicipio(id);
                  },
                  decoration: const InputDecoration(labelText: "Municipio"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: _sedeSeleccionada,
                  items: _sedes.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.nombreSede),
                  )).toList(),
                  onChanged: (id) => setState(() => _sedeSeleccionada = id),
                  decoration: const InputDecoration(labelText: "Sede educativa"),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Tipo de asunto"),
                  onChanged: (v) => _tipoAsunto = v,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Observaciones"),
                  onChanged: (v) => _observaciones = v,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
  value: _prioridad,
  items: ['Alta', 'Media', 'Baja'].map((nivel) => DropdownMenuItem<String>(
    value: nivel,
    child: Text(nivel),
  )).toList(),
  onChanged: (v) => setState(() => _prioridad = v),
  decoration: const InputDecoration(labelText: "Nivel de prioridad"),
),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(_horaSeleccionada == null
                        ? "Hora no seleccionada"
                        : "Hora: ${_horaSeleccionada!.format(context)}"),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _seleccionarHora,
                      child: const Text("Seleccionar hora"),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _archivoBoton("Foto", () => _seleccionarArchivo(ImageSource.camera, (f) => setState(() => _foto = f))),
                  _archivoBoton("Firma", () => _seleccionarArchivo(ImageSource.camera, (f) => setState(() => _firma = f))),
                  _archivoBoton("Video", () => _seleccionarArchivo(ImageSource.gallery, (f) => setState(() => _video = f))),
                  _archivoBoton("Audio", () => _seleccionarArchivo(ImageSource.gallery, (f) => setState(() => _audio = f))),
                  _archivoBoton("PDF", () => _seleccionarArchivo(ImageSource.gallery, (f) => setState(() => _pdf = f))),
                ]),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  onPressed: _enviarFormulario,
                  label: const Text("Enviar visita"),
                )
              ]),
            ),
    );
  }

  Widget _archivoBoton(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      child: Text(label),
    );
  }
}
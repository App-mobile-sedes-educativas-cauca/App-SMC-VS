import 'package:flutter/material.dart';

class CrearCronogramaScreen extends StatefulWidget {
  const CrearCronogramaScreen({super.key});

  @override
  State<CrearCronogramaScreen> createState() => _CrearCronogramaScreenState();
}

class _CrearCronogramaScreenState extends State<CrearCronogramaScreen> {
  int _currentStep = 0;

  // Controladores y variables
  final _formKey = GlobalKey<FormState>();
  DateTime? _fechaVisita;
  String _contrato = '';
  String _operador = '';
  int? _municipioId;
  int? _institucionId;
  int? _sedeId;
  int? _profesionalId;

  List<Map<String, dynamic>> evaluaciones = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cronograma PAE 2025')),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        steps: [
          Step(
            title: const Text('Datos del cronograma'),
            content: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Contrato'),
                    onChanged: (value) => _contrato = value,
                    validator: (value) =>
                        value!.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Operador'),
                    onChanged: (value) => _operador = value,
                    validator: (value) =>
                        value!.isEmpty ? 'Requerido' : null,
                  ),
                  ElevatedButton(
                    onPressed: _pickFechaVisita,
                    child: Text(_fechaVisita == null
                        ? 'Seleccionar fecha de visita'
                        : 'Fecha: ${_fechaVisita!.toLocal()}'.split(' ')[0]),
                  ),
                ],
              ),
            ),
            isActive: _currentStep == 0,
          ),
         Step(
  title: const Text('Ubicación'),
  content: Column(
    children: [
      FutureBuilder<List<Municipio>>(
        future: ApiService().getMunicipios(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          final municipios = snapshot.data!;
          return DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Municipio'),
            value: _municipioId,
            items: municipios.map((m) {
              return DropdownMenuItem(value: m.id, child: Text(m.nombre));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _municipioId = value;
                _sedeId = null; // Reset sede
              });
            },
          );
        },
      ),
      const SizedBox(height: 12),
      FutureBuilder<List<Institucion>>(
        future: ApiService().getInstituciones(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          final instituciones = snapshot.data!;
          return DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Institución educativa'),
            value: _institucionId,
            items: instituciones.map((i) {
              return DropdownMenuItem(value: i.id, child: Text(i.nombre));
            }).toList(),
            onChanged: (value) {
              setState(() => _institucionId = value);
            },
          );
        },
      ),
      const SizedBox(height: 12),
      if (_municipioId != null)
        FutureBuilder<List<Sede>>(
          future: ApiService().getSedesPorMunicipio(_municipioId!),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final sedes = snapshot.data!;
            return DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Sede educativa'),
              value: _sedeId,
              items: sedes.map((s) {
                return DropdownMenuItem(value: s.id, child: Text(s.nombre));
              }).toList(),
              onChanged: (value) {
                setState(() => _sedeId = value);
              },
            );
          },
        ),
    ],
  ),
  isActive: _currentStep == 1,
),

          Step(
            title: const Text('Evaluaciones'),
            content: Column(
              children: [
                Text('Aquí se mostrarán ítems a evaluar (checklist o selectores).'),
              ],
            ),
            isActive: _currentStep == 2,
          ),
          Step(
            title: const Text('Finalizar'),
            content: const Text('Resumen y botón para guardar.'),
            isActive: _currentStep == 3,
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0 && !_formKey.currentState!.validate()) return;

    if (_currentStep < 3) {
      setState(() => _currentStep += 1);
    } else {
      _submitFormulario();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  void _pickFechaVisita() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() => _fechaVisita = picked);
    }
  }

  void _submitFormulario() {
    // Aquí va la lógica de envío de datos al backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario enviado')),
    );
  }
}
     
import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/visita.dart'; // Importa tu modelo

class PendientesScreen extends StatefulWidget {
  const PendientesScreen({super.key});

  @override
  State<PendientesScreen> createState() => _PendientesScreenState();
}

class _PendientesScreenState extends State<PendientesScreen> {
  // Solo necesitamos una instancia del servicio
  final ApiService _apiService = ApiService();
  // El Future que contendrá los datos o el error
  late Future<List<Visita>> _futurePendientes;

  @override
  void initState() {
    super.initState();
    // Iniciamos la llamada a la API aquí
    _futurePendientes = _apiService.getMisVisitasPendientes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Visitas pendientes")),
      body: FutureBuilder<List<Visita>>(
        future: _futurePendientes,
        builder: (context, snapshot) {
          // Mientras carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Si hay un error
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // Si no hay datos
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes visitas pendientes.'));
          }

          // Si todo está bien, mostramos la lista
          final pendientes = snapshot.data!;
          return ListView.builder(
            itemCount: pendientes.length,
            itemBuilder: (context, index) {
              final v = pendientes[index];
              return ListTile(
                title: Text(v.sede.nombreSede), // Acceso a través de modelos
                subtitle: Text("Asunto: ${v.tipoAsunto}\nFecha: ${v.fechaCreacion}"),
              );
            },
          );
        },
      ),
    );
  }
}
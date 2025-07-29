import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config.dart';

class VisitadorHome extends StatefulWidget {
  const VisitadorHome({super.key});

  @override
  State<VisitadorHome> createState() => _VisitadorHomeState();
}

class _VisitadorHomeState extends State<VisitadorHome> {
  String nombre = "";
  Map<String, dynamic>? visitaReciente;

  @override
  void initState() {
    super.initState();
    verificarAutenticacion();
    cargarDatosUsuario();
    cargarUltimaVisita();
  }

  Future<void> verificarAutenticacion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombre = prefs.getString('nombre') ?? "Visitador";
    });
  }

  Future<void> cargarUltimaVisita() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/visitas/mis-visitas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final visitas = jsonDecode(response.body);
        if (visitas is List && visitas.isNotEmpty) {
          setState(() {
            visitaReciente = visitas.last;
          });
        }
      } else if (response.statusCode == 401) {
        // Token expirado o inválido
        await prefs.clear();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      debugPrint('Error al cargar última visita: $e');
    }
  }

  Widget _buildCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Container(
          width: 150,
          height: 140,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 30, color: Colors.black),
              const SizedBox(height: 8),
              Text(
                title, 
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle, 
                textAlign: TextAlign.center, 
                style: const TextStyle(fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Principal"),
        backgroundColor: const Color(0xFF008BE8),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Bienvenido, $nombre", 
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCard("Iniciar nueva visita", "Comienza un nuevo registro de visita", Icons.add, () {
                  Navigator.pushNamed(context, '/crear-visita');
                }),
                _buildCard("Mis visitas pendientes", "Accede a visitas guardadas", Icons.assignment_late, () {
                  Navigator.pushNamed(context, '/pendientes');
                }),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCard("Historial de visitas", "Revisa tus visitas completadas", Icons.history, () {
                  Navigator.pushNamed(context, '/historial');
                }),
                _buildCard("Mi perfil", "Gestiona tu información", Icons.settings, () {
                  Navigator.pushNamed(context, '/perfil');
                }),
              ],
            ),
            const SizedBox(height: 20),
            if (visitaReciente != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Actividad reciente",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Visita iniciada: ${visitaReciente!['sede']['nombre']}",
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Fecha: ${visitaReciente!['fecha']}",
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
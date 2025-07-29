import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

// Importamos los modelos y servicios que vamos a usar
// CORRECTO
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/visita.dart';
import 'package:frontend_visitas/screens/listado_visitas_estado_screen.dart';

class VisitadorDashboard extends StatefulWidget {
  const VisitadorDashboard({super.key});

  @override
  State<VisitadorDashboard> createState() => _VisitadorDashboardState();
}

class _VisitadorDashboardState extends State<VisitadorDashboard> {
  final ApiService _apiService = ApiService();

  int pendientes = 0;
  int completadas = 0;
  String nombreUsuario = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
  setState(() => isLoading = true);
  try {
    final token = await _apiService.getToken();
    if (token == null) {
      throw Exception('No hay token almacenado');
    }
    
    print('🔐 Token obtenido: $token');
    if (JwtDecoder.isExpired(token)) {
      throw Exception('Token expirado');
    }

    final decoded = JwtDecoder.decode(token);
    print('🔍 Token decodificado: $decoded');
    
    final userId = decoded['id'];
    if (userId == null) {
      throw Exception('El token no contiene ID de usuario');
    }

    final visitasPendientes = await _apiService.getMisVisitasPorEstado('pendiente');
    final visitasCompletadas = await _apiService.getMisVisitasPorEstado('completada');

    setState(() {
      nombreUsuario = "Visitador #$userId";
      pendientes = visitasPendientes.length;
      completadas = visitasCompletadas.length;
      isLoading = false;
    });
  } catch (e) {
    print("Error cargando datos: $e");
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
  }
}

  Future<void> _logout() async {
    await _apiService.logout();
    if (mounted) {
      // Navegamos al login y eliminamos todas las rutas anteriores
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Visitador"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Bienvenido, $nombreUsuario",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Resumen de visitas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildResumenCard('Pendientes', pendientes, Colors.orange),
                      _buildResumenCard('Completadas', completadas, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Aquí va tu GridView con los cards
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _DashboardCard(
                        icon: Icons.add,
                        title: 'Iniciar nueva visita',
                        onTap: () => Navigator.pushNamed(context, '/crear-visita'),
                      ),
                      _DashboardCard(
                        icon: Icons.pending_actions,
                        title: 'Mis visitas pendientes',
                        onTap: () => Navigator.pushNamed(context, '/pendientes'),
                      ),
                      _DashboardCard(
                        icon: Icons.history,
                        title: 'Historial de visitas',
                        onTap: () => Navigator.pushNamed(context, '/historial'),
                      ),
                      _DashboardCard(
                        icon: Icons.person,
                        title: 'Cronograma PAE',
                        onTap: () => Navigator.pushNamed(context, '/crear_cronograma'),
                      ),
                      _DashboardCard(
                        icon: Icons.person,
                        title: 'Mi perfil',
                        onTap: () => Navigator.pushNamed(context, '/perfil'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ...actividad reciente, etc.
                ],
              ),
            ),
    );
  }

  Widget _buildResumenCard(String titulo, int cantidad, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListadoVisitasEstadoScreen(estado: titulo.toLowerCase()),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color),
          ),
          child: Column(
            children: [
              Text(
                titulo,
                style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                cantidad.toString(),
                style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget reutilizable para las tarjetas del dashboard
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
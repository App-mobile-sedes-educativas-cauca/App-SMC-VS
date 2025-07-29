import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/pendientes_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/visitador_home.dart';
import 'screens/crear_visita_screen.dart';
import 'screens/perfil_screen.dart';
import 'package:frontend_visitas/screens/visitador_dashboard.dart' as visitador;
import 'package:frontend_visitas/screens/supervisor_dashboard.dart' as supervisor;
import 'screens/crear_cronograma_screen.dart';


void main() {
  runApp(SMCApp());
}

class SMCApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMC VS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF008BE8),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/admin_dashboard': (context) => AdminDashboard(),
        '/visitador_dashboard': (context) => visitador.VisitadorDashboard(),
        '/supervisor_dashboard': (context) => supervisor.SupervisorDashboard(),
        '/visitador': (context) => const VisitadorHome(),
         '/crear-visita': (context) => const CrearVisitaScreen(),
        '/pendientes': (context) => const PendientesScreen(),
        '/historial': (context) => const HistorialScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/crear_cronograma': (context) => CrearCronogramaScreen(),

      },
    );
  }
}
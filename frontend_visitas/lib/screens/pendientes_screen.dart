// lib/screens/pendientes_screen.dart

import 'package:flutter/material.dart';
import 'package:frontend_visitas/services/api_service.dart';
import 'package:frontend_visitas/models/visita.dart';
import 'package:frontend_visitas/screens/crear_visita_screen.dart';

class PendientesScreen extends StatefulWidget {
  const PendientesScreen({super.key});

  @override
  State<PendientesScreen> createState() => _PendientesScreenState();
}

class _PendientesScreenState extends State<PendientesScreen> {
  final ApiService _apiService = ApiService();
  List<Visita> _visitas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarVisitasPendientes();
  }

  Future<void> _cargarVisitasPendientes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final visitas = await _apiService.getMisVisitasPorEstado('pendiente');
      setState(() {
        _visitas = visitas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _seleccionarVisita(Visita visita) {
    // Navegar a la pantalla para completar la visita
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CrearVisitaScreen(),
      ),
    ).then((_) {
      // Recargar la lista cuando regrese de completar la visita
      _cargarVisitasPendientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitas Pendientes'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVisitasPendientes,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildVisitasList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error al cargar visitas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarVisitasPendientes,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitasList() {
    if (_visitas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay visitas pendientes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Excelente trabajo! Todas tus visitas están completadas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarVisitasPendientes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _visitas.length,
            itemBuilder: (context, index) {
          final visita = _visitas[index];
          return _buildVisitaCard(visita);
        },
      ),
    );
  }

  Widget _buildVisitaCard(Visita visita) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _seleccionarVisita(visita),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                                         decoration: BoxDecoration(
                       color: Colors.orange.withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(8),
                     ),
                    child: const Icon(
                      Icons.pending_actions,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visita.sede?.nombre ?? 'Sede no disponible',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          visita.sede?.municipio?.nombre ?? 'Municipio no disponible',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                       decoration: BoxDecoration(
                     color: Colors.orange.withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(12),
                   ),
                    child: Text(
                      'PENDIENTE',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.calendar_today,
                'Fecha programada',
                visita.fechaCreacion != null
                    ? _formatDate(visita.fechaCreacion!)
                    : 'No disponible',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.location_on,
                'Ubicación',
                '${visita.sede?.municipio?.nombre ?? 'N/A'} - ${visita.sede?.institucion?.nombre ?? 'N/A'}',
              ),
              if (visita.tipoAsunto != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.subject,
                  'Tipo de asunto',
                  visita.tipoAsunto!,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _seleccionarVisita(visita),
                      icon: const Icon(Icons.edit),
                      label: const Text('Completar Visita'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        side: BorderSide(color: Colors.orange[700]!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _mostrarDetallesVisita(visita),
                    icon: const Icon(Icons.info_outline),
                    tooltip: 'Ver detalles',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _mostrarDetallesVisita(Visita visita) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalles de la Visita'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Sede', visita.sede?.nombre ?? 'No disponible'),
                _buildDetailRow('Municipio', visita.sede?.municipio?.nombre ?? 'No disponible'),
                _buildDetailRow('Institución', visita.sede?.institucion?.nombre ?? 'No disponible'),
                _buildDetailRow('Estado', visita.estado ?? 'No disponible'),
                if (visita.tipoAsunto != null)
                  _buildDetailRow('Tipo de asunto', visita.tipoAsunto!),
                if (visita.observaciones != null)
                  _buildDetailRow('Observaciones', visita.observaciones!),
                if (visita.fechaCreacion != null)
                  _buildDetailRow('Fecha de creación', _formatDate(visita.fechaCreacion!)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _seleccionarVisita(visita);
              },
              child: const Text('Completar Visita'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
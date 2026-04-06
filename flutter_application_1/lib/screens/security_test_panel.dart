import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/security_service.dart';

/// Pantalla de testing para verificar el Nivel 1 (Detección de Root)
/// Solo disponible en modo debug
class SecurityTestPanel extends StatefulWidget {
  const SecurityTestPanel({super.key});

  @override
  State<SecurityTestPanel> createState() => _SecurityTestPanelState();
}

class _SecurityTestPanelState extends State<SecurityTestPanel> {
  bool? _isRooted;
  Map<String, dynamic> _deviceInfo = {};
  String _testStatus = 'Presiona "Ejecutar Tests" para comenzar';
  bool _isLoading = false;

  Future<void> _runSecurityTests() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Ejecutando tests...';
    });

    try {
      // Verificar root
      final isRooted = await SecurityService.isDeviceRooted();
      
      // Obtener info del dispositivo
      final deviceInfo = await SecurityService.getDeviceInfo();

      setState(() {
        _isRooted = isRooted;
        _deviceInfo = deviceInfo;
        _testStatus = 'Tests completados ✅';
      });

      // Registrar evento
      await SecurityService.logSecurityEvent(
        'TEST_PANEL_EXECUTED',
        'Tests de seguridad ejecutados. Root: $isRooted',
      );
    } catch (e) {
      setState(() {
        _testStatus = 'Error durante tests: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔒 Panel de Testing - NIVEL 1'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instrucciones
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '📋 INSTRUCCIONES DE TESTING',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Presiona el botón "Ejecutar Tests de Seguridad"',
                    ),
                    Text(
                      '2. Observa los resultados de la detección de root',
                    ),
                    Text(
                      '3. Revisa la información del dispositivo',
                    ),
                    Text(
                      '4. Verifica los logs en: flutter logs',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botón de Tests
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.security),
                onPressed: _isLoading ? null : _runSecurityTests,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepOrange,
                ),
                label: Text(
                  _isLoading
                      ? 'Ejecutando tests...'
                      : 'Ejecutar Tests de Seguridad',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Estado de Tests
            Card(
              color: _testStatus.contains('✅')
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _testStatus.contains('✅')
                          ? Icons.check_circle
                          : Icons.info,
                      color: _testStatus.contains('✅')
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _testStatus,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Resultado de Root Detection
            if (_isRooted != null) ...[
              Text(
                'RESULTADO: DETECCIÓN DE ROOT',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                color: _isRooted! ? Colors.red.shade50 : Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: _isRooted! ? Colors.red : Colors.green,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isRooted! ? Icons.warning : Icons.verified,
                            color: _isRooted! ? Colors.red : Colors.green,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isRooted!
                                      ? '❌ DISPOSITIVO ROOTEADO'
                                      : '✅ DISPOSITIVO SEGURO',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _isRooted! ? Colors.red : Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isRooted!
                                      ? 'Se detectó que el dispositivo tiene privilegios de root'
                                      : 'No se detectaron privilegios de root',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_isRooted!)
                        const Column(
                          children: [
                            SizedBox(height: 12),
                            Divider(),
                            SizedBox(height: 12),
                            Text(
                              'En una aplicación real, se mostraría un diálogo de alerta y la app se cerraría.',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Información del Dispositivo
            if (_deviceInfo.isNotEmpty) ...[
              Text(
                'INFORMACIÓN DEL DISPOSITIVO',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _deviceInfo.entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    '${e.key}:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    e.value.toString(),
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Notas de Testing
            Card(
              color: Colors.yellow.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '📝 NOTAS DE TESTING',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Esta pantalla solo es visible en modo DEBUG',
                    ),
                    Text(
                      '• Los tests se ejecutan sin cerrar la app',
                    ),
                    Text(
                      '• En producción, se cerraría la app automáticamente si detecta root',
                    ),
                    Text(
                      '• Revisa "flutter logs" para ver los eventos de seguridad',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

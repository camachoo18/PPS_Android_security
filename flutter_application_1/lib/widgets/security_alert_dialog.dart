import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/security_service.dart';

/// Diálogo que se muestra cuando se detecta un entorno inseguro (root)
/// MSTG-RES-1: Si se detecta root, la app debe informar al usuario y finalizar de forma segura
class SecurityAlertDialog {
  static void showRootDetected(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.security, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('⚠️ Dispositivo Inseguro'),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se ha detectado que tu dispositivo tiene privilegios de administrador (root).',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                Text(
                  'Por razones de seguridad, esta aplicación no puede ejecutarse en dispositivos rooteados ya que esto compromete:',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Integridad de datos sensibles'),
                      Text('• Protección de credenciales'),
                      Text('• Seguridad de la API'),
                      Text('• Control remoto de la aplicación'),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Desinstala las aplicaciones de root y vuelve a intentar.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                SecurityService.shutdownSecurely();
              },
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );
  }

  /// Diálogo alternativo para entornos de emulador o debug
  static void showDebugEnvironmentWarning(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('⚠️ Entorno de Desarrollo'),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se ha detectado que la aplicación se ejecuta en un entorno modificado.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                Text(
                  'En producción, esta aplicación requiere un dispositivo seguro sin root/jailbreak.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                SecurityService.shutdownSecurely();
              },
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );
  }

  /// Diálogo que se muestra cuando se detecta un debugger conectado
  /// MSTG-RES-2: Si se detecta anti-debugging, la app debe cerrar
  static void showDebuggerDetected(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('🔴 Análisis Detectado'),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se ha detectado un debugger o herramienta de análisis dinámico conectada.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                Text(
                  'Por razones de seguridad, esta aplicación no puede ejecutarse bajo análisis dinámico (MSTG-RES-2).',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Esto previene:'),
                      Text('• Inyección de código malicioso'),
                      Text('• Alteración de funciones de seguridad'),
                      Text('• Robo de credenciales en tiempo real'),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Desconecta cualquier debugger o herramienta de análisis dinámico e intenta nuevamente.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                SecurityService.shutdownSecurely();
              },
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );
  }

  /// Diálogo para detección de herramientas externas de análisis
  /// MSTG-RES-2: Detecta Frida, Xposed, y otras herramientas de reversing
  static void showAnalysisToolsDetected(
    BuildContext context,
    Map<String, dynamic> analysisDetails,
  ) {
    // Construir descripción de herramientas detectadas
    List<String> toolsDetected = [];
    if (analysisDetails['frida_detected'] == true) toolsDetected.add('Frida');
    if (analysisDetails['xposed_detected'] == true) toolsDetected.add('Xposed Framework');
    if (analysisDetails['debugger_connected'] == true) toolsDetected.add('Debugger Nativo');

    final suspiciousProcesses = analysisDetails['suspicious_processes'] ?? [];
    final suspiciousFiles = analysisDetails['suspicious_files'] ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.security_update_warning, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('🔴 Herramientas Externas Detectadas'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Se han detectado herramientas externas de análisis de código en tu dispositivo.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                if (toolsDetected.isNotEmpty) ...[
                  const Text(
                    'Herramientas encontradas:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: toolsDetected
                          .map((tool) => Text('• $tool', style: const TextStyle(fontSize: 12)))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if ((suspiciousProcesses as List).isNotEmpty) ...[
                  const Text(
                    'Procesos sospechosos:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (suspiciousProcesses as List)
                          .map((proc) => Text('• $proc', style: const TextStyle(fontSize: 11)))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if ((suspiciousFiles as List).isNotEmpty) ...[
                  const Text(
                    'Archivos sospechosos:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (suspiciousFiles as List)
                          .map((file) => Text('• $file', style: const TextStyle(fontSize: 11)))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Por razones de seguridad, esta aplicación no puede ejecutarse en un entorno bajo análisis dinámico (MSTG-RES-2).',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                SecurityService.shutdownSecurely();
              },
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );
  }
}

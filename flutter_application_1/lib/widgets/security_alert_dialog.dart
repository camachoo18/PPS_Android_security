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
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('⚠️ Dispositivo Inseguro'),
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
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('⚠️ Entorno de Desarrollo'),
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
}

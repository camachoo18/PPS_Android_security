import 'dart:io';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Servicio de seguridad para detección de root y entornos inseguros
/// Implementa MSTG-RES-1: Detección de root y entorno inseguro
/// IMPORTANTE: Usa RootBeer nativo (Kotlin) para detección multivariable
class SecurityService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  // Canal de Method para comunicación con código nativo Android
  static const platform = MethodChannel('com.example.flutter_application_1/security');

  /// Verifica si el dispositivo está rooteado usando RootBeer (multivariable detection)
  /// Esto cumple con MSTG-RES-1: Integrar librería RootBeer para detección multivariable
  /// 
  /// En Android: Usa RootBeer nativo (Kotlin) que realiza:
  ///   - Búsqueda de binarios su
  ///   - Verificación de propiedades del sistema
  ///   - Detección de herramientas de root conocidas
  ///   - Y más verificaciones multivariables
  /// 
  /// En otras plataformas: Retorna false (no hay root)
  static Future<bool> isDeviceRooted() async {
    try {
      // En Android: Usar RootBeer nativo
      if (Platform.isAndroid) {
        try {
          print('Iniciando detección de root con RootBeer (MSTG-RES-1)...');
          
          // Llamar al método nativo que usa RootBeer
          final bool isRooted = await platform.invokeMethod<bool>('isDeviceRooted') ?? false;
          
          if (isRooted) {
            print('🔴 DETECCIÓN MULTIVARIABLE: Dispositivo rooteado detectado por RootBeer');
            return true;
          } else {
            print('✓ RootBeer: Dispositivo seguro (no rooteado)');
          }

          return isRooted;
        } on PlatformException catch (e) {
          print('Error en RootBeer: ${e.message}');
          print('Continuando con verificaciones alternativas...');
          
          // Fallback a verificaciones manuales si RootBeer falla
          return await _performManualRootChecks();
        }
      }

      // En otras plataformas (Linux, Windows, Web): retornar false (no hay root en estos)
      print('Plataforma ${Platform.operatingSystem}: No aplica detección de root nativa');
      return false;
    } catch (e) {
      // En caso de error, asumimos entorno seguro pero registramos
      print('Error en detección de root: $e');
      return false;
    }
  }

  /// Obtiene diagnósticos detallados de la detección de root
  static Future<Map<String, dynamic>> getRootDiagnostics() async {
    try {
      if (Platform.isAndroid) {
        try {
          final result = await platform.invokeMethod<Map<dynamic, dynamic>>('getRootDiagnostics');
          return Map<String, dynamic>.from(result ?? {});
        } on PlatformException catch (e) {
          print('Error obteniendo diagnósticos: ${e.message}');
          return {'error': e.message};
        }
      }
      return {};
    } catch (e) {
      print('Error en getRootDiagnostics: $e');
      return {'error': e.toString()};
    }
  }

  /// Realiza verificaciones manuales de root adicionales (fallback)
  /// Comprueba la existencia de binarios su
  /// MSTG-RES-1: Incluye verificación específica de /system/xbin/su
  static Future<bool> _performManualRootChecks() async {
    try {
      if (!Platform.isAndroid) {
        return false;
      }

      print('Realizando verificaciones manuales de root (fallback)...');

      // Lista de rutas comunes de su en dispositivos rooteados
      final commonRootPaths = [
        '/system/xbin/su',        // ✓ Verificación principal solicitada en MSTG-RES-1
        '/system/bin/su',
        '/system/xbin/daemonsu',
        '/data/local/su',
        '/data/local/bin/su',
        '/data/su',
        '/su/bin/su',
        '/sbin/su',
        '/system/su',
      ];

      // Verificar existencia de archivos
      for (String path in commonRootPaths) {
        try {
          final file = File(path);
          if (await file.exists()) {
            print('🔴 Verificación manual: Archivo encontrado en: $path');
            return true;
          }
        } catch (e) {
          continue;
        }
      }

      print('✓ Verificaciones manuales: No se encontraron indicadores de root');
      return false;
    } catch (e) {
      print('Error en verificaciones manuales: $e');
      return false;
    }
  }

  /// Obtiene información del dispositivo para logging y debug
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'device': androidInfo.device,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          'platform': 'Android',
        };
      } else if (Platform.isLinux) {
        return {
          'platform': 'Linux Desktop',
          'note': 'En Linux Desktop no aplica detección de root (testing mode)',
        };
      } else if (Platform.isWindows) {
        return {
          'platform': 'Windows Desktop',
          'note': 'En Windows Desktop no aplica detección de root (testing mode)',
        };
      }
      return {};
    } catch (e) {
      print('Error obteniendo información del dispositivo: $e');
      return {};
    }
  }

  /// Registra evento de seguridad - MSTG-RES-1: Política de cerrar la app
  /// Registra cuando se detecta root para auditoría
  static Future<void> logSecurityEvent(String eventType, String details) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] SECURITY_EVENT: $eventType - $details');
    
    // En producción, esto enviaría a servidor de logging o servidor de seguridad
  }

  /// Simula cierre seguro de la aplicación
  /// MSTG-RES-1: La política requiere cerrar de forma segura
  static void shutdownSecurely() {
    print('Cerrando aplicación por motivos de seguridad (MSTG-RES-1)');
    exit(0);
  }
}


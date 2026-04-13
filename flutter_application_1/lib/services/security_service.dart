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

  /// Verifica si un debugger está conectado (NIVEL 2 - MSTG-RES-2)
  /// Anti-Debugging: Detecta si herramientas de debugreen están conectadas
  /// Nota: En debug mode de Flutter, esto puede retornar true, pero en release mode
  /// el MainActivity.kt hace System.exit(0) antes de que esto se ejecute
  static Future<bool> isDebuggerConnected() async {
    try {
      if (Platform.isAndroid) {
        try {
          print('Verificando si debugger está conectado (MSTG-RES-2)...');
          
          // Llamar al método nativo que usa Debug.isDebuggerConnected()
          final bool isConnected = await platform.invokeMethod<bool>('isDebuggerConnected') ?? false;
          
          if (isConnected) {
            print('🔴 ANTI-DEBUG: Debugger conectado detectado');
          } else {
            print('✓ Debugger: No conectado');
          }
          
          return isConnected;
        } on PlatformException catch (e) {
          print('Error verificando debugger: ${e.message}');
          return false;  // En caso de error, asumir que no hay debugger
        }
      }
      
      // En Desktop: No hay debugger nativo, retornamos false
      return false;
    } catch (e) {
      print('Error en isDebuggerConnected: $e');
      return false;
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
  /// MSTG-RES-2: Detección completa de herramientas externas de análisis
  /// Detecta Frida, Xposed, debuggers y herramientas de reversing
  /// Retorna un mapa con detalles de qué se detectó
  static Future<Map<String, dynamic>> checkForExternalAnalysisTools() async {
    try {
      if (Platform.isAndroid) {
        try {
          print('🔍 Comprobando herramientas externas de análisis (MSTG-RES-2)...');
          
          final result = await platform.invokeMethod<Map<dynamic, dynamic>>('checkForExternalAnalysisTools');
          final analysisResults = Map<String, dynamic>.from(result ?? {});
          
          // Log de resultados
          final toolFound = analysisResults['analysis_tool_found'] ?? false;
          if (toolFound) {
            print('⚠️ ADVERTENCIA: Herramienta de análisis detectada');
            if (analysisResults['frida_detected'] == true) print('  - Frida detectado');
            if (analysisResults['xposed_detected'] == true) print('  - Xposed Framework detectado');
            if (analysisResults['debugger_connected'] == true) print('  - Debugger conectado');
          } else {
            print('✓ No se detectaron herramientas externas');
          }
          
          return analysisResults;
        } on PlatformException catch (e) {
          print('Error en checkForExternalAnalysisTools: ${e.message}');
          return {'error': e.message, 'analysis_tool_found': false};
        }
      }
      
      // En Desktop: retornar false (no hay herramientas en desarrollo)
      return {'analysis_tool_found': false, 'platform': 'desktop'};
    } catch (e) {
      print('Error en checkForExternalAnalysisTools: $e');
      return {'error': e.toString(), 'analysis_tool_found': false};
    }
  }

  /// MSTG-RES-2: Verifica si alguna herramienta de análisis está activa
  /// Retorna true si se detecta cualquier herramienta
  static Future<bool> hasExternalAnalysisTools() async {
    final results = await checkForExternalAnalysisTools();
    return results['analysis_tool_found'] ?? false;
  }

  // ==================== NIVEL 3: VERIFICACIÓN DE FIRMA Y DETECCIÓN DE TAMPERING ====================

  /// MSTG-RES-3: Verifica la integridad del APK
  /// Compara el hash SHA-1 de la firma actual con el valor hardcodeado
  /// Detecta si el APK fue re-empaquetado o modificado (Anti-Tampering)
  static Future<bool> verifyAPKSignature() async {
    if (Platform.isAndroid) {
      try {
        print('🔍 Verificando integridad del APK (MSTG-RES-3)...');

        final bool isValid = await platform.invokeMethod<bool>('verifyAPKSignature') ?? false;

        if (isValid) {
          print('✓ APK verificado: Firma válida (no fue re-empaquetado)');
        } else {
          print('🔴 APK MODIFICADO: Firma no coincide (posible tampering/re-empaquetado)');
        }

        return isValid;
      } on PlatformException catch (e) {
        print('Error verificando firma: ${e.message}');
        return false;
      }
    }

    // En Desktop: retornar true (no aplica verificación)
    return true;
  }

  /// MSTG-RES-3: Obtiene el hash SHA-1 actual de la firma (para debugging)
  static Future<String> getAPKSignatureHash() async {
    if (Platform.isAndroid) {
      try {
        final String hash = await platform.invokeMethod<String>('getAPKSignatureHash') ?? '';
        return hash;
      } on PlatformException catch (e) {
        print('Error obteniendo hash: ${e.message}');
        return '';
      }
    }
    return '';
  }

  // ==================== NIVEL 5: RESPUESTA DINÁMICA Y RESILIENCIA ====================

  /// MSTG-RES-5: Detecta si la aplicación se ejecuta en un emulador
  /// Esto es parte de NIVEL 5: Respuesta dinámica y resiliencia UX
  /// El emulador se detecta mediante 4 métodos diferentes:
  ///   - Propiedades del sistema (android.kernel.qemu, ro.secure)
  ///   - Archivos específicos de emulador (/system/lib/libqemu.so, etc.)
  ///   - Características del dispositivo (device, model, manufacturer names)
  ///   - Entorno QEMU (bootloader)
  static Future<bool> isRunningOnEmulator() async {
    try {
      if (Platform.isAndroid) {
        final bool isEmulator = await platform.invokeMethod<bool>('isRunningOnEmulator') ?? false;
        if (isEmulator) {
          print('⚠️ ADVERTENCIA: Se detectó que la aplicación se ejecuta en un emulador');
        }
        return isEmulator;
      }
    } on PlatformException catch (e) {
      print('Error comprobando emulador: ${e.message}');
    }
    return false;
  }

  /// Cierre seguro de la aplicación
  /// MSTG-RES: La política requiere cerrar de forma segura cuando se detecten amenazas
  static void shutdownSecurely() {
    print('🛑 Cerrando aplicación por motivos de seguridad (MSTG-RESILIENCE)');
    exit(0);
  }
}
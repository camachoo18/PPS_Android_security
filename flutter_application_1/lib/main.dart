import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/imc_list_screen.dart';
import 'package:flutter_application_1/screens/security_test_panel.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/security_service.dart';
import 'package:flutter_application_1/widgets/security_alert_dialog.dart';

// 🧪 FLAGS PARA TESTING - DESACTIVA EN PRODUCCIÓN
// Permite testar NIVEL 2 sin que NIVEL 1 interfiera
const bool SKIP_ROOT_CHECK_FOR_TESTING = true;  // Cambiar a 'false' en producción

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Registro de IMC',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}

// Pantalla inicial que verifica sesión
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    // 🧪 TESTING NIVEL 2: Si SKIP_ROOT_CHECK_FOR_TESTING=true, saltamos NIVEL 1
    if (!SKIP_ROOT_CHECK_FOR_TESTING) {
      // NIVEL 1: Verificar que el dispositivo no esté rooteado
      final isDeviceRooted = await SecurityService.isDeviceRooted();
      
      if (isDeviceRooted) {
        // Registrar evento de seguridad
        await SecurityService.logSecurityEvent(
          'ROOTED_DEVICE_DETECTED',
          'Dispositivo con privilegios de root detectado. Aplicación terminada.',
        );
        
        if (mounted) {
          // Mostrar diálogo de alerta y cerrar la aplicación
          SecurityAlertDialog.showRootDetected(context);
          return; // No continuar con la ejecución
        }
      }
    }

    // NIVEL 2: Verificar que no hay debugger conectado (Anti-Debugging)
    // Nota: En Android, MainActivity.kt ya hace System.exit(0) en onCreate()
    // Si llegamos aquí es porque no hay debugger (o estamos en debug mode de Flutter)
    final isDebuggerConnected = await SecurityService.isDebuggerConnected();
    
    if (isDebuggerConnected) {
      // En release build, esto nunca se ejecutará porque MainActivity.kt hizo exit(0)
      // Pero en debug mode de Flutter, registramos para logging
      await SecurityService.logSecurityEvent(
        'DEBUGGER_DETECTED',
        'Debugger conectado detectado. Aplicación terminada.',
      );
      
      if (mounted) {
        // Mostrar diálogo de alerta y cerrar
        SecurityAlertDialog.showDebuggerDetected(context);
        return;
      }
    }

    // NIVEL 2 EXTENDIDO: Detección completa de herramientas externas
    // Detecta Frida, Xposed, y otras herramientas de reversing/análisis
    final hasAnalysisTools = await SecurityService.hasExternalAnalysisTools();

    if (hasAnalysisTools) {
      // Obtener detalles de qué se detectó
      final analysisDetails = await SecurityService.checkForExternalAnalysisTools();

      await SecurityService.logSecurityEvent(
        'EXTERNAL_ANALYSIS_TOOLS_DETECTED',
        'Herramientas externas de análisis detectadas: $analysisDetails',
      );

      if (mounted) {
        // Mostrar diálogo de alerta y cerrar
        SecurityAlertDialog.showAnalysisToolsDetected(context, analysisDetails);
        return;
      }
    }

    // NIVEL 3: Verificar integridad del APK (Anti-Tampering)
    // Detecta si el APK fue re-empaquetado o modificado
    final isAPKValid = await SecurityService.verifyAPKSignature();

    if (!isAPKValid) {
      await SecurityService.logSecurityEvent(
        'APK_TAMPERING_DETECTED',
        'Se detectó que el APK fue modificado o re-empaquetado.',
      );

      if (mounted) {
        // Mostrar diálogo de alerta y cerrar
        SecurityAlertDialog.showAPKTamperingDetected(context);
        return;
      }
    }

    // Si el dispositivo es seguro y no hay herramientas de análisis, continuar normalmente
    await Future.delayed(const Duration(seconds: 1));
    final isLoggedIn = await AuthService.isLoggedIn();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isLoggedIn 
              ? const IMCListScreen()
              : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Centro: Loading
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.health_and_safety, size: 80, color: Colors.blue),
                SizedBox(height: 20),
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Inicializando...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          
          // En modo DEBUG, mostrar botón de testing en la esquina superior derecha
          if (kDebugMode)
            Positioned(
              top: 40,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () {
                  print('Botón Testing presionado, navegando a SecurityTestPanel...');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SecurityTestPanel(),
                    ),
                  );
                },
                backgroundColor: Colors.deepOrange,
                icon: const Icon(Icons.security),
                label: const Text('Testing'),
              ),
            ),
        ],
      ),
    );
  }
}
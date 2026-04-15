import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/imc_list_screen.dart';
import 'package:flutter_application_1/screens/security_test_panel.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/security_service.dart';
import 'package:flutter_application_1/widgets/security_alert_dialog.dart';

// Test flag: set to false in production
const bool SKIP_ROOT_CHECK_FOR_TESTING = true;

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

// Initial screen for session check
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

    if (!SKIP_ROOT_CHECK_FOR_TESTING) {
      final isDeviceRooted = await SecurityService.isDeviceRooted();
      
      if (isDeviceRooted) {
        await SecurityService.logSecurityEvent(
          'ROOTED_DEVICE_DETECTED',
          'Dispositivo con privilegios de root detectado',
        );
        
        if (mounted) {
          SecurityAlertDialog.showRootDetected(context);
          return;
        }
      }
    }

    // Check debugger
    final isDebuggerConnected = await SecurityService.isDebuggerConnected();
    
    if (isDebuggerConnected) {
      await SecurityService.logSecurityEvent(
        'DEBUGGER_DETECTED',
        'Debugger conectado detectado',
      );
      
      if (mounted) {
        SecurityAlertDialog.showDebuggerDetected(context);
        return;
      }
    }

    // Check external tools
    final hasAnalysisTools = await SecurityService.hasExternalAnalysisTools();

    if (hasAnalysisTools) {
      final analysisDetails = await SecurityService.checkForExternalAnalysisTools();
      await SecurityService.logSecurityEvent('EXTERNAL_ANALYSIS_TOOLS_DETECTED', '${analysisDetails}');

      if (mounted) {
        SecurityAlertDialog.showAnalysisToolsDetected(context, analysisDetails);
        return;
      }
    }

    // Check APK integrity
    final isAPKValid = await SecurityService.verifyAPKSignature();

    if (!isAPKValid) {
      await SecurityService.logSecurityEvent('APK_TAMPERING_DETECTED', 'APK modificado detectado');

      if (mounted) {
        SecurityAlertDialog.showAPKTamperingDetected(context);
        return;
      }
    }

    print('✓ Aplicación segura');
    
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
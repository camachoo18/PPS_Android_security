package com.example.flutter_application_1

import android.os.Debug
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Activity principal de la aplicación
 * Expone canales de seguridad para Dart mediante MethodChannel
 * NIVEL 2: Anti-Debugging - Verifica debugger en onCreate()
 */
class MainActivity : FlutterActivity() {
    private val SECURITY_CHANNEL = "com.example.flutter_application_1/security"
    private lateinit var securityService: SecurityService

    override fun onCreate(savedInstanceState: Bundle?) {
        // NIVEL 2: Chequeo de Anti-Debugging MSTG-RES-2
        // Verificar ANTES de que Flutter se inicialice
        if (Debug.isDebuggerConnected()) {
            android.util.Log.e("AntiDebug", "🔴 DEBUGGER CONECTADO - Cerrando aplicación")
            System.exit(0)  // Cierre inmediato sin permitir continuación
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Inicializar servicio de seguridad
        securityService = SecurityService(this)

        // Crear canal de método para seguridad
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // NIVEL 1: Detección de root usando RootBeer
                    "isDeviceRooted" -> {
                        try {
                            val isRooted = securityService.isDeviceRooted()
                            result.success(isRooted)
                        } catch (e: Exception) {
                            result.error("ROOT_CHECK_ERROR", e.message, null)
                        }
                    }

                    // Obtener diagnósticos detallados
                    "getRootDiagnostics" -> {
                        try {
                            val diagnostics = securityService.getRootDiagnostics()
                            result.success(diagnostics)
                        } catch (e: Exception) {
                            result.error("DIAGNOSTICS_ERROR", e.message, null)
                        }
                    }

                    // NIVEL 2: Anti-Debugging - Verificar si debugger está conectado
                    "isDebuggerConnected" -> {
                        try {
                            val isDebuggerConnected = Debug.isDebuggerConnected()
                            result.success(isDebuggerConnected)
                        } catch (e: Exception) {
                            result.error("DEBUGGER_CHECK_ERROR", e.message, null)
                        }
                    }

                    // NIVEL 2: Anti-Debugging - Detección completa de herramientas externas
                    "checkForExternalAnalysisTools" -> {
                        try {
                            val analysisResults = securityService.checkForExternalAnalysisTools()
                            result.success(analysisResults)
                        } catch (e: Exception) {
                            result.error("ANALYSIS_TOOLS_CHECK_ERROR", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}

package com.example.flutter_application_1

import android.os.Debug
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.flutter_application_1.SecurityService

class MainActivity : FlutterActivity() {
    private val SECURITY_CHANNEL = "com.example.flutter_application_1/security"
    private lateinit var securityService: SecurityService

    override fun onCreate(savedInstanceState: Bundle?) {
        /// Anti-Debugging: Cierre inmediato si debugger conectado
        if (Debug.isDebuggerConnected()) {
            System.exit(0)
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
                    "isDeviceRooted" -> {
                        try {
                            val isRooted = securityService.isDeviceRooted()
                            result.success(isRooted)
                        } catch (e: Exception) {
                            result.error("ROOT_CHECK_ERROR", e.message, null)
                        }
                    }

                    "getRootDiagnostics" -> {
                        try {
                            val diagnostics = securityService.getRootDiagnostics()
                            result.success(diagnostics)
                        } catch (e: Exception) {
                            result.error("DIAGNOSTICS_ERROR", e.message, null)
                        }
                    }

                    "isDebuggerConnected" -> {
                        try {
                            val isDebuggerConnected = Debug.isDebuggerConnected()
                            result.success(isDebuggerConnected)
                        } catch (e: Exception) {
                            result.error("DEBUGGER_CHECK_ERROR", e.message, null)
                        }
                    }

                    "checkForExternalAnalysisTools" -> {
                        try {
                            val analysisResults = securityService.checkForExternalAnalysisTools()
                            result.success(analysisResults)
                        } catch (e: Exception) {
                            result.error("ANALYSIS_TOOLS_CHECK_ERROR", e.message, null)
                        }
                    }

                    "getAPKSignatureHash" -> {
                        try {
                            val hash = securityService.getAPKSignatureHash()
                            result.success(hash)
                        } catch (e: Exception) {
                            result.error("APK_HASH_GET_ERROR", e.message, null)
                        }
                    }

                    "verifyAPKSignature" -> {
                        try {
                            val isValid = securityService.verifyAPKSignature()
                            result.success(isValid)
                        } catch (e: Exception) {
                            result.error("APK_SIGNATURE_CHECK_ERROR", e.message, null)
                        }
                    }

                    "isRunningOnEmulator" -> {
                        try {
                            val isEmulator = securityService.isRunningOnEmulator()
                            result.success(isEmulator)
                        } catch (e: Exception) {
                            result.error("EMULATOR_CHECK_ERROR", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}

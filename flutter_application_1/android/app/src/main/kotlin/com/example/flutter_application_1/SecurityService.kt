package com.example.flutter_application_1

import android.content.Context
import android.os.Debug
import java.io.File
import com.scottyab.rootbeer.RootBeer

/**
 * Servicio de Seguridad Nativo (Kotlin)
 * Implementa:
 * - MSTG-RES-1: Detección multivariable de root usando RootBeer
 * - MSTG-RES-2: Detección de herramientas externas de análisis (Anti-Debugging)
 */
class SecurityService(private val context: Context) {
    private val rootBeer = RootBeer(context)

    /**
     * Detecta si el dispositivo está rooteado usando RootBeer
     * Realiza múltiples verificaciones (detección multivariable):
     * - Búsqueda de binarios su
     * - Verificación de propiedades del sistema
     * - Detección de herramientas de root conocidas
     * - Análisis de permisos de directorio
     * - Y más verificaciones que RootBeer implementa
     *
     * @return true si el dispositivo está rooteado, false si es seguro
     */
    fun isDeviceRooted(): Boolean {
        return try {
            val result = rootBeer.isRooted
            if (result) {
                android.util.Log.e("SecurityService", " DISPOSITIVO ROOTEADO DETECTADO")
            } else {
                android.util.Log.d("SecurityService", "✓ Dispositivo seguro (no rooteado)")
            }
            result
        } catch (e: Exception) {
            android.util.Log.e("SecurityService", "Error en detección de root: ${e.message}")
            false
        }
    }

    /**
     * Obtiene un diagnóstico detallado de por qué se detectó root
     * Útil para debugging y logging
     */
    fun getRootDiagnostics(): Map<String, Any> {
        return try {
            mapOf(
                "isRooted" to rootBeer.isRooted,
                "detectionMethod" to "RootBeer (multivariable)",
                "libraryVersion" to "0.1.0"
            )
        } catch (e: Exception) {
            mapOf(
                "error" to e.message.toString(),
                "detectionMethod" to "RootBeer (error)"
            )
        }
    }

    // ==================== NIVEL 2: DETECCIÓN DE HERRAMIENTAS EXTERNAS ====================

    /**
     * NIVEL 2: Comprobación integral de herramientas externas de análisis
     * Detecta:
     * - Frida (dynamic instrumentation)
     * - Xposed Framework (hooking)
     * - GDB/Debuggers nativos
     * - Procesos sospechosos
     * - Archivos de reversing tools
     */
    fun checkForExternalAnalysisTools(): Map<String, Any> {
        return mapOf(
            "frida_detected" to checkForFrida(),
            "xposed_detected" to checkForXposed(),
            "debugger_connected" to Debug.isDebuggerConnected(),
            "suspicious_processes" to checkForSuspiciousProcesses(),
            "suspicious_files" to checkForSuspiciousFiles(),
            "analysis_tool_found" to (
                checkForFrida() ||
                checkForXposed() ||
                Debug.isDebuggerConnected() ||
                checkForSuspiciousProcesses().isNotEmpty() ||
                checkForSuspiciousFiles().isNotEmpty()
            )
        )
    }

    /**
     * Detecta si Frida está inyectado en el proceso
     * Frida es una herramienta popular de dynamic instrumentation
     */
    private fun checkForFrida(): Boolean {
        return try {
            // Buscar libraries de Frida en el namespace
            val maps = File("/proc/self/maps").readText()
            if (maps.contains("frida")) {
                android.util.Log.e("AntiAnalysis", "🔴 FRIDA DETECTADO")
                return true
            }

            // Buscar procesos de Frida
            val processes = Runtime.getRuntime().exec("ps").inputStream.bufferedReader().readText()
            if (processes.contains("frida") || processes.contains("frida-server")) {
                android.util.Log.e("AntiAnalysis", "🔴 PROCESO FRIDA DETECTADO")
                return true
            }

            false
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Detecta si Xposed Framework está activo
     * Xposed es un framework que permite modificar el comportamiento del sistema
     */
    private fun checkForXposed(): Boolean {
        return try {
            // Verificar si la aplicación se ejecuta en un contexto modificado por Xposed
            try {
                ClassLoader.getSystemClassLoader().loadClass("de.robv.android.xposed.XposedHelpers")
                android.util.Log.e("AntiAnalysis", "🔴 XPOSED FRAMEWORK DETECTADO")
                return true
            } catch (e: ClassNotFoundException) {
                // Xposed no está cargado
            }

            // Buscar archivos de Xposed en el sistema
            val xposedPaths = listOf(
                "/system/xposed.prop",
                "/system/framework/XposedBridge.jar",
                "/system/app/Xposed.apk",
                "/data/xposed"
            )

            for (path in xposedPaths) {
                if (File(path).exists()) {
                    android.util.Log.e("AntiAnalysis", "🔴 ARCHIVO XPOSED ENCONTRADO: $path")
                    return true
                }
            }

            false
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Detecta procesos sospechosos de herramientas de reversing
     */
    private fun checkForSuspiciousProcesses(): List<String> {
        val suspiciousProcesses = mutableListOf<String>()

        try {
            val processes = Runtime.getRuntime().exec("ps").inputStream.bufferedReader().readText()

            val suspiciousNames = listOf(
                "frida",
                "gdb",
                "lldb",
                "strace",
                "ida",
                "ghidra",
                "radare2",
                "apktool",
                "burp",
                "charles",
                "fiddler"
            )

            for (processName in suspiciousNames) {
                if (processes.contains(processName)) {
                    suspiciousProcesses.add(processName)
                    android.util.Log.e("AntiAnalysis", "🔴 PROCESO SOSPECHOSO: $processName")
                }
            }
        } catch (e: Exception) {
            android.util.Log.w("AntiAnalysis", "Error en checkForSuspiciousProcesses: ${e.message}")
        }

        return suspiciousProcesses
    }

    /**
     * Detecta archivos sospechosos de herramientas de reversing
     */
    private fun checkForSuspiciousFiles(): List<String> {
        val suspiciousFiles = mutableListOf<String>()

        val suspiciousPaths = listOf(
            "/system/app/Frida.apk",
            "/data/frida-server",
            "/system/xposed.prop",
            "/system/framework/XposedBridge.jar",
            "/data/adb/modules/riru",
            "/data/adb/modules/zygisk",
            "/system/app/MobileSubstrate.apk",
            "/system/lib/libsubstrate.so"
        )

        for (path in suspiciousPaths) {
            if (File(path).exists()) {
                suspiciousFiles.add(path)
                android.util.Log.e("AntiAnalysis", "🔴 ARCHIVO SOSPECHOSO ENCONTRADO: $path")
            }
        }

        return suspiciousFiles
    }
}

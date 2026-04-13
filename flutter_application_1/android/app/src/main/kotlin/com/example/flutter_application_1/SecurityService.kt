package com.example.flutter_application_1

import android.content.Context
import android.content.pm.PackageManager
import android.os.Debug
import java.io.File
import java.security.MessageDigest
import com.scottyab.rootbeer.RootBeer

/**
 * Servicio de Seguridad Nativo (Kotlin)
 * Implementa:
 * - MSTG-RES-1: Detección multivariable de root usando RootBeer
 * - MSTG-RES-2: Detección de herramientas externas de análisis (Anti-Debugging)
 * - MSTG-RES-3: Verificación de firma y detección de tampering
 */
class SecurityService(private val context: Context) {
    private val rootBeer = RootBeer(context)

    companion object {
        // NIVEL 3: Hash SHA-1 de la firma del APK original (HARDCODEADO)
        // Este valor se verifica en runtime para detectar tampering
        private const val EXPECTED_SIGNATURE_HASH = "93:9e:9b:68:eb:bd:a2:35:f2:cc:26:e9:2a:30:da:7f:3e:80:55:c5"
    }

    // ==================== NIVEL 3: VERIFICACIÓN DE FIRMA Y DETECCIÓN DE TAMPERING ====================

    /**
     * NIVEL 3: Obtiene el hash SHA-1 de la firma del APK actual
     * Este método se ejecuta en tiempo de ejecución para verificar integridad
     */
    fun getAPKSignatureHash(): String {
        return try {
            @Suppress("DEPRECATION")
            val packageInfo = context.packageManager.getPackageInfo(
                context.packageName,
                PackageManager.GET_SIGNATURES
            )

            val signatures = packageInfo.signatures
            if (signatures == null || signatures.isEmpty()) {
                android.util.Log.e("AntiTampering", "No signatures found")
                return ""
            }

            val messageDigest = MessageDigest.getInstance("SHA-1")
            messageDigest.update(signatures[0].toByteArray())
            val digest = messageDigest.digest()

            val stringBuilder = StringBuilder()
            for (byte in digest) {
                val hex = (byte.toInt() and 0xFF).toString(16).padStart(2, '0')
                if (stringBuilder.isNotEmpty()) stringBuilder.append(":")
                stringBuilder.append(hex)
            }

            stringBuilder.toString()
        } catch (e: Exception) {
            android.util.Log.e("AntiTampering", "Error getting signature hash: ${e.message}")
            ""
        }
    }

    /**
     * NIVEL 3: Verifica la integridad del APK comparando hash de firma
     * Detecta si el APK fue re-empaquetado o modificado (Anti-Tampering)
     * @return true si el APK es legítimo, false si fue modificado
     */
    fun verifyAPKSignature(): Boolean {
        return try {
            val actualHash = getAPKSignatureHash()
            val isValid = actualHash == EXPECTED_SIGNATURE_HASH

            if (isValid) {
                android.util.Log.d("AntiTampering", "✓ APK verificado: Firma válida")
            } else {
                android.util.Log.e("AntiTampering", "🔴 APK MODIFICADO: Firma no coincide")
                android.util.Log.e("AntiTampering", "   Esperado: $EXPECTED_SIGNATURE_HASH")
                android.util.Log.e("AntiTampering", "   Obtenido: $actualHash")
            }

            isValid
        } catch (e: Exception) {
            android.util.Log.e("AntiTampering", "Error verificando firma: ${e.message}")
            false
        }
    }

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

    // ==================== NIVEL 3: VERIFICACIÓN DE INTEGRIDAD Y FIRMA ====================

    /**
     * NIVEL 3: Verifica la integridad del APK mediante el hash del certificado de firma
     * MSTG-RES-3: Detecta si el APK ha sido re-empaquetado o modificado
     * 
     * @param expectedHash: Hash SHA-1 del certificado original (hardcodeado)
     * @return Map con resultado de verificación
     */
    fun verifyAPKSignature(expectedHash: String): Map<String, Any> {
        return try {
            val actualHash = getSignatureSHA1Hash()
            
            val isValid = actualHash.equals(expectedHash, ignoreCase = true)
            
            if (isValid) {
                android.util.Log.d("APKIntegrity", "✓ Firma de APK verificada - Integridad confirmada")
            } else {
                android.util.Log.e("APKIntegrity", "🔴 HASH DE FIRMA NO COINCIDE - APK POSIBLEMENTE MODIFICADO")
                android.util.Log.e("APKIntegrity", "   Expected: $expectedHash")
                android.util.Log.e("APKIntegrity", "   Actual:   $actualHash")
            }
            
            mapOf(
                "signature_valid" to isValid,
                "actual_hash" to actualHash,
                "tampering_detected" to !isValid
            )
        } catch (e: Exception) {
            android.util.Log.e("APKIntegrity", "Error verificando firma: ${e.message}")
            mapOf(
                "error" to e.message.toString(),
                "tampering_detected" to false
            )
        }
    }

    /**
     * Obtiene el hash SHA-1 del certificado de firma actual
     * Útil para obtener el valor que luego hardcodearemos
     */
    fun getSignatureSHA1Hash(): String {
        return try {
            @Suppress("DEPRECATION")
            val packageInfo = context.packageManager.getPackageInfo(
                context.packageName,
                android.content.pm.PackageManager.GET_SIGNATURES
            )
            
            val signatures = packageInfo.signatures
            if (signatures != null && signatures.isNotEmpty()) {
                val signature = signatures[0]
                val md = java.security.MessageDigest.getInstance("SHA-1")
                md.update(signature.toByteArray())
                
                val digest = md.digest()
                digest.joinToString(":") { byte -> "%02x".format(byte) }
            } else {
                android.util.Log.w("APKIntegrity", "No signatures found")
                ""
            }
        } catch (e: Exception) {
            android.util.Log.e("APKIntegrity", "Error obteniendo hash: ${e.message}")
            ""
        }
    }

    /**
     * Obtiene información detallada del certificado para debugging
     */
    fun getSignatureInfo(): Map<String, String> {
        return try {
            @Suppress("DEPRECATION")
            val packageInfo = context.packageManager.getPackageInfo(
                context.packageName,
                android.content.pm.PackageManager.GET_SIGNATURES
            )
            
            val signatures = packageInfo.signatures
            if (signatures != null && signatures.isNotEmpty()) {
                val signature = signatures[0]
                mapOf(
                    "sha1" to getSignatureSHA1Hash(),
                    "md5" to getMD5Hash(signature.toByteArray()),
                    "certificate_raw" to signature.toCharsString().substring(0, minOf(50, signature.toCharsString().length)) + "..."
                )
            } else {
                mapOf("error" to "No signatures found")
            }
        } catch (e: Exception) {
            mapOf("error" to e.message.toString())
        }
    }

    /**
     * Calcula hash MD5 de un array de bytes
     */
    private fun getMD5Hash(data: ByteArray): String {
        val md = java.security.MessageDigest.getInstance("MD5")
        md.update(data)
        val digest = md.digest()
        return digest.joinToString(":") { byte -> "%02x".format(byte) }
    }
}

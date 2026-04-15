package com.example.flutter_application_1

import android.content.Context
import android.content.pm.PackageManager
import android.os.Debug
import java.io.File
import java.security.MessageDigest
import com.scottyab.rootbeer.RootBeer

class SecurityService(private val context: Context) {
    private val rootBeer = RootBeer(context)

    companion object {
        private const val EXPECTED_SIGNATURE_HASH = "93:9e:9b:68:eb:bd:a2:35:f2:cc:26:e9:2a:30:da:7f:3e:80:55:c5"
    }

    /// Obtiene el hash SHA-1 de la firma del APK
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

    /// Verifica integridad del APK comparando hash de firma
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

    /// Detecta si dispositivo está rooteado (RootBeer multivariable)
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

    /// Obtiene diagnóstico detallado de root detection
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

    /// Verificación integral de herramientas externas de análisis
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

    /// Detecta si Frida está inyectado
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

    /// Detecta si Xposed Framework está activo
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

    /// Detecta procesos sospechosos
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

    /// Detecta archivos sospechosos
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

    // ==================== NIVEL 5: DETECCIÓN DE EMULADORES ====================

    /**
     * NIVEL 5: Detecta si la aplicación se ejecuta en un emulador
     * MSTG-RES-5: Identifica entornos controlados para análisis
     * 
     * Métodos de detección:
     * 1. Propiedades del sistema (android.kernel.qemu, ro.serialno, etc.)
     * 2. Presencia de archivos específicos del emulador
     * 3. Características del dispositivo
     * 4. Procesos específicos del emulador
     */
    fun isRunningOnEmulator(): Boolean {
        return checkEmulatorProperties() || 
               checkEmulatorFiles() || 
               checkEmulatorFeatures() ||
               checkQemuEnvironment()
    }

    /**
     * Verificar propiedades del sistema que indican emulador
     */
    private fun checkEmulatorProperties(): Boolean {
        val properties = arrayOf(
            "android.kernel.qemu",          // QEMU property
            "ro.serialno",                  // Serial number often "unknown" in emulator
            "ro.debuggable",                // Debuggable flag
            "ro.secure",                    // Security flag (false in emulator)
        )

        for (prop in properties) {
            try {
                val value = System.getProperty(prop) ?: continue
                
                when (prop) {
                    "android.kernel.qemu" -> {
                        if (value == "1") {
                            android.util.Log.w("EmulatorDetection", "Detected QEMU property")
                            return true
                        }
                    }
                    "ro.serialno" -> {
                        if (value.equals("unknown", ignoreCase = true)) {
                            android.util.Log.w("EmulatorDetection", "Detected unknown serial number")
                            return true
                        }
                    }
                    "ro.secure" -> {
                        if (value == "0") {
                            android.util.Log.w("EmulatorDetection", "Detected insecure system")
                            return true
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore exceptions
            }
        }

        return false
    }

    /**
     * Verificar archivos del emulador
     */
    private fun checkEmulatorFiles(): Boolean {
        val emulatorFiles = arrayOf(
            "/system/lib/libc_malloc_debug_leak.so",      // GenyMotion
            "/system/app/SpeechRecorder.apk",             // Android Emulator
            "/system/lib64/libqemu.so",                   // QEMU
            "/system/lib/libqemu.so",
            "/system/bin/qemu-props",                     // QEMU props
            "/sys/qemu_trace",                            // QEMU trace
            "/system/xbin/qemu-props",
        )

        for (file in emulatorFiles) {
            if (File(file).exists()) {
                android.util.Log.w("EmulatorDetection", "Detected emulator file: $file")
                return true
            }
        }

        return false
    }

    /**
     * Verificar características del emulador (Build properties)
     */
    private fun checkEmulatorFeatures(): Boolean {
        val device = android.os.Build.DEVICE
        val model = android.os.Build.MODEL
        val manufacturer = android.os.Build.MANUFACTURER
        val brand = android.os.Build.BRAND
        val product = android.os.Build.PRODUCT
        val fingerprint = android.os.Build.FINGERPRINT
        val host = android.os.Build.HOST

        // Nombres comunes en emuladores
        val emulatorIndicators = arrayOf(
            "generic",      // Default Android Emulator
            "ranchu",       // Android Emulator (newer)
            "qemu",         // QEMU
            "vbox",         // VirtualBox
            "bluestacks",   // BlueStacks
            "nox",          // Nox App Player
            "genymotion",   // GenyMotion
            "goldfish",     // Android Emulator goldfish
        )

        for (indicator in emulatorIndicators) {
            val lowerDevice = device?.lowercase() ?: ""
            val lowerModel = model?.lowercase() ?: ""
            val lowerManufacturer = manufacturer?.lowercase() ?: ""
            val lowerBrand = brand?.lowercase() ?: ""
            val lowerProduct = product?.lowercase() ?: ""
            val lowerHost = host?.lowercase() ?: ""

            if (lowerDevice.contains(indicator) || 
                lowerModel.contains(indicator) ||
                lowerManufacturer.contains(indicator) ||
                lowerBrand.contains(indicator) ||
                lowerProduct.contains(indicator) ||
                lowerHost.contains(indicator)) {
                
                android.util.Log.w("EmulatorDetection", "Detected emulator indicator: $indicator")
                return true
            }
        }

        return false
    }

    /**
     * Verificar señales de QEMU específicamente
     */
    private fun checkQemuEnvironment(): Boolean {
        try {
            // Verificar propiedades del bootloader
            val bootloader = android.os.Build.BOOTLOADER
            if (bootloader?.lowercase()?.contains("qemu") == true) {
                android.util.Log.w("EmulatorDetection", "Detected QEMU bootloader")
                return true
            }

            // Verificar si es ARM o x86 (emuladores suelen ser x86)
            val abis = android.os.Build.SUPPORTED_ABIS
            if (abis.isNotEmpty() && abis[0].lowercase().contains("x86")) {
                // Esto es opcional - muchos dispositivos legítimos usan x86
                // android.util.Log.d("EmulatorDetection", "Detected x86 architecture (emulator-common)")
                // return true
            }
        } catch (e: Exception) {
            // Ignore exceptions
        }

        return false
    }
}

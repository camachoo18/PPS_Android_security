package com.example.flutter_application_1

import android.content.Context
import com.scottyab.rootbeer.RootBeer

/**
 * Servicio de Seguridad Nativo (Kotlin)
 * Implementa MSTG-RES-1: Detección multivariable de root usando RootBeer
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
}

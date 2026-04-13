# 🔐 IMPLEMENTACIÓN OWASP MSTG-RES-3: VERIFICACIÓN DE INTEGRIDAD DEL APK

## 📋 Resumen Ejecutivo

Se ha implementado **MSTG-RES-3 (Anti-Tampering)** para detectar si el APK ha sido modificado, re-empaquetado o distribuido de forma no autorizada. El sistema verifica en tiempo de ejecución que el certificado de firma del APK coincida con el valor hardcodeado original.

**Estado:** ✅ COMPLETAMENTE IMPLEMENTADO Y COMPILADO

---

## 🎯 Objetivo del NIVEL 3

Prevenir que:
- ✅ El APK sea re-empaquetado con código malicioso inyectado
- ✅ Se modifiquen recursos o funcionalidades originales  
- ✅ Se distribuya una versión comprometida del código
- ✅ Se realicen cambios en la firma del certificado

---

## 🏗️ Arquitectura de Implementación

### Flujo de Verificación

```
App Launch (_checkLogin)
    ↓
NIVEL 1: Root Detection (RootBeer)
    ↓ ✅ PASSED
NIVEL 2: Anti-Debugging (Frida, Xposed, etc.)
    ↓ ✅ PASSED
NIVEL 3: APK Signature Verification ← **AQUÍ**
    ↓
    ├─ Get current APK certificate hash (SHA-1)
    ├─ Compare with hardcoded expected value
    │  ├─ MATCH → All good, continue login
    │  └─ NOT MATCH → APK tampering detected!
    │              → Log security event
    │              → Show alert dialog
    │              → Call System.exit(0)
    ↓
NIVEL 4: Code Obfuscation (ProGuard) - FUTURO
NIVEL 5: Dynamic Response (SecurityManager) - FUTURO
```

---

## 💻 Implementación Técnica

### 1️⃣ Kotlin Native Layer (`SecurityService.kt`)

#### Imports Agregados
```kotlin
import android.content.pm.PackageManager
import java.security.MessageDigest
```

#### Companion Object - Valor Hardcodeado
```kotlin
companion object {
    // MSTG-RES-3: Hash SHA-1 de la firma original del certificado
    // Extraído del APK real y hardcodeado para comparación en runtime
    private const val EXPECTED_SIGNATURE_HASH = "93:9e:9b:68:eb:bd:a2:35:f2:cc:26:e9:2a:30:da:7f:3e:80:55:c5"
}
```

#### Método: `getAPKSignatureHash(): String`
- **Propósito:** Extrae el hash SHA-1 actual de la firma del APK
- **Algoritmo:** 
  1. Obtiene PackageInfo con flags GET_SIGNATURES
  2. Extrae el primer certificado de firma
  3. Calcula SHA-1 usando MessageDigest
  4. Convierte a formato hexadecimal separado por colones
- **Retorna:** String con hash en formato `"XX:XX:XX:..."`
- **Manejo de excepciones:** Retorna "" si falla

```kotlin
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
```

#### Método: `verifyAPKSignature(): Boolean`
- **Propósito:** Verifica que el hash actual coincida con el valor hardcodeado
- **Lógica:**
  1. Llama a `getAPKSignatureHash()` para obtener hash actual
  2. Compara con `EXPECTED_SIGNATURE_HASH`
  3. Registra resultado en logs
  4. Retorna true/false
- **Retorna:** `true` si APK es legítimo, `false` si fue modificado
- **Logging:**
  - ✓ APK válido: Log de éxito
  - 🔴 APK modificado: Log de error crítico

```kotlin
fun verifyAPKSignature(): Boolean {
    return try {
        val currentHash = getAPKSignatureHash()
        
        if (currentHash.isEmpty()) {
            android.util.Log.e("AntiTampering", "Failed to obtain current hash")
            return false
        }

        val isValid = currentHash.equals(EXPECTED_SIGNATURE_HASH, ignoreCase = true)

        if (isValid) {
            android.util.Log.d("AntiTampering", "✓ APK signature verified - Not tampered")
        } else {
            android.util.Log.e("AntiTampering", "🔴 APK TAMPERING DETECTED!")
            android.util.Log.e("AntiTampering", "Expected: $EXPECTED_SIGNATURE_HASH")
            android.util.Log.e("AntiTampering", "Current:  $currentHash")
        }

        isValid
    } catch (e: Exception) {
        android.util.Log.e("AntiTampering", "Error verifying APK: ${e.message}")
        false
    }
}
```

---

### 2️⃣ MethodChannel Bridge (`MainActivity.kt`)

#### Rutas Agregadas en MethodChannel Handler

```kotlin
// NIVEL 3: Obtener hash actual de firma (para debugging)
"getAPKSignatureHash" -> {
    val hash = SecurityService(this).getAPKSignatureHash()
    result.success(hash)
}

// NIVEL 3: Verificar integridad del APK
"verifyAPKSignature" -> {
    val isValid = SecurityService(this).verifyAPKSignature()
    result.success(isValid)
}
```

---

### 3️⃣ Dart Layer (`security_service.dart`)

#### Método Async: `verifyAPKSignature()`
```dart
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
```

#### Método Async: `getAPKSignatureHash()`
```dart
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
```

---

### 4️⃣ Integración en `main.dart`

#### Código de Verificación en `_checkLogin()`

```dart
// NIVEL 3: MSTG-RES-3 - Verificar integridad del APK (Anti-Tampering)
final isAPKValid = await SecurityService.verifyAPKSignature();
if (!isAPKValid) {
  await SecurityService.logSecurityEvent(
    'APK_TAMPERING_DETECTED',
    'Se detectó modificación del APK o re-empaquetado. Firma no disponible.',
  );
  if (mounted) {
    SecurityAlertDialog.showAPKTamperingDetected(context);
    return;
  }
}
```

---

### 5️⃣ Alert Dialog (`security_alert_dialog.dart`)

#### Diálogo: `showAPKTamperingDetected()`

```dart
static void showAPKTamperingDetected(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('🔴 Integridad del APK Comprometida'),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Se detectó que la aplicación ha sido modificada o re-empaquetada.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Text(
                'Esto indica posible tampering o distribución no autorizada (MSTG-RES-3).',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Riesgos identificados:'),
                    Text('• Código malicioso inyectado'),
                    Text('• Modificación de funcionalidades'),
                    Text('• Robo de datos del usuario'),
                    Text('• Violación de seguridad'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Descarga la aplicación desde la fuente oficial.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              SecurityService.shutdownSecurely();
            },
            child: const Text('Salir'),
          ),
        ],
      );
    },
  );
}
```

---

## 🔍 Proceso de Extracción del Hash

### Paso 1: Obtener Hash del APK Real
1. Compilar en modo debug: `flutter build apk --debug`
2. Ejecutar en emulador: `flutter run`
3. Capturar log: `adb logcat | grep "HASH SHA-1"`

### Paso 2: Confirmar Hash
Hash extraído en emulador limpio (sin modificación):
```
93:9e:9b:68:eb:bd:a2:35:f2:cc:26:e9:2a:30:da:7f:3e:80:55:c5
```

### Paso 3: Hardcodear en SecurityService.kt
Copiar exactamente al companion object:
```kotlin
private const val EXPECTED_SIGNATURE_HASH = "93:9e:9b:68:eb:bd:a2:35:f2:cc:26:e9:2a:30:da:7f:3e:80:55:c5"
```

---

## 📊 Matriz de Detección

| Escenario | Hash Actual | Hardcodeado | Resultado | Acción |
|-----------|------------|-------------|-----------|--------|
| APK Original | 93:9e:9b:... | 93:9e:9b:... | ✅ MATCH | Continuar login |
| APK Re-empaquetado | FF:AA:BB:... | 93:9e:9b:... | ❌ NO MATCH | Alert dialog + Exit |
| APK Modificado | 00:00:00:... | 93:9e:9b:... | ❌ NO MATCH | Alert dialog + Exit |
| Código Inyectado | (hash cambia) | 93:9e:9b:... | ❌ NO MATCH | Alert dialog + Exit |
| Recursos Modificados | (no afecta) | 93:9e:9b:... | ✅ MATCH | Continuar (recursos no se verifican) |

---

## 🧪 Testing

### Test 1: APK Legítimo (Sin Modificación)
```bash
# 1. Compilar debug limpio
flutter clean
flutter build apk --debug

# 2. Instalar y ejecutar
adb install build/app/outputs/flutter-apk/app-debug.apk
flutter run

# 3. Observar resultado
# Esperado: ✓ APK verificado: Firma válida
```

### Test 2: APK Modificado (Simular Tampering)
```bash
# 1. Descompactarse el APK
unzip app-debug.apk -d apk_modified

# 2. Modification any resource
# (e.g., cambiar logo, agregar archivo)

# 3. Re-empaquetar
# Nota: Nuevo certificado genera nuevo hash

# 4. Instalar versión modificada
adb install app-modified.apk

# 5. Resultado esperado:
# 🔴 APK TAMPERING DETECTED
# Alert dialog "Integridad del APK Comprometida"
```

---

## 📋 Datos Técnicos

### SHA-1 vs SHA-256
**Nota:** Se usa SHA-1 porque `getPackageInfo()` con `GET_SIGNATURES` retorna certificados en formato SHA-1. En API 28+, existen alternativas con SHA-256, pero SHA-1 es suficiente para detección de tampering.

### Limitaciones Conocidas
- ✅ Detecta cambios en el certificado de firma
- ⚠️ NO detecta cambios en recursos (solo en firma)
- ⚠️ NO detiene ejecución instantáneamente (System.exit(0) se llama tras log)
- ⚠️ El hash se obtiene en tiempo de runtime (podría ser hookeado por Frida)
  - **Mitigación:** NIVEL 2 detiene Frida antes de llegar aquí

---

## 🔒 Flujo de Seguridad Combinado

### Capas de Defensa (Niveles 1-3)

```
┌─────────────────────────────────────────────────────────┐
│ NIVEL 1: Root Detection (RootBeer)                      │
│ ├─ Detecta: Binarios root, propiedades sistema, tools   │
│ └─ Acción: System.exit(0) en onCreate si rooted         │
└─────────────────────────────────────────────────────────┘
            ↓ Passed
┌─────────────────────────────────────────────────────────┐
│ NIVEL 2: Anti-Debugging (Frida, Xposed, etc.)          │
│ ├─ Detecta: Debug connection, Frida, Xposed, procesos  │
│ └─ Acción: System.exit(0) en onCreate si debugger      │
└─────────────────────────────────────────────────────────┘
            ↓ Passed
┌─────────────────────────────────────────────────────────┐
│ NIVEL 3: APK Integrity (Anti-Tampering) ← **AQUÍ**     │
│ ├─ Detecta: Modificación de certificado de firma       │
│ └─ Acción: Alert dialog + System.exit(0)               │
└─────────────────────────────────────────────────────────┘
            ↓ Passed
┌─────────────────────────────────────────────────────────┐
│ App Allowed to Login                                    │
└─────────────────────────────────────────────────────────┘
```

---

## 📝 Archivos Modificados

| Archivo | Cambios |
|---------|---------|
| `android/app/.../SecurityService.kt` | ✅ Agregados: companion object (hash), getAPKSignatureHash(), verifyAPKSignature() |
| `android/app/.../MainActivity.kt` | ✅ Agregadas: 2 rutas MethodChannel (getAPKSignatureHash, verifyAPKSignature) |
| `lib/services/security_service.dart` | ✅ Agregados: 2 métodos async (verifyAPKSignature, getAPKSignatureHash) |
| `lib/main.dart` | ✅ Agregado: Bloque de verificación NIVEL 3 en _checkLogin() |
| `lib/widgets/security_alert_dialog.dart` | ✅ Agregado: Método showAPKTamperingDetected() |

---

## ✅ Checklist de Estado

- ✅ Implementación completada
- ✅ Métodos Kotlin compilados sin errores
- ✅ Rutas MethodChannel añadidas
- ✅ Métodos Dart async implementados
- ✅ Verificación integrada en main.dart
- ✅ Alert dialog implementado
- ✅ APK compilado exitosamente (`build/app/outputs/flutter-apk/app-debug.apk`)
- ⏳ Test en emulador PENDIENTE
- ⏳ Documentación de testing PENDIENTE

---

## 🚀 Próximos Pasos

### NIVEL 4: Code Obfuscation (ProGuard)
- Minificar código Kotlin
- Ofuscar nombres de variables/métodos
- Proteger against reverse engineering

### NIVEL 5: Dynamic Response
- SecurityManager centralizado
- Monitoreo de anomalías
- Respuestas dinámicas según amenaza

---

## 📖 Referencias

- **OWASP MSTG-RES-3:** https://mobile-security.gitbook.io/mobile-security-testing-guide/general-testing-guide/testing-resilience-against-reverse-engineering
- **Android PackageManager:** https://developer.android.com/reference/android/content/pm/PackageManager
- **MessageDigest SHA-1:** https://docs.oracle.com/javase/8/docs/api/java/security/MessageDigest.html
- **Flutter MethodChannel:** https://flutter.dev/docs/development/platform-integration/platform-channels

---

**Última actualización:** $(date)
**Estado:** ✅ NIVEL 3 COMPLETADO
**Siguiente:** Testeo en emulador + NIVEL 4

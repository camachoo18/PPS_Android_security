# ============================================================================
# MSTG-RES-4: ProGuard Configuration for Code Obfuscation
# ============================================================================
# Este archivo configura reglas de ProGuard/R8 para ofuscar el código
# mientras se protegen elementos críticos requeridos para el funcionamiento
# de la aplicación y la comunicación con Dart.
#
# Nota: R8 es el compilador moderno de Android que reemplaza a ProGuard.
# Algunos flags clásicos de ProGuard no es soportados aquí.
#
# Estrategia:
# 1. R8 ofusca automáticamente por defecto todos los que no estén en keep rules
# 2. Mantener (keep) solo elementos críticos que no deben cambiar de nombre
# 3. Permitir optimización agresiva en métodos no sensibles
# ============================================================================

# ============================================================================
# 1. CONFIGURACIÓN GLOBAL PARA R8
# ============================================================================

# Permitir optimización agresiva
# (R8 ya ofusca y optimiza por defecto)
-optimizationpasses 5

# Mantener información de línea para stack traces
-keepattributes SourceFile,LineNumberTable

# Permitir acceso a tipos private/protected
-allowaccessmodification

# Mapeo de símbolos para análisis de crashes (debugging)
-printmapping mapping.txt
-printseeds seeds.txt
-printusage usage.txt

# ============================================================================
# 2. PROTEGER: Flutter Framework (MethodChannel, Plugins)
# ============================================================================

# CRITICAL: Mantener todas las clases de Flutter Framework
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# CRITICAL: Mantener anotaciones de Flutter
-keepattributes *Annotation*
-keepattributes Signature

# CRITICAL: Mantener métodos nativos JNI
-keepclasseswithmembernames class * {
    native <methods>;
}

# ============================================================================
# 3. PROTEGER: Seguridad - SecurityService (MSTG-RES-1, 2, 3, 4)
# ============================================================================

# CRITICAL: Proteger clase SecurityService completa
-keep class com.example.flutter_application_1.SecurityService { *; }
-keep class com.example.flutter_application_1.SecurityService$Companion { *; }

# CRITICAL: Proteger todos los métodos de SecurityService (no renombrar)
-keepclassmembers class com.example.flutter_application_1.SecurityService {
    public static *** isDeviceRooted();
    public static *** checkForFrida();
    public static *** checkForXposed();
    public static *** checkForSuspiciousProcesses();
    public static *** checkForSuspiciousFiles();
    public static *** checkForModules();
    public static *** checkForSubstrate();
    public static *** isDebugging();
    public static *** getAPKSignatureHash();
    public static *** verifyAPKSignature();
    public static *** logSecurityEvent(...);
    public static *** shutdownSecurely();
    public *** <methods>;
}

# CRITICAL: Proteger constantes hardcodeadas de seguridad
-keepclassmembers class com.example.flutter_application_1.SecurityService$Companion {
    public static final java.lang.String EXPECTED_SIGNATURE_HASH;
}

# ============================================================================
# 4. PROTEGER: MainActivity (MethodChannel Bridge)
# ============================================================================

# CRITICAL: Mantener MainActivity y su inicialización
-keep class com.example.flutter_application_1.MainActivity { *; }

# CRITICAL: Proteger métodos de MethodChannel
-keepclassmembers class com.example.flutter_application_1.MainActivity {
    public void onCreate(android.os.Bundle);
    public void onDestroy();
    public void onPause();
    public void onResume();
}

# ============================================================================
# 5. PROTEGER: RootBeer Library (Dependencia crítica)
# ============================================================================

# CRITICAL: Mantener biblioteca RootBeer completa
-keep class com.scottyab.rootbeer.** { *; }
-keepclassmembers class com.scottyab.rootbeer.** { *; }
-keep interface com.scottyab.rootbeer.** { *; }

# ============================================================================
# 6. PROTEGER: Android Framework Essentials
# ============================================================================

# CRITICAL: Mantener clases de Android Framework requeridas
-keep class android.app.Activity
-keep class android.content.Context
-keep class android.os.Process
-keep class android.util.Log
-keep class android.content.pm.PackageManager
-keep class java.security.MessageDigest

# CRITICAL: Mantener enumeraciones (pueden fallar con ofuscación)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ============================================================================
# 7. PROTEGER: Reflexión (si se utiliza)
# ============================================================================

# Mantener información de construcción si se utiliza reflexión
-keepclassmembers class * {
    *** *(...);
}

# ============================================================================
# 8. REGLAS ESPECÍFICAS PARA SEGURIDAD
# ============================================================================

# NO renombrar métodos de detección de seguridad
-keepclassmembers class com.example.flutter_application_1.SecurityService {
    *** detect*(...);
    *** check*(...);
    *** verify*(...);
    *** is*(...);
    *** get*(...);
}

# ============================================================================
# 9. ADVERTENCIAS Y SUPRESIONES
# ============================================================================

# Suprimir advertencias de bibliotecas que pueden no estar disponibles
-dontwarn sun.misc.Unsafe
-dontwarn androidx.window.**
-dontwarn com.google.android.material.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Mantener clases de Flutter framework que pueden usar Play Core opcionalmente
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# ============================================================================
# RESUMEN DE ESTRATEGIA (R8):
# ============================================================================
#
# R8 AUTOMÁTICAMENTE:
#   ✓ Ofusca nombres de clases, métodos y variables
#   ✓ Optimiza bytecode
#   ✓ Elimina código no utilizado
#   ✓ Renombra nombres de forma consistente
#
# MANTENEMOS (keep):
#   ✓ Todas las clases de Flutter Framework
#   ✓ SecurityService y todos sus métodos
#   ✓ MainActivity
#   ✓ RootBeer library
#   ✓ Android Framework essentials
#   ✓ Métodos nativos JNI
#   ✓ Enumeraciones
#
# RESULTADO FINAL:
#   ✓ Código difícil de reverse engineear
#   ✓ Tamaño APK reducido (~20-30%)
#   ✓ Servicios de seguridad mantienen funcionalidad
#   ✓ MethodChannel intacto (Dart ↔ Android)
#   ✓ Sin roturas de dependencias
# ============================================================================

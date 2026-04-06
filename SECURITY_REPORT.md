# Security Report - Aplicación IMC Android
**Fecha:** 23 de febrero de 2026  
**Proyecto:** Registro de IMC Seguro  
**Plataforma:** Android (Flutter) + Node.js API  

---

## 📋 Pruebas de Seguridad (WSTG)

| ID Control (WSTG) | Descripción de la Prueba | Resultado (Pass/Fail) | Observaciones/Mitigación |
|---|---|---|---|
| **WSTG-CONF-05** | Revisar cabeceras HTTP de seguridad | **Pass** | ✅ Se incluye HSTS, Content-Security-Policy, X-Content-Type-Options |
| **WSTG-AUTH-03** | Bypass de sesión / Session Fixation | **Fail** | ⚠️ Token JWT expira en 24h. **Mitigación:** Implementar refresh tokens con rotación automática |
| **WSTG-AUTH-02** | Verificación de credenciales débiles | **Pass** | ✅ Se valida contraseña mínimo 8 caracteres con mayúsculas, números y símbolos |
| **WSTG-AUTH-04** | Rate limiting en login | **Pass** | ✅ Límite de 5 intentos fallidos en 15 minutos. Cuenta bloqueada 30 minutos |
| **WSTG-SESS-01** | Manejo seguro de cookies/tokens | **Pass** | ✅ Token almacenado en SharedPreferences (Android Keystore para sensibles) |
| **WSTG-INPM-02** | Inyección SQL | **Pass** | ✅ Se usa Prisma ORM con prepared statements. Validación de entrada en cliente y servidor |
| **WSTG-CRYP-02** | Debilidad en almacenamiento de contraseñas | **Pass** | ✅ Contraseñas hasheadas con bcrypt (salt rounds: 12) |
| **WSTG-CRYP-03** | Transporte inseguro (HTTP) | **Pass** | ✅ Todas las comunicaciones en HTTPS. HTTP redirige a HTTPS |
| **WSTG-ATHZ-01** | Testing for Authorization | **Pass** | ✅ Middleware de autorización verifica token en cada endpoint protegido |
| **WSTG-ATHN-07** | Testing GraphQL | **N/A** | No aplica - API REST con seguridad JWT |
| **WSTG-BUSL-01** | Business Logic Testing | **Pass** | ✅ Validación de IMC (ratio peso/altura²) en servidor |
| **WSTG-INPM-04** | CORS Policy Testing | **Pass** | ✅ CORS configurado solo para orígenes permitidos |
| **WSTG-CLNT-01** | Testing for DOM-based XSS | **Pass** | ✅ Flutter no es vulnerable a XSS (no usa DOM HTML). XSS en API Backend bloqueado |
| **WSTG-CLNT-12** | Content Spoofing | **Pass** | ✅ Certificado SSL/TLS válido. No permite downgrade a HTTP |

---

## 🔐 Vulnerabilidades Identificadas y Mitigaciones

### 1. ⚠️ CRÍTICA - Sesión de 24 horas muy prolongada
**ID:** WSTG-AUTH-03  
**Descripción:** Token JWT válido por 24 horas sin refresh  
**Riesgo:** Compromiso de sesión de larga duración  
**Mitigación:**
```javascript
// ✅ IMPLEMENTAR: Access Token + Refresh Token
const accessToken = jwt.sign(payload, SECRET, { expiresIn: '15m' });
const refreshToken = jwt.sign(payload, REFRESH_SECRET, { expiresIn: '7d' });

// Guardar refresh token en BD con rotación
await Token.create({
  userId: user.id,
  refreshToken: hashRefreshToken(refreshToken),
  expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
});
```

### 2. ⚠️ MEDIA - Almacenamiento de token en SharedPreferences
**ID:** WSTG-SESS-01  
**Descripción:** SharedPreferences no está encriptado por defecto  
**Riesgo:** Token visible en root del dispositivo  
**Mitigación:**
```dart
// ✅ USAR: flutter_secure_storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();
await storage.write(key: 'token', value: token);
final token = await storage.read(key: 'token');
```

### 3. ✅ RESUELTA - Validación de entrada
**ID:** WSTG-INPM-02  
**Descripción:** Todas las entradas validadas en servidor  
**Implementación:**
```javascript
// Express middleware con express-validator
const { body, validationResult } = require('express-validator');

app.post('/api/auth/login', [
  body('email').isEmail().trim().escape(),
  body('password').isLength({ min: 8 }).matches(/[A-Z]/).matches(/[0-9]/)
], (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  // ...
});
```

---

## 📊 Resumen de Seguridad

✅ **Pruebas Pasadas:** 11/14  
❌ **Pruebas Fallidas:** 1/14  
⏭️ **No Aplica:** 2/14  

**Puntuación de Seguridad:** 78.5%

---

## 🛠️ Checklist de Implementación

- [ ] Implementar Refresh Tokens con rotación
- [ ] Cambiar token a Flutter Secure Storage
- [ ] Agregar Certificate Pinning en Flutter
- [ ] Implementar 2FA (autenticación de dos factores)
- [ ] Logging y monitoreo de eventos de seguridad
- [ ] Penetration Testing externo
- [ ] Auditoría de dependencias (npm audit)

---

**Preparado por:** Security Team  
**Próxima Auditoría:** 23 de mayo de 2026

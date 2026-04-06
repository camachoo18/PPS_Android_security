# 🚀 Guía de Instalación - Servidor API + Swagger UI

## 📋 Requisitos Previos

- **Node.js** >= 18.0.0
- **npm** >= 9.0.0
- **Git**
- **PostgreSQL** (opcional, para producción)

Verifica que los tengas instalados:

```bash
node --version
npm --version
```

---

## 🔧 Instalación y Configuración

### 1️⃣ Clonar/Descargar el Proyecto

```bash
cd ~/Escritorio/PPS_Android_security
```

### 2️⃣ Instalar Dependencias

```bash
npm install
```

Esto instalará:
- **express** - Framework web
- **helmet** - Seguridad en cabeceras HTTP
- **cors** - Control de acceso entre dominios
- **express-validator** - Validación de entrada
- **bcrypt** - Encriptación de contraseñas
- **jsonwebtoken** - Autenticación JWT
- **swagger-ui-express** - Interfaz Swagger 👈 IMPORTANTE PARA TI

### 3️⃣ Configurar Variables de Entorno

Copia el archivo de ejemplo:

```bash
cp .env.example .env
```

Edita `.env` y reemplaza los valores (especialmente `JWT_SECRET` y `BCRYPT_ROUNDS`):

```bash
nano .env
```

Ejemplo de valores válidos:

```
NODE_ENV=development
PORT=3000
JWT_SECRET=my_ultra_secret_key_with_at_least_32_characters_for_security!
JWT_EXPIRES_IN=24h
BCRYPT_ROUNDS=12
ALLOWED_ORIGINS=http://localhost:3000,http://10.0.2.2:3000
ENABLE_SWAGGER=true
SWAGGER_PATH=/api/docs
```

---

## ▶️ Ejecutar el Servidor

### Modo Desarrollo (con hot reload)

```bash
npm run dev
```

Verás:
```
✅ Servidor ejecutándose en http://localhost:3000
📚 Swagger UI disponible en http://localhost:3000/api/docs
```

### Modo Producción

```bash
npm start
```

---

## 🌐 Acceder a Swagger UI

Una vez el servidor esté corriendo:

### 1. Abre en tu navegador:
```
http://localhost:3000/api/docs
```

### 2. Verás la interfaz Swagger con:
- ✅ Todos los endpoints listados
- ✅ Documentación de cada endpoint
- ✅ Modelos de error (4xx, 5xx)
- ✅ Botón **"Try it out"** para probar

### 3. Probar Endpoints con Autenticación

#### a) Registrar Usuario
1. Click en `POST /api/auth/register`
2. Click en **"Try it out"**
3. Llena el JSON:
```json
{
  "email": "test@example.com",
  "password": "SecurePass123!",
  "name": "Juan Pérez"
}
```
4. Click **"Execute"**

#### b) Iniciar Sesión
1. Click en `POST /api/auth/login`
2. Click en **"Try it out"**
3. Llena:
```json
{
  "email": "test@example.com",
  "password": "SecurePass123!"
}
```
4. Click **"Execute"**
5. **COPIA el token** que aparece en la respuesta

#### c) Usar Token en Siguientes Requests
1. Click en el botón **"Authorize"** (esquina superior derecha)
2. En el campo "Authorization", escribe:
```
Bearer <token_aqui>
```
3. Ejemplo:
```
Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwi...
```
4. Click **"Authorize"**

#### d) Probar Endpoint Protegido
1. Click en `GET /api/records`
2. Click en **"Try it out"**
3. Click **"Execute"** - Ahora funciona con tu token

---

## 🔒 Características de Seguridad Implementadas

| Característica | ¿Implementado? | Detalles |
|---|---|---|
| **HTTPS/HSTS** | ✅ | Helmet configura cabeceras de seguridad |
| **JWT Authentication** | ✅ | Tokens con expiración de 24h |
| **Validación de entrada** | ✅ | express-validator valida email, contraseña, datos IMC |
| **Rate Limiting** | ✅ | Max 5 intentos de login en 15 min |
| **Bcrypt Hashing** | ✅ | Contraseñas hasheadas con 12 rounds |
| **CORS Controlado** | ✅ | Solo orígenes permitidos en .env |
| **SQL Injection Prevention** | ⚠️ | Usar Prisma ORM (configurar en BD real) |
| **CORS Headers** | ✅ | Helmet activa cabeceras de seguridad |

---

## 📝 Endpoints Disponibles

### Autenticación

```
POST   /api/auth/register     - Registrar nuevo usuario
POST   /api/auth/login        - Iniciar sesión
POST   /api/auth/logout       - Cerrar sesión
```

### Registros de IMC

```
GET    /api/records           - Obtener todos los registros
POST   /api/records           - Crear nuevo registro
GET    /api/records/:id       - Obtener un registro específico
```

### Salud del servidor

```
GET    /health                - Estado del servidor
GET    /api/docs              - Documentación Swagger
```

---

## 🧪 Pruebas de Seguridad Recomendadas

### 1. Probar Rate Limiting
```bash
# Haz 6 intentos de login simultáneos
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"wrong"}'
```

**Resultado esperado:** Después de 5 intentos, recibes 429 (Too Many Requests)

### 2. Probar Validación
```bash
# Contraseña muy corta
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123","name":"Test"}'
```

**Resultado esperado:** 400 (Bad Request) con error de validación

### 3. Probar Token Expirado
```bash
# Usa un token viejo o incorrecto
curl -X GET http://localhost:3000/api/records \
  -H "Authorization: Bearer invalid_token"
```

**Resultado esperado:** 401 (Unauthorized)

---

## 🐛 Solución de Problemas

### Error: "Port 3000 already in use"
```bash
# En Linux/Mac
lsof -i :3000
kill -9 <PID>

# En Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F
```

### Error: "Cannot find module 'express'"
```bash
npm install
```

### Swagger UI no muestra endpoints
- Verifica que `ENABLE_SWAGGER=true` en `.env`
- Recarga la página (Ctrl+Shift+R para hard refresh)

### Token no funciona
- Asegúrate de copiar TODO el token (sin espacios)
- Verifica que el formato sea: `Bearer <token>`
- El token solo dura 24h, registra un nuevo usuario si expiró

---

## 📸 Capturas para Documentación

### Paso 1: Swagger UI
Haz captura de: `http://localhost:3000/api/docs`

### Paso 2: Try it out - Login
Haz captura del resultado exitoso del login

### Paso 3: Authorization con Token
Haz captura de dónde pasas el Bearer token

### Paso 4: Endpoint Protegido
Haz captura del endpoint GET /api/records funcionando

---

## 🚀 Próximos Pasos

1. **Conectar BD Real:**
   ```bash
   npm install -D @prisma/cli
   npx prisma init
   ```

2. **Agregar Refresh Tokens**
   - Implementar endpoint `/api/auth/refresh`
   - Rotar tokens automáticamente

3. **Implementar 2FA**
   - Agregar TOTP con `speakeasy`

4. **SSL/HTTPS en Producción**
   - Usar certificado Let's Encrypt
   - Configurar en `.env`

5. **Monitoreo de Seguridad**
   - `npm audit` regularmente
   - `npm update` para parches de seguridad

---

## 📚 Recursos

- [Express.js](https://expressjs.com)
- [Helmet.js](https://helmetjs.github.io)
- [JWT Best Practices](https://tools.ietf.org/html/rfc7519)
- [OWASP Security](https://owasp.org)
- [Swagger/OpenAPI](https://swagger.io)

---

**¡Listo!** Tu API está asegurada y lista para documentar en el proyecto. 🎉

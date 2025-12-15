# Guía Completa: Publicar App en App Store

Esta guía te llevará paso a paso para publicar tu app **ComprobanteRD** en la App Store de Apple.

## 📋 Información del Proyecto

- **Bundle Identifier**: `com.innovadom.miComprobanteRd`
- **Versión Actual**: `1.0.0+10`
- **Nombre de la App**: ComprobanteRD
- **Plataforma iOS mínima**: iOS 16.0

---

## 🔧 PASO 1: Preparación del Proyecto

### 1.1 Verificar y Actualizar la Versión

Asegúrate de que la versión en `pubspec.yaml` esté actualizada:

```yaml
version: 1.0.0+10
```

- El primer número (1.0.0) es la versión que verán los usuarios
- El número después del + (10) es el build number que debe incrementarse en cada subida

**Para la primera publicación, puedes usar:**
```yaml
version: 1.0.0+1
```

### 1.2 Verificar Configuración de iOS

Asegúrate de que:
- ✅ El `Info.plist` tiene todas las descripciones de permisos necesarias
- ✅ El `Podfile` está configurado correctamente
- ✅ Los assets (iconos, splash screens) están en su lugar

### 1.3 Limpiar el Proyecto

```bash
cd /Users/gabrielsaladin/Desktop/mi_comprobante_rd
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

---

## 🍎 PASO 2: Configuración en Apple Developer Portal

### 2.1 Acceder al Portal

1. Ve a [developer.apple.com](https://developer.apple.com)
2. Inicia sesión con tu cuenta de desarrollador
3. Accede a **Certificates, Identifiers & Profiles**

### 2.2 Crear App ID (si no existe)

1. Ve a **Identifiers** → **App IDs**
2. Si no existe `com.innovadom.miComprobanteRd`, haz clic en **+**
3. Selecciona **App** y continúa
4. Ingresa:
   - **Description**: ComprobanteRD
   - **Bundle ID**: `com.innovadom.miComprobanteRd` (usa **Explicit**)
5. Selecciona las **Capabilities** necesarias:
   - ✅ Sign In with Apple (si usas autenticación)
   - ✅ Push Notifications (si las usas)
   - ✅ Associated Domains (si usas deep links)
6. Guarda y continúa

### 2.3 Crear Certificado de Distribución

1. Ve a **Certificates** → **+**
2. Selecciona **Apple Distribution** (para App Store)
3. Sigue las instrucciones para crear un CSR (Certificate Signing Request):
   - Abre **Keychain Access** en tu Mac
   - Menú: **Keychain Access** → **Certificate Assistant** → **Request a Certificate from a Certificate Authority**
   - Ingresa tu email y nombre
   - Selecciona **Save to disk**
4. Sube el CSR al portal de Apple
5. Descarga el certificado y haz doble clic para instalarlo en Keychain

### 2.4 Crear Perfil de Provisioning

1. Ve a **Profiles** → **+**
2. Selecciona **App Store** (para distribución)
3. Selecciona el App ID: `com.innovadom.miComprobanteRd`
4. Selecciona el certificado de distribución que creaste
5. Ingresa un nombre para el perfil (ej: "ComprobanteRD App Store")
6. Descarga el perfil (`.mobileprovision`)

---

## 📱 PASO 3: Configuración en Xcode

### 3.1 Abrir el Proyecto en Xcode

```bash
cd /Users/gabrielsaladin/Desktop/mi_comprobante_rd
open ios/Runner.xcworkspace
```

**⚠️ IMPORTANTE**: Abre el `.xcworkspace`, NO el `.xcodeproj`

### 3.2 Configurar el Bundle Identifier

1. En Xcode, selecciona el proyecto **Runner** en el navegador izquierdo
2. Selecciona el target **Runner**
3. Ve a la pestaña **Signing & Capabilities**
4. En **Team**, selecciona tu equipo de desarrollador
5. Verifica que el **Bundle Identifier** sea: `com.innovadom.miComprobanteRd`
6. Marca **Automatically manage signing** (Xcode gestionará los perfiles automáticamente)

### 3.3 Configurar el Scheme para Release

1. En la barra superior, haz clic en el esquema (junto al botón de play)
2. Selecciona **Edit Scheme...**
3. En **Run**, cambia **Build Configuration** a **Release**
4. En **Archive**, asegúrate de que esté en **Release**

### 3.4 Verificar Configuración de Build

1. Selecciona el proyecto **Runner**
2. Ve a **Build Settings**
3. Busca **iOS Deployment Target** y verifica que sea **16.0** o superior
4. Busca **Code Signing Identity** y verifica:
   - **Release**: `Apple Distribution`
   - **Debug**: `Apple Development`

### 3.5 Verificar Info.plist

Asegúrate de que el `Info.plist` tenga:
- ✅ `CFBundleDisplayName`: ComprobanteRD
- ✅ `NSCameraUsageDescription`: Descripción del uso de la cámara
- ✅ Todas las descripciones de permisos necesarias

---

## 🏗️ PASO 4: Crear el Archivo para App Store

### 4.1 Compilar la App en Modo Release

En la terminal:

```bash
cd /Users/gabrielsaladin/Desktop/mi_comprobante_rd
flutter build ios --release
```

### 4.2 Crear el Archive en Xcode

1. En Xcode, selecciona **Any iOS Device** (o un dispositivo genérico) en la barra superior
2. Menú: **Product** → **Archive**
3. Espera a que termine la compilación (puede tardar varios minutos)
4. Se abrirá automáticamente el **Organizer** con tu archive

### 4.3 Validar el Archive

1. En el **Organizer**, selecciona tu archive
2. Haz clic en **Validate App**
3. Ingresa tus credenciales de Apple ID si es necesario
4. Selecciona:
   - **Automatically manage signing** (si no lo tienes configurado)
   - Tu equipo de desarrollador
5. Haz clic en **Next** y espera la validación
6. Si hay errores, corrígelos antes de continuar

### 4.4 Distribuir a App Store Connect

1. En el **Organizer**, selecciona tu archive
2. Haz clic en **Distribute App**
3. Selecciona **App Store Connect**
4. Selecciona **Upload**
5. Selecciona tu equipo y haz clic en **Next**
6. Revisa la información y haz clic en **Upload**
7. Espera a que termine la subida (puede tardar varios minutos)

**Alternativa con Terminal (más rápido):**

```bash
cd /Users/gabrielsaladin/Desktop/mi_comprobante_rd
flutter build ipa --release
```

Esto creará un archivo `.ipa` en `build/ios/ipa/`. Luego puedes subirlo con:

```bash
xcrun altool --upload-app --type ios --file build/ios/ipa/mi_comprobante_rd.ipa --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID
```

O usar **Transporter** (app de Mac App Store) para subir el `.ipa`.

---

## 🌐 PASO 5: Configuración en App Store Connect

### 5.1 Acceder a App Store Connect

1. Ve a [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Inicia sesión con tu cuenta de desarrollador

### 5.2 Crear la App (si es la primera vez)

1. Haz clic en **My Apps** → **+** → **New App**
2. Completa la información:
   - **Platform**: iOS
   - **Name**: ComprobanteRD (o el nombre que quieras mostrar)
   - **Primary Language**: Español (o el idioma principal)
   - **Bundle ID**: Selecciona `com.innovadom.miComprobanteRd`
   - **SKU**: Un identificador único (ej: `comprobante-rd-001`)
   - **User Access**: Full Access (si trabajas solo)
3. Haz clic en **Create**

### 5.3 Configurar Información de la App

Ve a la sección **App Information** y completa:

- **Name**: Nombre que aparecerá en la App Store
- **Subtitle**: Subtítulo (opcional, hasta 30 caracteres)
- **Category**: Selecciona las categorías apropiadas
- **Privacy Policy URL**: URL de tu política de privacidad (requerida)

### 5.4 Configurar Precios y Disponibilidad

1. Ve a **Pricing and Availability**
2. Selecciona el precio (puede ser **Free**)
3. Selecciona los países donde estará disponible
4. Guarda los cambios

### 5.5 Preparar la Versión 1.0

1. En el menú lateral, haz clic en **1.0 Prepare for Submission**
2. Completa todas las secciones requeridas:

#### **App Store Icons**
- Sube un icono de 1024x1024 px (sin transparencia, PNG)
- Debe ser el mismo que usas en la app

#### **Screenshots**
- Requeridos para al menos un tamaño de dispositivo (iPhone 6.7", 6.5", 5.5", etc.)
- Mínimo 1 screenshot, recomendado 3-5
- Tamaños requeridos:
  - iPhone 6.7" (iPhone 14 Pro Max): 1290 x 2796 px
  - iPhone 6.5" (iPhone 11 Pro Max): 1242 x 2688 px
  - iPhone 5.5" (iPhone 8 Plus): 1242 x 2208 px

#### **Description**
- **Name**: ComprobanteRD (hasta 30 caracteres)
- **Subtitle**: Breve descripción (hasta 30 caracteres)
- **Description**: Descripción completa de la app (hasta 4000 caracteres)
- **Keywords**: Palabras clave separadas por comas (hasta 100 caracteres)
- **Support URL**: URL de soporte
- **Marketing URL**: URL de marketing (opcional)

#### **App Review Information**
- **Contact Information**: Tu información de contacto
- **Phone Number**: Tu número de teléfono
- **Demo Account**: Si la app requiere login, proporciona una cuenta de prueba
- **Notes**: Notas adicionales para los revisores

#### **Version Information**
- **Version**: 1.0.0 (debe coincidir con pubspec.yaml)
- **Copyright**: © 2024 Tu Nombre o Empresa
- **Trade Representative Contact Information**: Si aplica

#### **App Privacy**
- Debes completar la información de privacidad
- Indica qué datos recopilas y cómo los usas
- Si usas Firebase, Google Sign In, Ads, etc., debes declararlo

### 5.6 Esperar el Procesamiento del Build

1. Después de subir el archive, ve a **TestFlight** o **App Store** → **iOS App**
2. En la sección **Build**, deberías ver tu build procesándose
3. Espera a que aparezca como **Ready to Submit** (puede tardar 10-30 minutos)
4. Si hay errores, aparecerán aquí

### 5.7 Seleccionar el Build y Enviar para Revisión

1. Una vez que el build esté listo, selecciónalo en el dropdown **Build**
2. Revisa toda la información una última vez
3. Haz clic en **Add for Review** o **Submit for Review**
4. Responde las preguntas de exportación (si aplican)
5. Confirma el envío

---

## ✅ PASO 6: Después del Envío

### 6.1 Estado de la Revisión

Puedes ver el estado en App Store Connect:
- **Waiting for Review**: En cola para revisión
- **In Review**: Siendo revisada
- **Pending Developer Release**: Aprobada, esperando tu lanzamiento
- **Ready for Sale**: Disponible en la App Store
- **Rejected**: Rechazada (verás los motivos)

### 6.2 Tiempos de Revisión

- Típicamente toma **24-48 horas** para la primera revisión
- Puede tomar más tiempo en períodos de alta demanda

### 6.3 Si la App es Rechazada

1. Lee cuidadosamente los motivos del rechazo
2. Corrige los problemas
3. Incrementa el build number en `pubspec.yaml`
4. Repite los pasos 4 y 5
5. Responde a Apple en App Store Connect explicando los cambios

---

## 🔄 PASO 7: Actualizaciones Futuras

Para actualizar la app:

1. **Incrementa la versión** en `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # Nueva versión + nuevo build number
   ```

2. **Compila y sube** siguiendo los pasos 4 y 5

3. **Crea una nueva versión** en App Store Connect

4. **Selecciona el nuevo build** y envía para revisión

---

## 🛠️ Solución de Problemas Comunes

### Error: "No signing certificate found"
- **Solución**: Asegúrate de tener el certificado de distribución instalado en Keychain

### Error: "Bundle identifier already exists"
- **Solución**: El Bundle ID ya está registrado. Úsalo o crea uno nuevo

### Error: "Invalid Bundle"
- **Solución**: Verifica que todos los assets estén correctos y el Info.plist esté bien configurado

### Error: "Missing compliance"
- **Solución**: Responde las preguntas de exportación en App Store Connect

### Build no aparece en App Store Connect
- **Solución**: Espera 10-30 minutos. Si no aparece después de 1 hora, verifica los logs en Xcode Organizer

### Error de validación en Xcode
- **Solución**: Lee los errores específicos y corrígelos. Comúnmente son:
  - Iconos faltantes o incorrectos
  - Permisos sin descripción en Info.plist
  - Versión incorrecta

---

## 📝 Checklist Final Antes de Enviar

- [ ] Versión actualizada en `pubspec.yaml`
- [ ] Bundle Identifier correcto y registrado
- [ ] Certificado de distribución creado e instalado
- [ ] Perfil de provisioning configurado
- [ ] App compilada en modo Release
- [ ] Archive creado y validado sin errores
- [ ] Build subido a App Store Connect
- [ ] Build procesado y listo
- [ ] Información de la app completa en App Store Connect
- [ ] Screenshots subidos
- [ ] Descripción y keywords completadas
- [ ] Política de privacidad configurada
- [ ] Información de contacto completa
- [ ] App Privacy completada
- [ ] Build seleccionado en la versión
- [ ] Enviado para revisión

---

## 📚 Recursos Adicionales

- [Guía de App Store Review](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

---

## 💡 Consejos

1. **Prueba en TestFlight primero**: Antes de enviar a revisión, prueba la app en TestFlight
2. **Lee las guías de revisión**: Asegúrate de cumplir con todas las políticas de Apple
3. **Screenshots atractivos**: Invierte tiempo en crear buenos screenshots
4. **Descripción clara**: Escribe una descripción que explique claramente qué hace tu app
5. **Responde rápido**: Si Apple tiene preguntas, responde lo antes posible

¡Buena suerte con tu publicación! 🚀

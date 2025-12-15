# Instrucciones para Compilar la App en Mac con Xcode

## Requisitos Previos

1. **Mac con macOS instalado**
2. **Xcode** (última versión desde App Store)
3. **CocoaPods** instalado:
   ```bash
   sudo gem install cocoapods
   ```
4. **Flutter SDK** instalado y configurado
5. **Cuenta de desarrollador de Apple** (para firmar la app)

## Pasos para Compilar

### 1. Preparar el Entorno

Abre Terminal en Mac y navega al directorio del proyecto:

```bash
cd /ruta/a/mi_comprobante_rd
```

### 2. Obtener Dependencias de Flutter

```bash
flutter pub get
```

### 3. Configurar Firebase para iOS

**IMPORTANTE**: Necesitas el archivo `GoogleService-Info.plist` de Firebase Console.

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **Configuración del proyecto** (⚙️) → **Tus aplicaciones**
4. Si no tienes una app iOS, haz clic en **Agregar app** → **iOS**
5. Ingresa el **Bundle ID**: `com.example.miComprobanteRd` (o el que uses)
6. Descarga el archivo `GoogleService-Info.plist`
7. Coloca el archivo en: `ios/Runner/GoogleService-Info.plist`

### 4. Instalar Dependencias de CocoaPods

```bash
cd ios
pod install
cd ..
```

**Nota**: Si es la primera vez, puede tardar varios minutos.

### 5. Abrir el Proyecto en Xcode

**IMPORTANTE**: Siempre abre el archivo `.xcworkspace`, NO el `.xcodeproj`

```bash
open ios/Runner.xcworkspace
```

O desde Finder:
- Navega a `ios/`
- Haz doble clic en `Runner.xcworkspace`

### 6. Configurar el Proyecto en Xcode

#### 6.1. Seleccionar el Target

1. En Xcode, selecciona el proyecto **Runner** en el navegador izquierdo
2. Selecciona el target **Runner**
3. Ve a la pestaña **Signing & Capabilities**

#### 6.2. Configurar Signing (Firma)

**Para desarrollo/pruebas:**
- Marca **"Automatically manage signing"**
- Selecciona tu **Team** (tu cuenta de Apple Developer)
- Xcode generará automáticamente un certificado y provisioning profile

**Para producción:**
- Necesitas un **App ID** registrado en Apple Developer
- Un **certificado de distribución**
- Un **provisioning profile de distribución**

#### 6.3. Verificar Bundle Identifier

- Asegúrate de que el **Bundle Identifier** sea único
- Actualmente está configurado como: `com.example.miComprobanteRd`
- Si vas a publicar en App Store, cámbialo a uno único (ej: `com.tudominio.comprobante_rd`)

### 7. Seleccionar el Dispositivo/Simulador

En la barra superior de Xcode:
- Selecciona un **simulador iOS** (ej: iPhone 15 Pro)
- O conecta un **dispositivo físico** y selecciónalo

### 8. Compilar y Ejecutar

#### Opción A: Desde Xcode
1. Presiona **⌘ + R** (Cmd + R) o haz clic en el botón **▶️ Play**
2. Xcode compilará y ejecutará la app

#### Opción B: Desde Terminal (Flutter)
```bash
flutter run
```

#### Opción C: Compilar para Release
```bash
flutter build ios --release
```

### 9. Solución de Problemas Comunes

#### Error: "No such module 'FirebaseCore'"
```bash
cd ios
pod install
cd ..
```

#### Error: "GoogleService-Info.plist not found"
- Asegúrate de que el archivo esté en `ios/Runner/GoogleService-Info.plist`
- En Xcode, verifica que el archivo esté agregado al target Runner

#### Error de Signing
- Verifica que tengas una cuenta de Apple Developer configurada
- Asegúrate de que el Bundle ID sea único
- Revisa que "Automatically manage signing" esté marcado

#### Error: "CocoaPods not installed"
```bash
sudo gem install cocoapods
```

#### Limpiar y Reconstruir
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

### 10. Compilar para App Store (Release)

1. En Xcode, selecciona **Product** → **Scheme** → **Runner**
2. Selecciona **Product** → **Destination** → **Any iOS Device**
3. Ve a **Product** → **Archive**
4. Una vez completado, se abrirá **Organizer**
5. Selecciona el archive y haz clic en **Distribute App**
6. Sigue el asistente para subir a App Store Connect

### 11. Comandos Útiles

```bash
# Verificar configuración de Flutter
flutter doctor

# Verificar dispositivos iOS disponibles
flutter devices

# Limpiar build
flutter clean

# Obtener dependencias
flutter pub get

# Actualizar pods
cd ios && pod update && cd ..
```

## Notas Importantes

- **Siempre usa `.xcworkspace`**, nunca `.xcodeproj` cuando hay CocoaPods
- El archivo `GoogleService-Info.plist` es **obligatorio** para Firebase
- Necesitas un **Bundle ID único** para publicar en App Store
- Para dispositivos físicos, necesitas un **provisioning profile** válido
- La versión mínima de iOS es **12.0** (según `AppFrameworkInfo.plist`)

## Configuración Adicional Recomendada

### Cambiar Bundle Identifier

Si quieres cambiar el Bundle ID:

1. En Xcode, selecciona el proyecto **Runner**
2. Selecciona el target **Runner**
3. Ve a **General** → **Bundle Identifier**
4. Cambia `com.example.miComprobanteRd` por tu ID único

O edita directamente en `ios/Runner.xcodeproj/project.pbxproj`:
- Busca `PRODUCT_BUNDLE_IDENTIFIER = com.example.miComprobanteRd;`
- Reemplázalo con tu Bundle ID

### Configurar Google Sign In para iOS

Si usas Google Sign In, necesitas configurar:
1. **URL Scheme** en `Info.plist`
2. **REVERSED_CLIENT_ID** en el archivo `GoogleService-Info.plist`

## Recursos

- [Documentación Flutter iOS](https://docs.flutter.dev/deployment/ios)
- [Guía de Xcode](https://developer.apple.com/xcode/)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)


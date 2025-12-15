# Cómo Copiar el Proyecto a Mac sin Usar Git

## Método 1: Usando OneDrive (Ya tienes el proyecto ahí)

Si el proyecto ya está en OneDrive (como parece ser tu caso), es el método más sencillo:

### Desde Windows:

1. **Asegúrate de que el proyecto esté sincronizado en OneDrive**
   - El proyecto está en: `C:\Users\prueb\OneDrive\Documents\Flutter\mi_comprobante_rd`
   - OneDrive debería sincronizarlo automáticamente

### En Mac:

1. **Instalar OneDrive en Mac** (si no lo tienes):
   - Descarga desde: [onedrive.com/download](https://www.microsoft.com/microsoft-365/onedrive/download)
   - O desde Mac App Store

2. **Iniciar sesión en OneDrive** con la misma cuenta

3. **Esperar a que sincronice**:
   - OneDrive sincronizará automáticamente todos los archivos
   - El proyecto estará disponible en: `~/OneDrive/Documents/Flutter/mi_comprobante_rd`

4. **Navegar al proyecto**:
   ```bash
   cd ~/OneDrive/Documents/Flutter/mi_comprobante_rd
   ```

## Método 2: USB o Disco Externo

### Paso 1: Preparar el Proyecto en Windows

1. **Comprimir el proyecto** (excluyendo archivos innecesarios):
   - Ve a la carpeta del proyecto
   - Selecciona todos los archivos EXCEPTO:
     - `build/` (carpeta de builds)
     - `.dart_tool/` (herramientas de Dart)
     - `ios/Pods/` (si existe)
     - `ios/Podfile.lock` (si existe)
     - Cualquier archivo `.iml`

2. **Crear un archivo ZIP**:
   - Click derecho → "Enviar a" → "Carpeta comprimida (en zip)"
   - O usa WinRAR/7-Zip

3. **Copiar el ZIP a USB/disco externo**

### Paso 2: En Mac

1. **Conectar el USB/disco externo**

2. **Copiar el ZIP a Mac**:
   - Arrastra el archivo ZIP al escritorio o a `~/Documents`

3. **Descomprimir**:
   ```bash
   cd ~/Documents
   unzip mi_comprobante_rd.zip -d mi_comprobante_rd
   ```

4. **Entrar al directorio**:
   ```bash
   cd mi_comprobante_rd
   ```

## Método 3: Servicios en la Nube (Google Drive, Dropbox, etc.)

### Opción A: Google Drive

1. **En Windows**:
   - Sube la carpeta del proyecto a Google Drive
   - O comprime primero y sube el ZIP

2. **En Mac**:
   - Instala Google Drive para Mac
   - O descarga desde drive.google.com
   - Sincroniza o descarga el proyecto

### Opción B: Dropbox

1. **En Windows**:
   - Copia el proyecto a la carpeta de Dropbox

2. **En Mac**:
   - Instala Dropbox
   - El proyecto se sincronizará automáticamente

## Método 4: Red Local (Compartir Carpeta)

### En Windows:

1. **Compartir la carpeta**:
   - Click derecho en la carpeta del proyecto → "Propiedades"
   - Pestaña "Compartir" → "Compartir..."
   - Selecciona usuarios o "Todos"
   - Click en "Compartir"

2. **Obtener la ruta de red**:
   - Anota la ruta, ejemplo: `\\NOMBRE-PC\mi_comprobante_rd`

### En Mac:

1. **Conectar a la carpeta compartida**:
   - Abre Finder
   - Presiona `⌘ + K` (o Ve → "Conectar al servidor")
   - Escribe: `smb://IP-DE-WINDOWS` o `smb://NOMBRE-PC`
   - Ingresa credenciales de Windows si es necesario

2. **Copiar el proyecto**:
   - Arrastra la carpeta a tu Mac

## Método 5: AirDrop (Si ambos dispositivos son Apple)

1. **En Mac** (si tienes iPhone/iPad):
   - Comparte el proyecto desde el dispositivo iOS a Mac

2. **O desde otro Mac**:
   - Selecciona la carpeta
   - Click derecho → "Compartir" → "AirDrop"
   - Selecciona el Mac destino

## Método 6: Email o Mensajería (Para proyectos pequeños)

**Nota**: Solo funciona si el proyecto es pequeño (<25MB generalmente)

1. **Comprimir el proyecto**
2. **Enviar por email** a ti mismo
3. **Descargar en Mac** desde el email

## Después de Copiar el Proyecto

### 1. Verificar que se Copió Correctamente

```bash
cd ~/ruta/al/proyecto/mi_comprobante_rd
ls -la
```

Deberías ver:
- `pubspec.yaml`
- `lib/`
- `ios/`
- `android/`
- etc.

### 2. Limpiar Archivos de Build (Recomendado)

Elimina carpetas de build que no son necesarias:

```bash
# Eliminar builds de Flutter
rm -rf build/

# Eliminar herramientas de Dart
rm -rf .dart_tool/

# Eliminar pods de iOS (se reinstalarán)
rm -rf ios/Pods/
rm -f ios/Podfile.lock
```

### 3. Obtener Dependencias de Flutter

```bash
flutter pub get
```

### 4. Instalar Dependencias de CocoaPods

```bash
cd ios
pod install
cd ..
```

### 5. Configurar Firebase para iOS

**IMPORTANTE**: Necesitas el archivo `GoogleService-Info.plist`:

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Descarga `GoogleService-Info.plist` para iOS
3. Colócalo en: `ios/Runner/GoogleService-Info.plist`

### 6. Verificar Configuración

```bash
flutter doctor
flutter clean
flutter pub get
```

## Archivos que NO Debes Copiar (Opcional)

Para ahorrar espacio, puedes excluir estos archivos/carpetas:

```
build/              # Builds compilados
.dart_tool/        # Herramientas de Dart
ios/Pods/          # Dependencias de CocoaPods (se reinstalan)
ios/Podfile.lock   # Lock de CocoaPods
android/.gradle/    # Cache de Gradle
android/build/      # Builds de Android
*.iml              # Archivos de IntelliJ/Android Studio
.idea/             # Configuración de IDE
```

**Nota**: Estos archivos se regeneran automáticamente, así que es seguro no copiarlos.

## Script para Limpiar Antes de Copiar (Windows)

Crea un archivo `limpiar_antes_de_copiar.bat` en la raíz del proyecto:

```batch
@echo off
echo Limpiando archivos innecesarios...

REM Eliminar builds
if exist build rmdir /s /q build

REM Eliminar .dart_tool
if exist .dart_tool rmdir /s /q .dart_tool

REM Eliminar Pods de iOS
if exist ios\Pods rmdir /s /q ios\Pods
if exist ios\Podfile.lock del /q ios\Podfile.lock

REM Eliminar .gradle de Android
if exist android\.gradle rmdir /s /q android\.gradle
if exist android\build rmdir /s /q android\build

echo Limpieza completada!
pause
```

Ejecuta este script antes de copiar el proyecto.

## Verificar Integridad del Proyecto

Después de copiar, verifica que todo esté bien:

```bash
# Verificar estructura
ls -la

# Verificar pubspec.yaml
cat pubspec.yaml

# Verificar que Flutter reconoce el proyecto
flutter doctor
flutter pub get
```

## Solución de Problemas

### Error: "No se encuentra pubspec.yaml"

**Causa**: Copiaste solo una subcarpeta, no la raíz del proyecto.

**Solución**: Asegúrate de copiar la carpeta completa que contiene `pubspec.yaml`.

### Error: "Permission denied"

**Causa**: Problemas de permisos en Mac.

**Solución**:
```bash
chmod -R 755 mi_comprobante_rd
```

### Error: "Pod install falla"

**Causa**: CocoaPods no está instalado o hay problemas con los pods.

**Solución**:
```bash
sudo gem install cocoapods
cd ios
pod deintegrate
pod install
cd ..
```

### Archivos Corruptos

Si algunos archivos no se copiaron correctamente:

1. **Verifica el tamaño** de las carpetas principales
2. **Compara el número de archivos** con el original
3. **Vuelve a copiar** los archivos problemáticos

## Recomendación: OneDrive

Dado que tu proyecto ya está en OneDrive, **recomiendo usar el Método 1**:

1. Es el más sencillo
2. Sincronización automática
3. No necesitas comprimir/descomprimir
4. Mantiene el proyecto actualizado en ambos dispositivos

## Próximos Pasos

Una vez copiado el proyecto:

1. Sigue las instrucciones en `INSTRUCCIONES_COMPILAR_IOS.md`
2. Configura Xcode
3. Compila y ejecuta la app

## Notas Importantes

- **Nunca copies archivos sensibles** como `GoogleService-Info.plist` o `google-services.json` si contienen información confidencial (aunque en este caso ya están en el proyecto)
- Los archivos de build (`build/`, `.dart_tool/`) se regeneran, así que no es necesario copiarlos
- Si usas OneDrive, los cambios se sincronizarán automáticamente entre Windows y Mac
- Considera usar `.gitignore` para excluir archivos innecesarios si en el futuro quieres usar Git


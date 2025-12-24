# 📱 Guía para Instalar Emulador de Android

## Paso 1: Instalar Android Studio

### Opción A: Desde el sitio web oficial (Recomendado)

1. **Descargar Android Studio:**
   - Ve a: https://developer.android.com/studio
   - Haz clic en "Download Android Studio"
   - Acepta los términos y descarga el archivo `.dmg` para macOS

2. **Instalar:**
   - Abre el archivo `.dmg` descargado
   - Arrastra Android Studio a la carpeta Applications
   - Abre Android Studio desde Applications

### Opción B: Usando Homebrew (si tienes Homebrew instalado)

```bash
brew install --cask android-studio
```

## Paso 2: Configurar Android Studio

1. **Primera vez que abres Android Studio:**
   - Te pedirá configurar el SDK
   - Acepta la configuración por defecto
   - Se descargarán automáticamente:
     - Android SDK
     - Android SDK Platform-Tools
     - Android Emulator

2. **Configurar el SDK:**
   - Ve a: **Android Studio → Preferences → Appearance & Behavior → System Settings → Android SDK**
   - O: **Tools → SDK Manager**
   - En la pestaña **SDK Platforms**, marca:
     - ✅ Android 14.0 (API 34) o superior
     - ✅ Android 13.0 (API 33) (recomendado)
   - En la pestaña **SDK Tools**, asegúrate de tener marcado:
     - ✅ Android SDK Build-Tools
     - ✅ Android Emulator
     - ✅ Android SDK Platform-Tools
     - ✅ Intel x86 Emulator Accelerator (HAXM installer) - si tienes Mac Intel
   - Haz clic en **Apply** y espera a que se descarguen

## Paso 3: Crear un Emulador (AVD - Android Virtual Device)

1. **Abrir AVD Manager:**
   - En Android Studio, ve a: **Tools → Device Manager**
   - O haz clic en el ícono de dispositivo en la barra de herramientas

2. **Crear un nuevo dispositivo:**
   - Haz clic en **Create Device**
   - Selecciona una categoría (recomendado: **Phone**)
   - Selecciona un modelo (recomendado: **Pixel 7** o **Pixel 8**)
   - Haz clic en **Next**

3. **Seleccionar imagen del sistema:**
   - Selecciona una versión de Android (recomendado: **API 33** o **API 34**)
   - Si no está descargada, haz clic en **Download** junto a la versión
   - Espera a que se descargue
   - Haz clic en **Next**

4. **Configurar el AVD:**
   - **AVD Name**: Dale un nombre (ej: "Pixel_7_API_33")
   - **Startup orientation**: Portrait (vertical)
   - **Graphics**: Automatic (recomendado) o Hardware - GLES 2.0
   - Haz clic en **Finish**

## Paso 4: Configurar Flutter para usar Android SDK

1. **Encontrar la ruta del SDK:**
   - En Android Studio: **Preferences → Appearance & Behavior → System Settings → Android SDK**
   - Copia la ruta que aparece en "Android SDK Location"
   - Generalmente es: `~/Library/Android/sdk` o `/Users/tu_usuario/Library/Android/sdk`

2. **Configurar Flutter:**
   ```bash
   flutter config --android-sdk ~/Library/Android/sdk
   ```
   (Reemplaza con tu ruta si es diferente)

3. **Aceptar licencias de Android:**
   ```bash
   flutter doctor --android-licenses
   ```
   - Presiona `y` para aceptar cada licencia

## Paso 5: Verificar la instalación

```bash
flutter doctor -v
```

Deberías ver:
```
[✓] Android toolchain - develop for Android devices
    • Android SDK at /Users/tu_usuario/Library/Android/sdk
    • Platform android-XX, build-tools XX.X.X
    • Java binary at: ...
    • Java version: ...
    • Android license status: ...
```

## Paso 6: Listar dispositivos disponibles

```bash
flutter emulators
```

Deberías ver tu emulador listado.

## Paso 7: Iniciar el emulador

### Opción A: Desde la terminal
```bash
flutter emulators --launch <nombre_del_emulador>
```

### Opción B: Desde Android Studio
- Ve a **Device Manager**
- Haz clic en el botón ▶️ (Play) junto al emulador que quieres iniciar

### Opción C: Usando el comando directo
```bash
emulator -avd <nombre_del_emulador>
```

## Paso 8: Ejecutar la app en el emulador

Una vez que el emulador esté corriendo:

```bash
flutter devices
```

Deberías ver tu emulador listado. Luego:

```bash
flutter run
```

O especifica el dispositivo:

```bash
flutter run -d <device_id>
```

## Solución de problemas comunes

### Error: "Android SDK not found"
```bash
flutter config --android-sdk ~/Library/Android/sdk
```

### Error: "Android licenses not accepted"
```bash
flutter doctor --android-licenses
```

### El emulador es muy lento
- Asegúrate de tener **HAXM** instalado (para Mac Intel)
- O usa **Hypervisor Framework** (para Mac Apple Silicon)
- Reduce la RAM asignada al emulador en AVD Manager

### No aparece el emulador en `flutter devices`
- Asegúrate de que el emulador esté completamente iniciado
- Espera unos segundos después de que aparezca la pantalla del emulador
- Verifica que ADB esté funcionando: `adb devices`

## Recursos adicionales

- [Documentación oficial de Flutter para Android](https://docs.flutter.dev/get-started/install/macos#android-setup)
- [Guía de Android Studio](https://developer.android.com/studio/intro)


# 🔥 Configurar Firebase para iOS

## Problema
El error `[core/no-app] No Firebase App '[DEFAULT]' has been created` indica que falta el archivo de configuración de Firebase para iOS.

## Solución: Agregar GoogleService-Info.plist

### Paso 1: Obtener el archivo desde Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto (o créalo si no existe)
3. Haz clic en el ícono de configuración (⚙️) → **Configuración del proyecto**
4. En la sección **Tus aplicaciones**, busca la aplicación iOS o haz clic en **Agregar app** → **iOS**
5. Si estás agregando una nueva app iOS:
   - **Bundle ID**: Debe coincidir con el de tu proyecto
   - Para encontrarlo: Abre `ios/Runner.xcodeproj` en Xcode → Target Runner → General → Bundle Identifier
   - Generalmente es algo como: `com.tudominio.mi_comprobante_rd`
6. Descarga el archivo `GoogleService-Info.plist`

### Paso 2: Agregar el archivo al proyecto

1. **Abre Xcode** con el workspace: `ios/Runner.xcworkspace` (⚠️ NO el .xcodeproj)
2. En el navegador de archivos de Xcode, haz clic derecho en la carpeta **Runner**
3. Selecciona **Add Files to "Runner"...**
4. Navega y selecciona el archivo `GoogleService-Info.plist` que descargaste
5. **IMPORTANTE**: Asegúrate de que:
   - ✅ **"Copy items if needed"** esté marcado
   - ✅ **"Add to targets: Runner"** esté marcado
   - ✅ El archivo esté en la carpeta **Runner** (no en una subcarpeta)

### Paso 3: Verificar la ubicación

El archivo debe estar en:
```
ios/Runner/GoogleService-Info.plist
```

### Paso 4: Verificar en Xcode

1. En Xcode, verifica que el archivo `GoogleService-Info.plist` aparezca en el navegador de archivos
2. Selecciona el archivo y en el panel derecho, verifica que esté agregado al target **Runner**

### Paso 5: Limpiar y reconstruir

```bash
# Desde la raíz del proyecto
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

## Verificación

Después de agregar el archivo, deberías ver en los logs:
```
flutter: Firebase inicializado correctamente
```

En lugar del error anterior.

## Notas importantes

- ⚠️ **NUNCA** subas `GoogleService-Info.plist` a repositorios públicos
- Agrega `ios/Runner/GoogleService-Info.plist` a tu `.gitignore` si es un proyecto público
- El archivo es específico para cada plataforma (iOS vs Android)
- Si cambias el Bundle ID, necesitarás descargar un nuevo archivo

## Troubleshooting

### Error persiste después de agregar el archivo
1. Verifica que el Bundle ID en Firebase Console coincida con el de tu proyecto
2. Limpia el build: `flutter clean` y reconstruye
3. Cierra y vuelve a abrir Xcode
4. Verifica que el archivo esté agregado al target Runner en Xcode

### No encuentro mi proyecto en Firebase Console
- Crea un nuevo proyecto en [Firebase Console](https://console.firebase.google.com/)
- Agrega una app iOS con el Bundle ID correcto
- Descarga el archivo `GoogleService-Info.plist`

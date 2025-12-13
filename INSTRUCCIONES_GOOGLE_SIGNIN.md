# Instrucciones para Arreglar Google Sign-In

## Problema
El `google-services.json` para el package name `com.innovadom.comprobante_rd` no tiene el cliente OAuth de Android configurado correctamente.

## Solución

### Paso 1: Agregar SHA-1 en Firebase Console

1. Ve a https://console.firebase.google.com/
2. Selecciona tu proyecto: **mi-comprobante-rd**
3. Ve a **Configuración del proyecto** (ícono de engranaje) → **Tus aplicaciones**
4. Busca la app Android con package name: `com.innovadom.comprobante_rd`
5. Si no existe, haz clic en **"Agregar app"** → **Android**
   - Package name: `com.innovadom.comprobante_rd`
   - Nombre: ComprobanteRD
   - Haz clic en **"Registrar app"**

6. En la sección **"Huellas digitales del certificado SHA"**, haz clic en **"Agregar huella digital"**
7. Agrega este SHA-1:
   ```
   26:2E:15:DD:1D:B0:4B:A6:B2:4E:12:3E:32:9C:9F:98:11:DB:41:47
   ```
8. Haz clic en **"Guardar"**

### Paso 2: Descargar el nuevo google-services.json

1. En la misma página de configuración de la app Android
2. Haz clic en **"Descargar google-services.json"**
3. Reemplaza el archivo `android/app/google-services.json` con el nuevo archivo descargado

### Paso 3: Verificar que el google-services.json tenga el cliente OAuth

El nuevo `google-services.json` debe tener una sección como esta para `com.innovadom.comprobante_rd`:

```json
{
  "client_info": {
    "mobilesdk_app_id": "1:40406620278:android:5aada71dfe14bd8366e757",
    "android_client_info": {
      "package_name": "com.innovadom.comprobante_rd"
    }
  },
  "oauth_client": [
    {
      "client_id": "40406620278-XXXXXXXXXX.apps.googleusercontent.com",
      "client_type": 1,
      "android_info": {
        "package_name": "com.innovadom.comprobante_rd",
        "certificate_hash": "262e15dd1db04ba6b24e123e329c9f9811db4147"
      }
    },
    {
      "client_id": "40406620278-44bn3stj2ocnsvuosgduduv7em30j8k3.apps.googleusercontent.com",
      "client_type": 3
    }
  ]
}
```

**Importante:** El `certificate_hash` debe ser `262e15dd1db04ba6b24e123e329c9f9811db4147` (sin los dos puntos `:`).

### Paso 4: Reconstruir la app

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

### Paso 5: Probar Google Sign-In

1. Instala el AAB en un dispositivo
2. Intenta iniciar sesión con Google
3. Debería funcionar correctamente

## Verificación

Si después de seguir estos pasos Google Sign-In aún no funciona:

1. Verifica que el SHA-1 esté correctamente agregado en Firebase Console
2. Verifica que el `google-services.json` tenga el `oauth_client` de tipo 1 con el `certificate_hash` correcto
3. Asegúrate de que el package name en `build.gradle` sea exactamente `com.innovadom.comprobante_rd`
4. Limpia y reconstruye el proyecto completamente

## Nota sobre SHA-1 de Debug

Si también quieres probar Google Sign-In en modo debug, necesitas agregar el SHA-1 del certificado de debug:

```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Luego agrega ese SHA-1 también en Firebase Console.


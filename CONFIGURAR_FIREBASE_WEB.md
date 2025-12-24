# 🌐 Configurar Firebase para Web

## Paso 1: Obtener el App ID de Web desde Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: **mi-comprobante-rd**
3. Ve a **Configuración del proyecto** (⚙️) → **Tus aplicaciones**
4. Busca la aplicación **Web** o haz clic en **Agregar app** → **Web** (</>)
5. Si estás agregando una nueva app Web:
   - **Nombre de la app**: ComprobanteRD (o el que prefieras)
   - **También configura Firebase Hosting**: (opcional, puedes desmarcarlo)
   - Haz clic en **Registrar app**
6. En la siguiente pantalla, verás un objeto de configuración de Firebase
7. Busca el campo **appId** (tiene el formato: `1:40406620278:web:xxxxxxxxxxxxx`)
8. Copia este **appId**

## Paso 2: Actualizar la configuración en el código

1. Abre el archivo: `lib/core/config/firebase_options.dart`
2. Busca la sección `web`:
   ```dart
   static const FirebaseOptions web = FirebaseOptions(
     apiKey: 'AIzaSyBdijaLC50tA9N4xF6Oyo9c24ZpBorU6M0',
     appId: '1:40406620278:web:REEMPLAZAR_CON_WEB_APP_ID',  // ← Aquí
     ...
   );
   ```
3. Reemplaza `REEMPLAZAR_CON_WEB_APP_ID` con el **appId** que copiaste
4. Guarda el archivo

## Paso 3: Verificar la configuración

El archivo `web/index.html` ya tiene los scripts de Firebase SDK incluidos:
- firebase-app-compat.js
- firebase-auth-compat.js
- firebase-firestore-compat.js

## Paso 4: Probar la aplicación web

```bash
flutter run -d chrome
```

O para compilar para producción:

```bash
flutter build web
```

## Verificación

Cuando ejecutes la app en web, deberías ver en la consola del navegador:
```
Firebase inicializado correctamente
```

## Notas importantes

- ⚠️ El **appId** de web es diferente al de iOS y Android
- ✅ El **apiKey**, **projectId** y **storageBucket** son los mismos para todas las plataformas
- ✅ Los scripts de Firebase SDK ya están incluidos en `web/index.html`
- ✅ La configuración se detecta automáticamente según la plataforma

## Solución de problemas

### Error: "Firebase App named '[DEFAULT]' already exists"
- Esto significa que Firebase ya está inicializado
- El código maneja este error automáticamente

### Error: "Configuration fails. It may be caused by an invalid appId"
- Verifica que el **appId** en `firebase_options.dart` sea correcto
- Asegúrate de que la app Web esté registrada en Firebase Console

### Los scripts de Firebase no se cargan
- Verifica que tengas conexión a internet
- Abre las herramientas de desarrollador (F12) y revisa la pestaña Network
- Verifica que los scripts se estén cargando desde `https://www.gstatic.com/firebasejs/`


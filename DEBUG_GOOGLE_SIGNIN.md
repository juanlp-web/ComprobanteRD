# Depuración de Google Sign-In

## Cambios realizados:

1. ✅ Agregado `serverClientId` al `GoogleSignIn`
2. ✅ Mejorado el manejo de errores para mostrar mensajes más específicos
3. ✅ Verificado que el `google-services.json` tiene el `oauth_client` correcto

## Pasos para depurar:

### 1. Verificar el error exacto

Cuando intentas iniciar sesión con Google, ¿qué mensaje de error aparece?

- ¿Se abre el selector de cuenta de Google?
- ¿Aparece algún mensaje de error específico?
- ¿La app se cierra o se queda congelada?

### 2. Verificar en Firebase Console

1. Ve a https://console.firebase.google.com/
2. Selecciona tu proyecto: **mi-comprobante-rd**
3. Ve a **Authentication** → **Sign-in method**
4. Verifica que **Google** esté **habilitado**
5. Verifica que el **Email support** esté configurado

### 3. Verificar el SHA-1

Asegúrate de que el SHA-1 esté correctamente agregado:

1. En Firebase Console → **Configuración del proyecto** → **Tus aplicaciones**
2. Selecciona la app Android: `com.innovadom.comprobante_rd`
3. Verifica que el SHA-1 esté listado:
   ```
   26:2E:15:DD:1D:B0:4B:A6:B2:4E:12:3E:32:9C:9F:98:11:DB:41:47
   ```

### 4. Verificar el google-services.json

El archivo debe tener el `oauth_client` de tipo 1 con:
- `package_name: "com.innovadom.comprobante_rd"`
- `certificate_hash: "262e15dd1db04ba6b24e123e329c9f9811db4147"`

### 5. Limpiar y reconstruir

```bash
flutter clean
flutter pub get
flutter build apk --release
```

### 6. Verificar logs

Ejecuta la app y revisa los logs de Android:

```bash
flutter run --release
```

O usa:
```bash
adb logcat | grep -i "google\|auth\|firebase"
```

## Errores comunes:

### Error: "10:"
- **Causa:** SHA-1 no coincide o no está agregado
- **Solución:** Verifica el SHA-1 en Firebase Console

### Error: "12500:"
- **Causa:** Google Sign-In no está habilitado en Firebase
- **Solución:** Habilita Google en Firebase Console → Authentication → Sign-in method

### Error: "12501:"
- **Causa:** El usuario canceló el inicio de sesión
- **Solución:** Esto es normal, no es un error

### Error: "DEVELOPER_ERROR"
- **Causa:** Configuración incorrecta del `serverClientId` o `google-services.json`
- **Solución:** Verifica que el `serverClientId` sea el correcto (tipo 3 - web client)

## Verificación final:

1. ✅ `google-services.json` tiene el `oauth_client` correcto
2. ✅ SHA-1 agregado en Firebase Console
3. ✅ Google Sign-In habilitado en Firebase
4. ✅ `serverClientId` configurado en el código
5. ✅ Package name correcto: `com.innovadom.comprobante_rd`


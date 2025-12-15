# Solución para Google Sign-In después de cambiar el package name

## ✅ Configuración verificada:

1. ✅ `build.gradle` tiene `applicationId = "com.innovadom.comprobante_rd"`
2. ✅ `google-services.json` tiene el `oauth_client` correcto para `com.innovadom.comprobante_rd`
3. ✅ SHA-1 agregado en Firebase Console
4. ✅ `serverClientId` configurado en el código

## 🔧 Pasos para solucionar:

### Paso 1: Desinstalar la app anterior completamente

Si tenías la app con el package name anterior instalada, desinstálala:

```bash
adb uninstall com.example.mi_comprobante_rd
```

O manualmente desde el dispositivo:
- Configuración → Aplicaciones → Busca la app antigua → Desinstalar

### Paso 2: Limpiar completamente el proyecto

```bash
# Desde la raíz del proyecto
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
```

### Paso 3: Verificar que no haya archivos residuales

Asegúrate de que no haya archivos del package name anterior:

```bash
# Verificar que MainActivity esté en la ubicación correcta
ls android/app/src/main/kotlin/com/innovadom/comprobante_rd/MainActivity.kt
```

### Paso 4: Reconstruir completamente

```bash
# Limpiar build de Android
rm -rf android/app/build
rm -rf android/build

# Reconstruir
flutter build apk --release
```

O para probar en modo debug:

```bash
flutter run --release
```

### Paso 5: Verificar en Firebase Console

1. Ve a https://console.firebase.google.com/
2. Selecciona tu proyecto: **mi-comprobante-rd**
3. Ve a **Authentication** → **Sign-in method**
4. Verifica que **Google** esté **habilitado** (debe estar en verde)
5. Verifica que tenga configurado:
   - **Email support**: Tu correo de soporte
   - **Project support email**: Tu correo

### Paso 6: Verificar el SHA-1 nuevamente

1. En Firebase Console → **Configuración del proyecto** → **Tus aplicaciones**
2. Selecciona la app: `com.innovadom.comprobante_rd`
3. Verifica que el SHA-1 esté listado:
   ```
   26:2E:15:DD:1D:B0:4B:A6:B2:4E:12:3E:32:9C:9F:98:11:DB:41:47
   ```

### Paso 7: Si aún no funciona, verificar logs

Ejecuta la app y revisa los logs:

```bash
flutter run --release
```

En otra terminal:
```bash
adb logcat | grep -i "google\|auth\|firebase\|signin"
```

Busca errores específicos como:
- `DEVELOPER_ERROR`
- `10:` (SHA-1 no coincide)
- `12500:` (Google Sign-In no habilitado)

## ⚠️ Problemas comunes:

### Error: "10:" o "DEVELOPER_ERROR"
- **Causa:** SHA-1 no coincide o Google Sign-In no está habilitado
- **Solución:** 
  1. Verifica el SHA-1 en Firebase Console
  2. Verifica que Google Sign-In esté habilitado en Firebase

### La app se cierra al intentar iniciar sesión
- **Causa:** Caché corrupta o app anterior aún instalada
- **Solución:** Desinstala completamente la app y reinstala

### No aparece el selector de cuenta de Google
- **Causa:** `serverClientId` incorrecto o `google-services.json` no se está procesando
- **Solución:** 
  1. Verifica que el `serverClientId` sea el del web client (tipo 3)
  2. Limpia y reconstruye completamente

## ✅ Checklist final:

- [ ] App anterior desinstalada completamente
- [ ] Proyecto limpiado (`flutter clean` y `./gradlew clean`)
- [ ] `google-services.json` actualizado con el nuevo package name
- [ ] SHA-1 agregado en Firebase Console para el nuevo package name
- [ ] Google Sign-In habilitado en Firebase Console
- [ ] `serverClientId` configurado en el código
- [ ] App reconstruida completamente
- [ ] Probado en un dispositivo físico o emulador


# Solución: Google Sign-In funciona en APK local pero no en Google Play Store

## 🔍 Problema

Cuando subes tu app a Google Play Store, Google firma tu app con su propio certificado (Google Play App Signing), que es **diferente** al certificado de tu keystore local. Por eso:

- ✅ Funciona en APK local (usa tu keystore)
- ❌ No funciona en Google Play Store (usa certificado de Google)

## ✅ Solución: Agregar SHA-1 de Google Play a Firebase

### Paso 1: Obtener el SHA-1 del certificado de Google Play

1. Ve a **Google Play Console**: https://play.google.com/console
2. Selecciona tu app: **ComprobanteRD**
3. Ve a **Configuración** → **Integridad de la app** (o **App Integrity**)
4. En la sección **"App signing by Google Play"**, encontrarás:
   - **SHA-1 certificate fingerprint**
   - Copia este SHA-1 (formato: `XX:XX:XX:XX:...`)

### Paso 2: Agregar el SHA-1 a Firebase

1. Ve a **Firebase Console**: https://console.firebase.google.com/
2. Selecciona tu proyecto: **mi-comprobante-rd**
3. Ve a **Configuración del proyecto** (ícono de engranaje) → **Tus aplicaciones**
4. Selecciona la app Android: `com.innovadom.comprobante_rd`
5. En **"Huellas digitales del certificado SHA"**, haz clic en **"Agregar huella digital"**
6. Pega el SHA-1 que copiaste de Google Play Console
7. Haz clic en **"Guardar"**

### Paso 3: Descargar el nuevo google-services.json (opcional)

1. En la misma página de configuración de la app Android
2. Haz clic en **"Descargar google-services.json"**
3. Reemplaza el archivo `android/app/google-services.json` con el nuevo

**Nota:** Normalmente no es necesario descargar un nuevo `google-services.json` solo por agregar un SHA-1, pero si quieres estar seguro, puedes hacerlo.

### Paso 4: Verificar que ambos SHA-1 estén agregados

En Firebase Console, deberías ver **ambos** SHA-1:

1. **SHA-1 de tu keystore local** (para desarrollo/testing):
   ```
   26:2E:15:DD:1D:B0:4B:A6:B2:4E:12:3E:32:9C:9F:98:11:DB:41:47
   ```

2. **SHA-1 de Google Play** (para producción):
   ```
   XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   ```
   (El que obtuviste de Google Play Console)

## ⚠️ Importante

- **No elimines** el SHA-1 de tu keystore local, lo necesitas para probar APKs locales
- **Agrega** el SHA-1 de Google Play para que funcione en la tienda
- Puedes tener **múltiples SHA-1** agregados en Firebase

## 🔄 Después de agregar el SHA-1

1. **No necesitas** reconstruir la app
2. **No necesitas** subir un nuevo AAB
3. Los cambios en Firebase son **inmediatos** (puede tardar unos minutos en propagarse)

## ✅ Verificación

Después de agregar el SHA-1 de Google Play:

1. Espera 5-10 minutos para que los cambios se propaguen
2. Prueba Google Sign-In en una versión de prueba interna
3. Debería funcionar correctamente

## 📝 Nota sobre Google Play App Signing

Si no ves la opción "App signing by Google Play" en Google Play Console, significa que:

- Tu app aún no está configurada con Google Play App Signing
- O estás usando el método de firma antiguo

En ese caso, Google Play App Signing se activa automáticamente cuando subes tu primer AAB. El SHA-1 estará disponible después de que Google procese tu primera versión.




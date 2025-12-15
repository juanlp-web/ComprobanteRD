# ✅ Checklist para Prueba Cerrada (Closed Testing) - ComprobanteRD

## 🔴 CRÍTICO - Debe estar completo antes de producción

### 1. Política de Privacidad
- [ ] **URL de política de privacidad publicada** (GitHub Pages o tu sitio web)
- [ ] **URL agregada en Google Play Console** → Política y programas → Política de privacidad
- [ ] **URL actualizada en el código** (`lib/features/settings/presentation/settings_page.dart`)
  - Actualmente está: `'https://tudominio.com/privacy-policy'`
  - Debe ser tu URL real (ej: `'https://tuusuario.github.io/comprobante-rd-privacy/'`)
- [ ] **Botón de política funciona** en la app (Configuración → Política de Privacidad)

### 2. Google Sign-In
- [ ] **SHA-1 de Google Play agregado en Firebase Console**
  - Firebase Console → Configuración → Tus aplicaciones → `com.innovadom.comprobante_rd`
  - Debe tener ambos SHA-1:
    - SHA-1 de keystore local (para desarrollo)
    - SHA-1 de Google Play (para producción)
- [ ] **google-services.json actualizado** con el nuevo SHA-1
- [ ] **Google Sign-In probado en la versión de prueba cerrada**
  - Debe funcionar correctamente
  - Si no funciona, verifica que el SHA-1 de Google Play esté agregado

### 3. AdMob
- [ ] **IDs reales configurados** (✅ Ya están configurados)
  - Banner: `ca-app-pub-4489858186339381/2700089641`
  - Intersticial: `ca-app-pub-4489858186339381/9052200419`
- [ ] **Anuncios funcionando** en la versión de prueba
- [ ] **No aparecen "Test Ad"** (deben ser anuncios reales)

### 4. Permisos
- [ ] **Permisos bloqueados correctamente** (✅ Ya están bloqueados)
  - `READ_MEDIA_IMAGES` removido
  - `READ_MEDIA_VIDEO` removido
- [ ] **Solo permisos necesarios** aparecen en Google Play Console
  - `CAMERA` (requerido para escanear QR)
  - `INTERNET` (requerido para Firebase y AdMob)

## 🟡 IMPORTANTE - Verificar antes de producción

### 5. Funcionalidad Core
- [ ] **Escanear QR funciona** correctamente
- [ ] **Guardar comprobantes** funciona
- [ ] **Lista de comprobantes** se muestra correctamente
- [ ] **Filtros y búsqueda** funcionan
- [ ] **Exportar comprobantes** (CSV, Excel, PDF) funciona
- [ ] **Sincronización con Firebase** funciona
  - Comprobantes se sincronizan entre dispositivos
  - Datos se guardan correctamente en Firestore

### 6. Autenticación
- [ ] **Registro con email** funciona
- [ ] **Verificación de email** funciona
- [ ] **Login con email** funciona
- [ ] **Login con Google** funciona (en prueba cerrada)
- [ ] **Cerrar sesión** funciona
- [ ] **Datos por usuario** funcionan correctamente
  - Cada usuario solo ve sus propios comprobantes

### 7. UI/UX
- [ ] **Todas las pantallas** se ven correctamente
- [ ] **Navegación** funciona sin problemas
- [ ] **Mensajes de error** son claros y útiles
- [ ] **Mensajes de éxito** aparecen cuando corresponde
- [ ] **Carga/espera** tiene indicadores apropiados

### 8. Offline/Online
- [ ] **Funciona sin internet** (guardar comprobantes localmente)
- [ ] **Sincroniza cuando hay internet** (sube comprobantes a Firestore)
- [ ] **Validación DGII** se salta cuando no hay internet
- [ ] **Validación DGII** funciona cuando hay internet

## 🟢 RECOMENDADO - Mejoras opcionales

### 9. Contenido de la App
- [ ] **Descripción en Google Play Console** está completa
- [ ] **Capturas de pantalla** actualizadas
- [ ] **Icono de la app** se ve bien
- [ ] **Categoría** seleccionada correctamente

### 10. Testing
- [ ] **Probar en diferentes dispositivos** (si es posible)
- [ ] **Probar con diferentes versiones de Android**
- [ ] **Probar con y sin internet**
- [ ] **Probar con diferentes cuentas de Google**

### 11. Monitoreo
- [ ] **Firebase Analytics** configurado (opcional)
- [ ] **Crashlytics** configurado (opcional)
- [ ] **Monitorear errores** en Firebase Console

## 📋 Verificación Final

Antes de pasar a producción, asegúrate de:

1. ✅ **Política de privacidad** publicada y URL agregada en Google Play
2. ✅ **Google Sign-In** funciona en prueba cerrada
3. ✅ **AdMob** muestra anuncios reales (no "Test Ad")
4. ✅ **Todas las funcionalidades core** funcionan correctamente
5. ✅ **No hay crashes** o errores críticos
6. ✅ **Permisos** son solo los necesarios

## 🚀 Después de la Prueba Cerrada

Una vez que todo funcione en prueba cerrada:

1. **Recopilar feedback** de los testers
2. **Corregir bugs** encontrados
3. **Actualizar versionCode** si hay cambios
4. **Subir nueva versión** si es necesario
5. **Pasar a producción** cuando esté listo

## ⚠️ Problemas Comunes en Prueba Cerrada

### Google Sign-In no funciona
- **Solución:** Agregar SHA-1 de Google Play en Firebase Console

### Anuncios muestran "Test Ad"
- **Solución:** Verificar que los IDs sean reales (ya están configurados)

### Política de privacidad no se puede abrir
- **Solución:** Actualizar la URL en el código con la URL real

### La app se cierra inesperadamente
- **Solución:** Revisar logs en Firebase Crashlytics o Android Logcat




# Instrucciones para Actualizar Reglas de Firestore

## 📋 Archivo de Reglas

Se ha creado el archivo `firestore.rules` en la raíz del proyecto con las reglas de seguridad apropiadas.

## 🚀 Cómo Desplegar las Reglas

### Opción 1: Desde Firebase Console (Recomendado)

1. **Abre Firebase Console**
   - Ve a [https://console.firebase.google.com](https://console.firebase.google.com)
   - Selecciona tu proyecto

2. **Navega a Firestore Database**
   - En el menú lateral, haz clic en **Firestore Database**
   - Ve a la pestaña **Reglas** (Rules)

3. **Copia y Pega las Reglas**
   - Abre el archivo `firestore.rules` de este proyecto
   - Copia todo el contenido
   - Pega el contenido en el editor de reglas de Firebase Console

4. **Publica las Reglas**
   - Haz clic en el botón **Publicar** (Publish)
   - Espera a que se confirme la publicación

### Opción 2: Usando Firebase CLI

Si tienes Firebase CLI instalado:

```bash
# Asegúrate de estar en la raíz del proyecto
cd /Users/juancarlos/Documents/ComprobanteRD

# Inicia sesión en Firebase (si no lo has hecho)
firebase login

# Despliega las reglas
firebase deploy --only firestore:rules
```

## 🔒 ¿Qué Hacen Estas Reglas?

Las reglas de seguridad implementadas:

1. **Autenticación Requerida**: Solo usuarios autenticados pueden acceder a los datos
2. **Aislamiento de Usuarios**: Cada usuario solo puede leer/escribir sus propios datos
   - `users/{userId}` - Solo el usuario con ese `userId` puede acceder
   - `users/{userId}/invoices/{invoiceId}` - Solo el propietario puede gestionar sus facturas
3. **Permisos de Eliminación**: Los usuarios pueden eliminar sus propios datos (necesario para eliminar la cuenta)

## ⚠️ Importante

- **Después de desplegar las reglas**, el error `permission-denied` al eliminar la cuenta debería desaparecer
- Las reglas se aplican inmediatamente después de publicarlas
- Si tienes problemas, verifica que el `userId` en las reglas coincida con `request.auth.uid`

## 🧪 Verificar las Reglas

Puedes probar las reglas usando el **Simulador de Reglas** en Firebase Console:
1. Ve a Firestore Database → Reglas
2. Haz clic en **Simulador de Reglas** (Rules Simulator)
3. Prueba diferentes escenarios de lectura/escritura/eliminación

## 📝 Notas

- Estas reglas son seguras y siguen el principio de menor privilegio
- Cada usuario solo puede acceder a sus propios datos
- No hay acceso público a los datos
- Los usuarios no pueden acceder a datos de otros usuarios


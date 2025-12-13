# Cómo actualizar google-services.json después de agregar SHA-1 de Google Play

## Pasos:

1. **Agregar SHA-1 en Firebase Console** (si aún no lo has hecho)
   - Firebase Console → Configuración → Tus aplicaciones
   - Selecciona `com.innovadom.comprobante_rd`
   - Agrega el SHA-1 de Google Play

2. **Descargar nuevo google-services.json**
   - En la misma página, haz clic en **"Descargar google-services.json"**
   - Guarda el archivo

3. **Reemplazar el archivo**
   - Reemplaza `android/app/google-services.json` con el nuevo archivo

4. **Verificar que tenga ambos oauth_client**
   - Debería tener al menos 2 `oauth_client` de tipo 1:
     - Uno con el SHA-1 de tu keystore local
     - Uno con el SHA-1 de Google Play

## Verificación:

El nuevo `google-services.json` debería verse así:

```json
{
  "client": [
    {
      "package_name": "com.innovadom.comprobante_rd",
      "oauth_client": [
        {
          "client_type": 1,
          "android_info": {
            "package_name": "com.innovadom.comprobante_rd",
            "certificate_hash": "262e15dd1db04ba6b24e123e329c9f9811db4147"  // SHA-1 local
          }
        },
        {
          "client_type": 1,
          "android_info": {
            "package_name": "com.innovadom.comprobante_rd",
            "certificate_hash": "XXXXXXXXXXXXX"  // SHA-1 de Google Play
          }
        },
        {
          "client_type": 3  // Web client
        }
      ]
    }
  ]
}
```




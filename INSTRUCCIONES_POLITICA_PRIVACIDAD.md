# Instrucciones para Publicar la Política de Privacidad

## ✅ Lo que ya está hecho:

1. ✅ Se creó el archivo `PRIVACY_POLICY.md` con la política de privacidad completa
2. ✅ Se agregó un botón en la página de Configuración para acceder a la política
3. ✅ El `versionCode` se incrementó a 2

## 📋 Pasos que debes completar:

### 1. Publicar la Política de Privacidad en una URL pública

Tienes varias opciones:

#### Opción A: GitHub Pages (Gratis y fácil)
1. Crea un repositorio público en GitHub (ej: `comprobante-rd-privacy`)
2. Crea un archivo `index.html` con el contenido de `PRIVACY_POLICY.md` convertido a HTML
3. Habilita GitHub Pages en la configuración del repositorio
4. Tu URL será: `https://tuusuario.github.io/comprobante-rd-privacy/`

#### Opción B: Tu propio sitio web
1. Sube el contenido de `PRIVACY_POLICY.md` a tu sitio web
2. Asegúrate de que sea accesible públicamente (sin autenticación)

#### Opción C: Servicios gratuitos
- **GitHub Pages**: https://pages.github.com/
- **Netlify**: https://www.netlify.com/
- **Vercel**: https://vercel.com/

### 2. Actualizar la URL en el código

Una vez que tengas la URL pública:

1. Abre `lib/features/settings/presentation/settings_page.dart`
2. Busca la línea:
   ```dart
   const privacyPolicyUrl = 'https://tudominio.com/privacy-policy';
   ```
3. Reemplázala con tu URL real:
   ```dart
   const privacyPolicyUrl = 'https://tuusuario.github.io/comprobante-rd-privacy/';
   ```

### 3. Agregar la URL en Google Play Console

1. Ve a Google Play Console: https://play.google.com/console
2. Selecciona tu aplicación "ComprobanteRD"
3. Ve a **"Política y programas"** en el menú lateral
4. En **"Política de privacidad de la app"**, haz clic en **"Iniciar"** o **"Editar"**
5. Ingresa la URL pública de tu política de privacidad
6. Guarda los cambios

### 4. Actualizar información de contacto (opcional pero recomendado)

En el archivo `PRIVACY_POLICY.md`, actualiza la sección de contacto:

```markdown
## 10. Contacto

Si tienes preguntas sobre esta Política de Privacidad, puedes contactarnos a través de:
- Email: tu-email@ejemplo.com
- Sitio web: https://tusitio.com
```

### 5. Convertir Markdown a HTML (si usas GitHub Pages)

Si usas GitHub Pages, puedes crear un archivo `index.html` simple:

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Política de Privacidad - ComprobanteRD</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
        }
        h1 { color: #2D6A4F; }
        h2 { color: #0057B8; margin-top: 30px; }
        code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; }
    </style>
</head>
<body>
    <!-- Pega aquí el contenido de PRIVACY_POLICY.md convertido a HTML -->
    <!-- O usa un convertidor de Markdown a HTML -->
</body>
</html>
```

## ✅ Verificación

Antes de subir el AAB a Google Play:

1. ✅ Verifica que la URL de la política de privacidad sea accesible públicamente
2. ✅ Verifica que el botón en la app abra correctamente la URL
3. ✅ Verifica que la política mencione específicamente el uso de la cámara
4. ✅ Verifica que la política mencione todos los servicios que usas (Firebase, AdMob)

## 📝 Notas importantes

- La política de privacidad **debe estar en español** (ya que tu app está en español)
- La URL **debe ser accesible sin autenticación**
- La política **debe mencionar específicamente el permiso de cámara**
- Google Play puede tardar algunas horas en verificar la política

## 🚀 Después de completar estos pasos

1. Reconstruye el AAB con la URL actualizada
2. Sube el nuevo AAB a Google Play Console
3. Completa la información de la política de privacidad en Google Play Console
4. Envía la aplicación para revisión


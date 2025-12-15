# Instrucciones para Publicar en GitHub Pages

## 📋 Pasos para subir la política de privacidad a GitHub Pages

### Paso 1: Crear un repositorio en GitHub

1. Ve a https://github.com y inicia sesión
2. Haz clic en el botón **"+"** (arriba a la derecha) → **"New repository"**
3. Configura el repositorio:
   - **Repository name:** `comprobante-rd-privacy` (o el nombre que prefieras)
   - **Description:** "Política de Privacidad de ComprobanteRD"
   - **Visibilidad:** ✅ **Public** (debe ser público para GitHub Pages)
   - ❌ NO marques "Add a README file" (ya tenemos el archivo HTML)
4. Haz clic en **"Create repository"**

### Paso 2: Subir el archivo HTML

Tienes dos opciones:

#### Opción A: Usando la interfaz web de GitHub (Más fácil)

1. En la página del repositorio recién creado, haz clic en **"uploading an existing file"**
2. Arrastra el archivo `privacy-policy.html` a la página
3. O haz clic en **"choose your files"** y selecciona `privacy-policy.html`
4. En el campo **"Commit changes"**, escribe: "Agregar política de privacidad"
5. Haz clic en **"Commit changes"**

#### Opción B: Usando Git desde la terminal

```bash
# Navega a la carpeta del proyecto
cd C:/Users/prueb/OneDrive/Documents/Flutter/mi_comprobante_rd

# Inicializa git (si no está inicializado)
git init

# Agrega el archivo
git add privacy-policy.html

# Haz commit
git commit -m "Agregar política de privacidad"

# Agrega el repositorio remoto (reemplaza TU_USUARIO con tu usuario de GitHub)
git remote add origin https://github.com/TU_USUARIO/comprobante-rd-privacy.git

# Sube el archivo
git branch -M main
git push -u origin main
```

### Paso 3: Renombrar el archivo a index.html

**IMPORTANTE:** GitHub Pages busca un archivo llamado `index.html` por defecto.

1. En GitHub, ve a tu repositorio
2. Haz clic en el archivo `privacy-policy.html`
3. Haz clic en el ícono de lápiz (editar)
4. Cambia el nombre del archivo en la parte superior a `index.html`
5. Haz clic en **"Commit changes"**

**O** puedes renombrarlo localmente y subirlo de nuevo:

```bash
# Renombrar el archivo
mv privacy-policy.html index.html

# Subir el nuevo archivo
git add index.html
git commit -m "Renombrar a index.html"
git push
```

### Paso 4: Habilitar GitHub Pages

1. En tu repositorio de GitHub, ve a **"Settings"** (Configuración)
2. En el menú lateral izquierdo, busca y haz clic en **"Pages"**
3. En **"Source"**, selecciona:
   - Branch: `main` (o `master` si usas esa rama)
   - Folder: `/ (root)`
4. Haz clic en **"Save"**
5. Espera unos minutos (puede tardar hasta 5 minutos)

### Paso 5: Obtener tu URL

Después de habilitar GitHub Pages, tu URL será:

```
https://TU_USUARIO.github.io/comprobante-rd-privacy/
```

**Ejemplo:** Si tu usuario es `juanperez`, la URL será:
```
https://juanperez.github.io/comprobante-rd-privacy/
```

### Paso 6: Verificar que funciona

1. Abre tu navegador
2. Ve a la URL que obtuviste en el Paso 5
3. Deberías ver la política de privacidad

### Paso 7: Actualizar la URL en tu app

1. Abre `lib/features/settings/presentation/settings_page.dart`
2. Busca esta línea:
   ```dart
   const privacyPolicyUrl = 'https://tudominio.com/privacy-policy';
   ```
3. Reemplázala con tu URL de GitHub Pages:
   ```dart
   const privacyPolicyUrl = 'https://TU_USUARIO.github.io/comprobante-rd-privacy/';
   ```
4. Guarda el archivo

### Paso 8: Reconstruir y probar

```bash
# Reconstruir la app
flutter build appbundle --release
```

Luego prueba en un dispositivo que el botón de "Política de Privacidad" abra correctamente la URL.

## ✅ Checklist Final

- [ ] Repositorio creado en GitHub (público)
- [ ] Archivo `index.html` subido al repositorio
- [ ] GitHub Pages habilitado
- [ ] URL verificada en el navegador
- [ ] URL actualizada en el código de la app
- [ ] App reconstruida y probada

## 🔧 Solución de Problemas

### La página no carga
- Espera 5-10 minutos después de habilitar GitHub Pages
- Verifica que el repositorio sea público
- Verifica que el archivo se llame `index.html` (no `privacy-policy.html`)

### Error 404
- Asegúrate de que el archivo esté en la raíz del repositorio (no en una carpeta)
- Verifica que el nombre del archivo sea exactamente `index.html`

### La URL no funciona en la app
- Verifica que la URL esté correctamente escrita en el código
- Asegúrate de que la URL comience con `https://`
- Prueba abrir la URL directamente en el navegador del dispositivo

## 📝 Notas Adicionales

- Puedes actualizar el contenido editando `index.html` directamente en GitHub
- Los cambios pueden tardar unos minutos en aparecer
- Puedes personalizar el diseño editando el CSS dentro del archivo HTML


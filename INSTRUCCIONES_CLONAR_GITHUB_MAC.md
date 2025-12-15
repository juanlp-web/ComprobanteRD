# Cómo Clonar el Proyecto desde GitHub a Mac

## Requisitos Previos

1. **Git instalado** (viene preinstalado en macOS, pero puedes verificar con):
   ```bash
   git --version
   ```

2. **Cuenta de GitHub** con acceso al repositorio

3. **Flutter instalado** en tu Mac (para trabajar con el proyecto después)

## Método 1: Clonar con HTTPS (Recomendado para principiantes)

### Paso 1: Obtener la URL del Repositorio

1. Ve a tu repositorio en GitHub
2. Haz clic en el botón verde **"Code"**
3. Selecciona la pestaña **"HTTPS"**
4. Copia la URL (ejemplo: `https://github.com/tu-usuario/mi_comprobante_rd.git`)

### Paso 2: Abrir Terminal en Mac

1. Presiona `⌘ + Espacio` para abrir Spotlight
2. Escribe "Terminal" y presiona Enter
3. O ve a **Aplicaciones** → **Utilidades** → **Terminal**

### Paso 3: Navegar al Directorio Deseado

```bash
cd ~/Documents
# O cualquier otra ubicación donde quieras clonar el proyecto
```

### Paso 4: Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/mi_comprobante_rd.git
```

**Nota**: Reemplaza `tu-usuario` y `mi_comprobante_rd` con tu usuario y nombre del repositorio real.

### Paso 5: Entrar al Directorio del Proyecto

```bash
cd mi_comprobante_rd
```

## Método 2: Clonar con SSH (Recomendado para uso frecuente)

### Paso 1: Configurar SSH en GitHub

Si aún no tienes una clave SSH configurada:

1. **Generar una clave SSH**:
   ```bash
   ssh-keygen -t ed25519 -C "tu-email@ejemplo.com"
   ```
   - Presiona Enter para aceptar la ubicación predeterminada
   - Opcionalmente, agrega una frase de contraseña

2. **Copiar la clave pública**:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   - Copia toda la salida

3. **Agregar la clave a GitHub**:
   - Ve a GitHub → **Settings** → **SSH and GPG keys**
   - Haz clic en **"New SSH key"**
   - Pega tu clave pública y guarda

### Paso 2: Clonar con SSH

```bash
git clone git@github.com:tu-usuario/mi_comprobante_rd.git
```

## Método 3: Usando GitHub Desktop (Interfaz Gráfica)

1. **Descargar GitHub Desktop**:
   - Ve a [desktop.github.com](https://desktop.github.com/)
   - Descarga e instala GitHub Desktop

2. **Iniciar sesión**:
   - Abre GitHub Desktop
   - Inicia sesión con tu cuenta de GitHub

3. **Clonar el repositorio**:
   - Haz clic en **"File"** → **"Clone Repository"**
   - Selecciona el repositorio de la lista
   - O pega la URL del repositorio
   - Elige la ubicación donde quieres clonarlo
   - Haz clic en **"Clone"**

## Después de Clonar

### 1. Verificar que se Clonó Correctamente

```bash
cd mi_comprobante_rd
ls -la
```

Deberías ver todos los archivos del proyecto.

### 2. Obtener Dependencias de Flutter

```bash
flutter pub get
```

### 3. Configurar Firebase para iOS

**IMPORTANTE**: Necesitas descargar el archivo `GoogleService-Info.plist`:

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **Configuración** → **Tus aplicaciones**
4. Descarga `GoogleService-Info.plist` para iOS
5. Colócalo en: `ios/Runner/GoogleService-Info.plist`

### 4. Instalar Dependencias de CocoaPods

```bash
cd ios
pod install
cd ..
```

### 5. Verificar la Configuración

```bash
flutter doctor
```

Esto te mostrará si todo está configurado correctamente.

## Comandos Git Útiles

### Ver el Estado del Repositorio

```bash
git status
```

### Ver las Ramas Disponibles

```bash
git branch -a
```

### Cambiar de Rama

```bash
git checkout nombre-de-la-rama
```

### Actualizar el Proyecto (Obtener Cambios Nuevos)

```bash
git pull
```

### Ver el Historial de Commits

```bash
git log --oneline
```

## Solución de Problemas

### Error: "Permission denied (publickey)"

**Causa**: No tienes configurada la clave SSH o no está agregada a GitHub.

**Solución**: Sigue los pasos del Método 2 para configurar SSH.

### Error: "Repository not found"

**Causa**: 
- El repositorio es privado y no tienes acceso
- La URL es incorrecta
- No estás autenticado

**Solución**:
- Verifica que tengas acceso al repositorio
- Verifica que la URL sea correcta
- Si es privado, asegúrate de estar autenticado:
  ```bash
  gh auth login  # Si usas GitHub CLI
  ```

### Error: "fatal: destination path already exists"

**Causa**: Ya existe un directorio con ese nombre.

**Solución**:
```bash
# Opción 1: Eliminar el directorio existente (¡cuidado!)
rm -rf mi_comprobante_rd
git clone https://github.com/tu-usuario/mi_comprobante_rd.git

# Opción 2: Clonar con otro nombre
git clone https://github.com/tu-usuario/mi_comprobante_rd.git mi_comprobante_rd_nuevo
```

### Error: "Git no está instalado"

**Solución**:
```bash
# Instalar con Homebrew
brew install git

# O descargar desde: https://git-scm.com/download/mac
```

## Estructura del Proyecto Después de Clonar

Después de clonar, deberías ver esta estructura:

```
mi_comprobante_rd/
├── android/
├── ios/
├── lib/
├── assets/
├── pubspec.yaml
├── README.md
└── ...
```

## Próximos Pasos

Una vez clonado el proyecto:

1. **Configurar el entorno iOS** (ver `INSTRUCCIONES_COMPILAR_IOS.md`)
2. **Abrir en Xcode**: `open ios/Runner.xcworkspace`
3. **Compilar y ejecutar**: `flutter run` o desde Xcode

## Autenticación con GitHub

### Usando Personal Access Token (HTTPS)

Si GitHub te pide autenticación al hacer `git pull` o `git push`:

1. Ve a GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Genera un nuevo token con permisos de `repo`
3. Cuando Git te pida credenciales, usa tu token como contraseña

### Usando GitHub CLI

```bash
# Instalar GitHub CLI
brew install gh

# Autenticarse
gh auth login
```

## Notas Importantes

- **Nunca subas archivos sensibles** como `GoogleService-Info.plist` o `google-services.json` si contienen información confidencial
- El archivo `.gitignore` ya está configurado para excluir archivos de build y configuración local
- Si trabajas en equipo, siempre haz `git pull` antes de empezar a trabajar
- Usa ramas para nuevas funcionalidades: `git checkout -b nombre-feature`

## Recursos

- [Documentación de Git](https://git-scm.com/doc)
- [Guía de GitHub](https://docs.github.com/)
- [Flutter Setup para macOS](https://docs.flutter.dev/get-started/install/macos)


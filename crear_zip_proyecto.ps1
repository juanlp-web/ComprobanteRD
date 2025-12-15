# Script para crear ZIP del proyecto Flutter excluyendo archivos innecesarios
# Ejecutar desde la raíz del proyecto

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Preparando proyecto para transferencia" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Obtener la ruta del script (directorio del proyecto)
$projectPath = $PSScriptRoot
if (-not $projectPath) {
    $projectPath = Get-Location
}

$projectName = Split-Path -Leaf $projectPath
$zipFileName = "$projectName.zip"
$parentPath = Split-Path -Parent $projectPath
$zipPath = Join-Path $parentPath $zipFileName

Write-Host "Proyecto: $projectName" -ForegroundColor Yellow
Write-Host "Ubicación: $projectPath" -ForegroundColor Yellow
Write-Host ""

# Lista de carpetas y archivos a excluir
$excludePatterns = @(
    "build",
    ".dart_tool",
    "ios\Pods",
    "ios\Podfile.lock",
    "android\.gradle",
    "android\build",
    "android\app\build",
    "android\local.properties",
    "android\key.properties",
    "android\*.jks",
    "android\upload-keystore.jks",
    "*.iml",
    ".idea",
    ".vscode",
    ".DS_Store",
    "*.log",
    "*.swp",
    ".flutter-plugins",
    ".flutter-plugins-dependencies",
    "ios\Flutter\.last_build_id",
    "ios\Flutter\Flutter.framework",
    "ios\Flutter\Flutter.podspec",
    "ios\Flutter\Generated.xcconfig",
    "ios\Flutter\ephemeral",
    "macos\Flutter\ephemeral",
    "windows\flutter\ephemeral",
    "linux\flutter\ephemeral"
)

Write-Host "Excluyendo archivos innecesarios..." -ForegroundColor Green
Write-Host ""

# Crear una carpeta temporal para el proyecto limpio
$tempFolder = Join-Path $env:TEMP "flutter_zip_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$tempProjectFolder = Join-Path $tempFolder $projectName

New-Item -ItemType Directory -Path $tempProjectFolder -Force | Out-Null

Write-Host "Copiando archivos necesarios..." -ForegroundColor Green

# Función para verificar si un archivo/carpeta debe ser excluido
function Should-Exclude {
    param($itemPath, $relativePath)
    
    foreach ($pattern in $excludePatterns) {
        $normalizedPattern = $pattern -replace '\\', [System.IO.Path]::DirectorySeparatorChar
        if ($relativePath -like "*$normalizedPattern*" -or $relativePath -eq $normalizedPattern) {
            return $true
        }
    }
    return $false
}

# Copiar archivos recursivamente
$itemsCopied = 0
$itemsExcluded = 0

Get-ChildItem -Path $projectPath -Recurse -Force | ForEach-Object {
    $relativePath = $_.FullName.Substring($projectPath.Length + 1)
    
    if (Should-Exclude -itemPath $_.FullName -relativePath $relativePath) {
        $itemsExcluded++
        return
    }
    
    $destinationPath = Join-Path $tempProjectFolder $relativePath
    $destinationDir = Split-Path -Parent $destinationPath
    
    if (-not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }
    
    if (-not $_.PSIsContainer) {
        Copy-Item -Path $_.FullName -Destination $destinationPath -Force
        $itemsCopied++
    }
}

Write-Host ""
Write-Host "Archivos copiados: $itemsCopied" -ForegroundColor Green
Write-Host "Archivos excluidos: $itemsExcluded" -ForegroundColor Yellow
Write-Host ""

# Crear el archivo ZIP
Write-Host "Creando archivo ZIP..." -ForegroundColor Green

# Eliminar ZIP anterior si existe
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
    Write-Host "ZIP anterior eliminado." -ForegroundColor Yellow
}

# Comprimir usando .NET
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempProjectFolder, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)

# Limpiar carpeta temporal
Remove-Item -Path $tempFolder -Recurse -Force

# Obtener tamaño del ZIP
$zipSize = (Get-Item $zipPath).Length
$zipSizeMB = [math]::Round($zipSize / 1MB, 2)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "¡ZIP creado exitosamente!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Archivo: $zipPath" -ForegroundColor White
Write-Host "Tamaño: $zipSizeMB MB" -ForegroundColor White
Write-Host ""
Write-Host "El archivo está listo para transferir." -ForegroundColor Green
Write-Host ""

# Preguntar si desea abrir la carpeta
$openFolder = Read-Host "¿Deseas abrir la carpeta del ZIP? (S/N)"
if ($openFolder -eq "S" -or $openFolder -eq "s") {
    $parentFolder = Split-Path -Parent $zipPath
    Invoke-Item $parentFolder
}


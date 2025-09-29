

#requires -version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Script: 01b_build_images.ps1
# Objetivo: Cambiar el H1 visible en src/app/app.component.html y construir
#           las imágenes BLUE (v1) y GREEN (v2) de snake-app. (Sin restaurar el HTML,
#           igual que en el script .sh mostrado.)
#
# Uso:
#   pwsh -File snake-app/scripts/01b_build_images.ps1
#
# Variables (opcionales) por entorno:
#   $env:BLUE_TAG  (default: snake-app:v1-blue)
#   $env:GREEN_TAG (default: snake-app:v2-green)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppDir    = Split-Path -Parent $ScriptDir        # -> snake-app
$SnakeDir  = $AppDir
$BlueTag   = if ($env:BLUE_TAG)  { $env:BLUE_TAG }  else { "snake-app:v1-blue" }
$GreenTag  = if ($env:GREEN_TAG) { $env:GREEN_TAG } else { "snake-app:v2-green" }

$AppHtml   = Join-Path $SnakeDir "src/app/app.component.html"
$BlueLine  = '<h1>Balada das serpentes 🐍 <span style="font-size:.8em;">v1 (blue)</span></h1>'
$GreenLine = '<h1>Balada das serpentes 🐍 <span style="font-size:.8em;">v2 (green)</span></h1>'

Write-Host "==> [01] Validando archivo HTML objetivo"
if (-not (Test-Path -LiteralPath $AppHtml)) {
  throw "ERROR: No se encontró $AppHtml"
}

# Función: reemplaza la **primera** ocurrencia de <h1>...</h1> por la línea objetivo
function Set-H1 {
  param(
    [Parameter(Mandatory=$true)][string]$TargetLine
  )
  $content = Get-Content -LiteralPath $AppHtml -Raw
  # Reemplazo de UNA sola ocurrencia (count = 1)
  $pattern = '<h1>.*?</h1>'
  $newContent = [regex]::Replace($content, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $TargetLine }, 1, [System.Text.RegularExpressions.RegexOptions]::Singleline)
  Set-Content -LiteralPath $AppHtml -Value $newContent -NoNewline
}

Write-Host "==> [02] Seteando H1 a v1 (blue) y construyendo $BlueTag"
Set-H1 -TargetLine $BlueLine
(Get-Content -LiteralPath $AppHtml | Select-String -Pattern '<h1>').Line | Select-Object -First 1 | ForEach-Object { Write-Host $_ }
docker build -t $BlueTag $SnakeDir

Write-Host "==> [03] Seteando H1 a v2 (green) y construyendo $GreenTag"
Set-H1 -TargetLine $GreenLine
(Get-Content -LiteralPath $AppHtml | Select-String -Pattern '<h1>').Line | Select-Object -First 1 | ForEach-Object { Write-Host $_ }
docker build -t $GreenTag $SnakeDir

# Write-Host "==> [04] Restaurando app.component.html original (OPCIONAL – desactivado para emular el .sh)"
# Copy-Item -LiteralPath "$AppHtml.bak" -Destination $AppHtml -Force

Write-Host "==> [05] Listo. Imágenes construidas:"
docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}' | Select-String -Pattern 'snake-app:(v1-blue|v2-green)' | ForEach-Object { $_.Line }
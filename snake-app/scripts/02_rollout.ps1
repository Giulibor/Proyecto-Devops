

#requires -version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

<#
.SYNOPSIS
  Cambia el selector del Service snake-app a blue o green y abre el Service con minikube.
.DESCRIPTION
  Script minimalista para rollout Blue/Green en Windows (PowerShell).
  Mantiene el comportamiento interactivo: deja abierto `minikube service snake-app` y se sale con Ctrl+C.
.PARAMETER Color
  Color de destino del Service. Valores permitidos: blue, green. Default: green.
.EXAMPLE
  pwsh -File .\snake-app\scripts\02_rollout.ps1 -Color green
#>

param(
  [Parameter(Position=0)]
  [ValidateSet("blue","green")]
  [string]$Color = "green"
)

Write-Host "==> Cambiando Service a color=$Color"
# Construimos el JSON inline sin problemas de comillas
$patch = @{ spec = @{ selector = @{ app = "snake-app"; color = $Color } } } | ConvertTo-Json -Compress
kubectl patch svc snake-app -p $patch | Out-Host

Write-Host "==> Servicio snake-app"
kubectl get svc snake-app -o wide | Out-Host

Write-Host "==> Abriendo Service con minikube (dejá esta terminal abierta para visualizar la app)"
minikube service snake-app
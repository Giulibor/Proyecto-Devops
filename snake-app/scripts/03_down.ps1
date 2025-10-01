

#requires -version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

<#
.SYNOPSIS
  Limpia recursos de snake-app y detiene minikube en Windows (PowerShell).
.DESCRIPTION
  Equivalente PowerShell al script 03_down.sh.
  Elimina deploys, services y pods etiquetados con app=snake-app.
  Revierte las variables de entorno de Docker y detiene minikube.
.EXAMPLE
  pwsh -File .\snake-app\scripts\03_down.ps1
#>

Write-Host "==> Eliminando recursos de snake-app"
kubectl delete deploy -l app=snake-app --ignore-not-found | Out-Host
kubectl delete svc    -l app=snake-app --ignore-not-found | Out-Host
kubectl delete pod    -l app=snake-app --ignore-not-found | Out-Host

Write-Host "==> Revirtiendo variables de entorno de Docker (minikube docker-env -u)"
# En PowerShell, aplicamos con Invoke-Expression
Invoke-Expression -Command "$(minikube docker-env -u --shell powershell)"

Write-Host "==> Deteniendo minikube"
minikube stop | Out-Host

# Si querés borrar completamente el cluster, descomentá:
# Write-Host "==> Borrando cluster minikube"
# minikube delete --all --purge | Out-Host

Write-Host "Listo. Tu shell vuelve a apuntar a tu Docker local y minikube quedó detenido."
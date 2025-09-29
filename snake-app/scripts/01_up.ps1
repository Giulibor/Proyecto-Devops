

#requires -version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configuración
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppDir    = Split-Path -Parent $ScriptDir
$SnakeDir  = $AppDir
$BlueTag   = "snake-app:v1-blue"
$GreenTag  = "snake-app:v2-green"
$K8sDir    = Join-Path $SnakeDir "k8s"

Write-Host "==> 1) Iniciando minikube (driver=docker)"
minikube start --driver=docker

Write-Host "==> 2) Apuntando Docker local al daemon de minikube"
# En PowerShell, minikube docker-env devuelve variables que deben aplicarse con Invoke-Expression
Invoke-Expression -Command "$(minikube docker-env --shell powershell)"

Write-Host "==> 3) Limpiando recursos previos SOLO de snake-app (no borro todo el cluster)"
kubectl delete deploy -l app=snake-app --ignore-not-found
kubectl delete svc    -l app=snake-app --ignore-not-found
kubectl delete pod    -l app=snake-app --ignore-not-found

Write-Host "==> 4) Construyendo imágenes (delegado a 01b_build_images)"
# Para Windows nativo, deberías crear también un script PowerShell equivalente (01b_build_images.ps1).
# Mientras tanto, si Git Bash está instalado, se puede llamar al .sh:
bash "$ScriptDir/01b_build_images.sh"

Write-Host "==> 5) Aplicando manifests"
kubectl apply -f (Join-Path $K8sDir "deployment-blue.yaml")
kubectl apply -f (Join-Path $K8sDir "deployment-green.yaml")
kubectl apply -f (Join-Path $K8sDir "service.yaml")

Write-Host "==> 6) Esperando rollouts"
kubectl rollout status deploy/snake-app-blue
kubectl rollout status deploy/snake-app-green

Write-Host "==> 7) Pods actuales"
kubectl get pods -l app=snake-app -o wide

Write-Host "==> 8) URL estable del Service (NodePort)"
Write-Host "==> Abriendo Service con minikube (dejá esta terminal abierta para visualizar la app)"
minikube service snake-app
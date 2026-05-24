param(
    [string]$Region = "eu-north-1",
    [string]$ClusterName = "postboard-cluster",
    [string]$Tag = "latest",
    [string]$AccountId = "",
    [switch]$NoRedeploy
)

$ErrorActionPreference = "Stop"

$serviceNames = @(
    "postboard-auth-service",
    "postboard-core-service",
    "postboard-media-service",
    "postboard-notification-service",
    "postboard-frontend"
)

foreach ($serviceName in $serviceNames) {
    Write-Host ""
    Write-Host "Deploying $serviceName..."

    & "$PSScriptRoot\deploy-service.ps1" `
        -ServiceName $serviceName `
        -Region $Region `
        -ClusterName $ClusterName `
        -Tag $Tag `
        -AccountId $AccountId `
        -NoRedeploy:$NoRedeploy
}

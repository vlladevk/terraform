param(
    [string]$Region = "us-east-1",
    [string]$ClusterName = "postboard-cluster",
    [string]$Tag = "latest",
    [string]$AccountId = "",
    [switch]$NoRedeploy
)

$ErrorActionPreference = "Stop"

$serviceNames = @(
    "postboard-auth-service",
    "postboard-media-service",
    "postboard-notification-service",
    "postboard-frontend"
)

& "$PSScriptRoot\package-core-lambda.ps1"

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

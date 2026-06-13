param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        "postboard-auth-service",
        "postboard-core-service",
        "postboard-media-service",
        "postboard-notification-service",
        "postboard-frontend"
    )]
    [string]$ServiceName,

    [string]$Region = "us-east-1",
    [string]$ClusterName = "postboard-cluster",
    [string]$Tag = "latest",
    [string]$AccountId = "",
    [switch]$NoRedeploy
)

$ErrorActionPreference = "Stop"

$appsRoot = $env:POSTBOARD_APPS_ROOT
if ([string]::IsNullOrWhiteSpace($appsRoot)) {
    $appsRoot = Join-Path $PSScriptRoot "..\.."
}

$services = @{
    "postboard-auth-service" = @{
        ProjectPath   = (Join-Path $appsRoot "Project2\postboard-auth-service")
        EcrRepository = "postboard-auth-service"
        EcsService    = "postboard-auth-service"
        BuildType     = "maven"
    }
    "postboard-core-service" = @{
        ProjectPath   = (Join-Path $appsRoot "Project2\postboard-core-service")
        EcrRepository = "postboard-core-service"
        EcsService    = "postboard-core-service"
        BuildType     = "maven"
    }
    "postboard-media-service" = @{
        ProjectPath   = (Join-Path $appsRoot "Project2\postboard-media-service")
        EcrRepository = "postboard-media-service"
        EcsService    = "postboard-media-service"
        BuildType     = "maven"
    }
    "postboard-notification-service" = @{
        ProjectPath   = (Join-Path $appsRoot "Project2\postboard-notification-service")
        EcrRepository = "postboard-notification-service"
        EcsService    = "postboard-notification-service"
        BuildType     = "maven"
    }
    "postboard-frontend" = @{
        ProjectPath   = (Join-Path $appsRoot "post_board_front")
        EcrRepository = "postboard-frontend"
        EcsService    = "postboard-frontend"
        BuildType     = "node"
    }
}

$service = $services[$ServiceName]

if (-not (Test-Path $service.ProjectPath)) {
    throw "Project path does not exist: $($service.ProjectPath)"
}

if ([string]::IsNullOrWhiteSpace($AccountId)) {
    $AccountId = aws sts get-caller-identity --query Account --output text
}

$registry = "$AccountId.dkr.ecr.$Region.amazonaws.com"
$remoteImage = "$registry/$($service.EcrRepository):$Tag"

& "$PSScriptRoot\ecr-login.ps1" -Region $Region -AccountId $AccountId

Push-Location $service.ProjectPath
try {
    if ($service.BuildType -eq "maven") {
        if (Test-Path ".\mvnw.cmd") {
            & .\mvnw.cmd clean package -DskipTests
            if ($LASTEXITCODE -ne 0) {
                throw "Maven build failed for $ServiceName."
            }
        }
        else {
            mvn clean package -DskipTests
            if ($LASTEXITCODE -ne 0) {
                throw "Maven build failed for $ServiceName."
            }
        }
    }
    elseif ($service.BuildType -eq "node") {
        if (Test-Path ".\package-lock.json") {
            npm ci
            if ($LASTEXITCODE -ne 0) {
                throw "NPM install failed for $ServiceName."
            }
        }
        else {
            npm install
            if ($LASTEXITCODE -ne 0) {
                throw "NPM install failed for $ServiceName."
            }
        }
    }

    docker build -t "$ServiceName`:$Tag" .
    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed for $ServiceName."
    }

    docker tag "$ServiceName`:$Tag" $remoteImage
    if ($LASTEXITCODE -ne 0) {
        throw "Docker tag failed for $ServiceName."
    }

    docker push $remoteImage
    if ($LASTEXITCODE -ne 0) {
        throw "Docker push failed for $ServiceName. Check ECR login and repository permissions."
    }
}
finally {
    Pop-Location
}

if (-not $NoRedeploy) {
    aws ecs update-service `
        --cluster $ClusterName `
        --service $service.EcsService `
        --force-new-deployment `
        --region $Region | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "ECS redeploy failed for $($service.EcsService)."
    }

    Write-Host "Pushed $remoteImage and requested ECS redeploy for $($service.EcsService)."
}
else {
    Write-Host "Pushed $remoteImage. ECS redeploy skipped by -NoRedeploy."
}

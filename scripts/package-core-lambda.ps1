param(
    [string]$ProjectPath = (Join-Path $PSScriptRoot "..\..\Project2\postboard-core-service")
)

$ErrorActionPreference = "Stop"

if (-not $PSBoundParameters.ContainsKey("ProjectPath") -and $env:POSTBOARD_APPS_ROOT) {
    $ProjectPath = Join-Path $env:POSTBOARD_APPS_ROOT "Project2\postboard-core-service"
}

if (-not (Test-Path $ProjectPath)) {
    throw "Project path does not exist: $ProjectPath"
}

Push-Location $ProjectPath
try {
    if (Test-Path ".\mvnw.cmd") {
        & .\mvnw.cmd clean package -DskipTests
        if ($LASTEXITCODE -ne 0) {
            throw "Maven Lambda package build failed."
        }
    }
    else {
        mvn clean package -DskipTests
        if ($LASTEXITCODE -ne 0) {
            throw "Maven Lambda package build failed."
        }
    }
}
finally {
    Pop-Location
}

Write-Host "Packaged core Lambda artifact."

param(
    [string]$Region = "us-east-1",
    [string]$AccountId = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($AccountId)) {
    $AccountId = aws sts get-caller-identity --query Account --output text
}

$registry = "$AccountId.dkr.ecr.$Region.amazonaws.com"

# Docker Desktop on Windows can reject the PowerShell pipeline with HTTP 400.
cmd.exe /c "aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $registry"
if ($LASTEXITCODE -ne 0) {
    throw "Docker login to ECR registry failed: $registry"
}

Write-Host "Logged in to ECR registry: $registry"

param(
    [string]$Region = "eu-north-1",
    [string]$AccountId = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($AccountId)) {
    $AccountId = aws sts get-caller-identity --query Account --output text
}

$registry = "$AccountId.dkr.ecr.$Region.amazonaws.com"

aws ecr get-login-password --region $Region |
    docker login --username AWS --password-stdin $registry

Write-Host "Logged in to ECR registry: $registry"

# Deployment Scripts

`bootstrap` Terraform creates ECR repositories first. These scripts build
application images, push them to ECR, package the core Lambda artifact, and
optionally force ECS to redeploy services created by the main `postBoard`
Terraform stack.

## First deployment

```powershell
cd .\bootstrap
terraform init
terraform apply

cd ..
.\scripts\deploy-all.ps1 -NoRedeploy

cd .\postBoard
terraform init
terraform apply
```

## Deploy one service

```powershell
.\scripts\deploy-service.ps1 -ServiceName postboard-auth-service
```

`postboard-core-service` is packaged as AWS Lambda functions for Project 3, not
as a Fargate image. Package it with:

```powershell
.\scripts\package-core-lambda.ps1
```

## Deploy everything

```powershell
.\scripts\deploy-all.ps1
```

## Common options

```powershell
.\scripts\deploy-all.ps1 `
  -Region us-east-1 `
  -ClusterName postboard-cluster `
  -Tag latest
```

Use `-NoRedeploy` when ECR repositories already exist but ECS services have not
been created yet.

```powershell
.\scripts\deploy-all.ps1 -NoRedeploy
```

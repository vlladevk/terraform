# Deployment Scripts

Terraform creates the infrastructure. These scripts build application images,
push them to ECR, and optionally force ECS to redeploy services.

## Deploy one service

```powershell
.\scripts\deploy-service.ps1 -ServiceName postboard-core-service
```

## Deploy everything

```powershell
.\scripts\deploy-all.ps1
```

## Common options

```powershell
.\scripts\deploy-all.ps1 `
  -Region eu-north-1 `
  -ClusterName postboard-cluster `
  -Tag latest
```

Use `-NoRedeploy` when ECR repositories already exist but ECS services have not
been created yet.

```powershell
.\scripts\deploy-all.ps1 -NoRedeploy
```

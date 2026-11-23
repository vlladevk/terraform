# Deployment scripts

Run the commands below from the root of this repository. The scripts expect the
application sources under the parent of this repository by default. Set
`$env:POSTBOARD_APPS_ROOT` to use another directory with the same layout:

```text
<application root>/
  Project2/
    postboard-auth-service/
    postboard-core-service/
    postboard-media-service/
    postboard-notification-service/
  post_board_front/
```

Install AWS CLI, Docker, Java 21, and Node.js before building the application.
The Java projects use the Maven wrapper if present and otherwise require Maven.

## First deployment

```powershell
terraform -chdir=bootstrap init
terraform -chdir=bootstrap apply

.\scripts\deploy-all.ps1 -NoRedeploy

# Set TF_VAR_db_password from your secret store before planning.
$env:TF_VAR_lambda_artifact_path = 'C:\path\to\built-core-lambda.jar'
terraform -chdir=postBoard init
terraform -chdir=postBoard plan
```

Apply the main stack after reviewing its plan. Keep the AWS CLI and Terraform
credentials and regions aligned so both use the same ECR repositories.

## Updating services

```powershell
.\scripts\deploy-service.ps1 -ServiceName postboard-auth-service
.\scripts\deploy-all.ps1
```

The ECS deployment scripts push images and request new ECS deployments. Use the
image tag referenced by Terraform. To update the core Lambda functions, package
the core application, set its artifact path, and apply the main Terraform stack.

```powershell
.\scripts\package-core-lambda.ps1 -ProjectPath 'C:\path\to\postboard-core-service'
```

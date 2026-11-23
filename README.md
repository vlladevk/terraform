# PostBoard AWS infrastructure

Terraform configuration for the PostBoard application on AWS.

| Directory | Purpose |
| --- | --- |
| `bootstrap/` | Creates Amazon ECR repositories for the application images. |
| `postBoard/` | Defines the VPC, load balancer, ECS Fargate services, API Gateway, Lambda functions, Cognito, PostgreSQL on RDS, DynamoDB, S3, SNS, SQS, and CloudWatch monitoring. |
| `scripts/` | Builds and publishes images to ECR and packages the core Lambda application. See the [deployment steps](scripts/README.md). |

## Deployment prerequisites

- Terraform and AWS credentials for the target account. Set `lab_role_name` to an existing IAM role that the ECS and Lambda services can use. The default is `LabRole`.
- PostBoard application sources or prebuilt artifacts. Set `TF_VAR_lambda_artifact_path` to the built Java 21 Lambda JAR and publish the application images to the ECR repositories.
- Supply the RDS password through `TF_VAR_db_password` using your local secret store or shell session. Keep Terraform state, plans, and local variable files outside version control.

Initialize and apply `bootstrap/` first, publish the application images, then initialize and plan `postBoard/`. Review the plan before applying it.

## Project timeline

| Date | Activity |
| --- | --- |
| 2026-05-24 | Initial Terraform snapshot and ECR deployment scripts. |
| 2026-06-13 | Updated the infrastructure baseline, split the stack into Terraform modules, and tuned individual Lambda resources. |
| 2026-06-21 | The deployment state records creation of the Cognito user pool and updates to the core Lambda functions in AWS. |

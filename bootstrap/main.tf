terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project = var.project_name
  }

  repositories = {
    auth         = "postboard-auth-service"
    media        = "postboard-media-service"
    notification = "postboard-notification-service"
    frontend     = "postboard-frontend"
  }
}

resource "aws_ecr_repository" "service" {
  for_each = local.repositories

  name         = each.value
  force_delete = true

  tags = merge(local.common_tags, {
    Name = each.value
  })
}

output "ecr_repository_urls" {
  value = {
    for key, repo in aws_ecr_repository.service : key => repo.repository_url
  }
}

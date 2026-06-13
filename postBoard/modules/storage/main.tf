resource "aws_db_subnet_group" "core" {
  name       = "${var.project_name}-core-db-subnets"
  subnet_ids = var.db_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-core-db-subnets"
  })
}

resource "aws_db_instance" "core" {
  allocated_storage       = var.db_allocated_storage
  backup_retention_period = 1
  db_name                 = var.db_name
  db_subnet_group_name    = aws_db_subnet_group.core.name
  deletion_protection     = false
  engine                  = "postgres"
  identifier              = "${var.project_name}-core-db"
  instance_class          = var.db_instance_class
  password                = var.db_password
  port                    = var.db_port
  publicly_accessible     = false
  skip_final_snapshot     = true
  username                = var.db_username
  vpc_security_group_ids  = [var.db_security_group_id]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-core-db"
  })
}

resource "aws_dynamodb_table" "auth_users" {
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "username"
  name         = "auth_users"

  attribute {
    name = "username"
    type = "S"
  }

  tags = var.common_tags
}

resource "aws_dynamodb_table" "media_metadata" {
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  name         = "media_metadata"

  attribute {
    name = "id"
    type = "S"
  }

  tags = var.common_tags
}

resource "aws_dynamodb_table" "notifications" {
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "recipientUsername"
  name         = "notifications"
  range_key    = "id"

  attribute {
    name = "recipientUsername"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }

  tags = var.common_tags
}

resource "aws_dynamodb_table" "notification_subscribers" {
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "username"
  name         = "notification_subscribers"

  attribute {
    name = "username"
    type = "S"
  }

  tags = var.common_tags
}

resource "aws_s3_bucket" "media" {
  bucket_prefix = "${var.project_name}-media-"
  force_destroy = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-media"
  })
}

resource "aws_s3_bucket_public_access_block" "media" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.media.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}
